"parses transient data format CSV into list of dictionarys"
function parse_transient(file::AbstractString)::Array{Dict{String,Any},1}
    return open(file, "r") do io
        parse_transient(io)
    end
end


"parses transient data format CSV into "
function parse_transient(io::IO)::Array{Dict{String,Any},1}
    raw = readlines(io)

    data = []
    for line in raw[2:end]
        timestamp, component_type, component_id, parameter, value = split(line, ",")
        push!(
            data,
            Dict(
                "timestamp" => timestamp,
                "component_type" => component_type,
                "component_id" => component_id,
                "parameter" => parameter,
                "value" => value,
            ),
        )
    end

    return data
end


""
function parse_files(static_file::AbstractString, transient_file::AbstractString; kwargs...)::Dict{String,Any}
    static_filetype = split(lowercase(static_file), '.')[end]

    open(static_file, "r") do static_io
        open(transient_file, "r") do transient_io
            return parse_files(static_io, transient_io; static_filetype=static_filetype, kwargs...)
        end
    end
end


"""
Parses two files - a static file and a transient csv file and prepares the data object. The static file is the .m file and the transient file is a .csv file that contains the time-series data information. The function takes in the following keyword arguments:
(i) `total_time` (defaults to 86400 seconds or 24 hours) - this is the total time for which transient optimization needs to be solved (ii) `time_step` (defaults to 3600 seconds or 1 hours) - this argument specifies the time discretization step (iii) `spatial_discretization` (defaults to 10000 m or 10 km) - this argument specifies the spatial discretization step (iv) `additional_time` (defaults to 21600 seconds or 6 hours) - this argument decides the time horizon that needs to be padded to the total time to in case the user wishes to perform a moving horizon transient optimization.
"""
function parse_files(
    static_io::IO,
    transient_io::IO;
    static_filetype::AbstractString="m",
    total_time = 86400.0,
    time_step = 3600.0,
    spatial_discretization = 10000.0,
    additional_time = 21600.0,
)
    periodic = true

    if static_filetype == "m"
        static_data = GasModels.parse_matgas(static_io)
    elseif static_filetype == "json"
        static_data = GasModels.parse_json(static_io)
    else
        Memento.error(_LOGGER, "only .m and .json network data files are supported")
    end

    check_non_negativity(static_data)
    correct_p_mins!(static_data)

    per_unit_data_field_check!(static_data)
    add_compressor_fields!(static_data)

    make_si_units!(static_data)
    add_base_values!(static_data)
    check_connectivity(static_data)
    check_status(static_data)
    check_edge_loops(static_data)

    check_global_parameters(static_data)

    _prep_transient_data!(static_data, spatial_discretization = spatial_discretization)
    transient_data = parse_transient(transient_io)
    make_si_units!(transient_data, static_data)
    time_series_block = _create_time_series_block(
        transient_data,
        total_time = total_time,
        time_step = time_step,
        additional_time = additional_time,
        periodic = periodic,
    )

    static_data["time_series"] = deepcopy(time_series_block)
    mn_data = _IM.make_multinetwork(static_data, _gm_global_keys)
    make_per_unit!(mn_data)
    return mn_data
end

"function to get the maximum pipe id"
function _get_max_pipe_id(pipes::Dict{String,Any})::Int
    max_pipe_id = 0
    for (key, pipe) in pipes
        max_pipe_id = (pipe["id"] > max_pipe_id) ? pipe["id"] : max_pipe_id
    end
    return max_pipe_id
end

"function to calculate bearing given 2 lat lon values"
function _calc_bearing(fr, to)
    y = cos(to[1] * pi / 180) * sin(abs(to[2] - fr[2]) * pi / 180)
    x = cos(fr[1] * pi / 180) * sin(to[1] * pi / 180) -
        sin(fr[1] * pi / 180) * cos(to[1] * pi / 180) * cos((to[2] - fr[2]) * pi / 180)
    beta = atan(y, x)
    return (beta * 180.0 / pi + 360) % 360
end

"function to calculate lat lon given origin, bearing, and distance"
function _get_lat_lon(fr, bearing, distance)
    R = 6378.1
    brng = bearing * pi / 180.0
    d = distance / 1000.0
    lat1 = fr[1] * pi / 180
    lon1 = fr[2] * pi / 180
    lat2 = asin(sin(lat1) * cos(d / R) + cos(lat1) * sin(d / R) * cos(brng))
    lon2 = lon1 + atan(sin(brng) * sin(d / R) * cos(lat1), cos(d / R) - sin(lat1) * sin(lat2))
    return (lat2 * 180 / pi, lon2 * 180 / pi)
end

"function to update the lat lon for the new junctions"
function update_lat_lon!(data::Dict{String,Any})
    for (i, p) in data["original_pipe"]
        sub_pipes = collect(p["fr_pipe"]:p["to_pipe"])
        start_junction = data["pipe"]["$(sub_pipes[1])"]["fr_junction"]
        start_lon = data["junction"]["$(start_junction)"]["lon"]
        start_lat = data["junction"]["$(start_junction)"]["lat"]

        end_junction = data["pipe"]["$(sub_pipes[end])"]["to_junction"]
        end_lon = data["junction"]["$(end_junction)"]["lon"]
        end_lat = data["junction"]["$(end_junction)"]["lat"]

        lon_incr = (end_lon - start_lon) / (length(sub_pipes) * 2)
        lat_incr = (end_lat - start_lat) / (length(sub_pipes) * 2)

        for (s, sub_pipe_id) in enumerate(sub_pipes)
            sub_pipe = data["pipe"]["$sub_pipe_id"]

            data["junction"]["$(sub_pipe["fr_junction"])"]["lon"] = 2 * (s - 1) * lon_incr + start_lon
            data["junction"]["$(sub_pipe["fr_junction"])"]["lat"] = 2 * (s - 1) * lat_incr + start_lat

            data["junction"]["$(sub_pipe["to_junction"])"]["lon"] = (2 * (s - 1) + 1) * lon_incr + start_lon
            data["junction"]["$(sub_pipe["to_junction"])"]["lat"] = (2 * (s - 1) + 1) * lat_incr + start_lat
        end
    end
end

" discretizes the pipes and takes care of renumbering junctions and pipes"
function _prep_transient_data!(
    data::Dict{String,Any};
    spatial_discretization::Float64 = 10000.0,
)
    max_pipe_id = _get_max_pipe_id(data["pipe"])
    num_sub_pipes = Dict()
    short_pipes = []
    long_pipes = []
    for (key, pipe) in data["pipe"]
        (pipe["length"] < spatial_discretization) && (push!(short_pipes, key); continue)
        push!(long_pipes, key)
        count = Int(floor(pipe["length"] / spatial_discretization) + 1)
        num_sub_pipes[key] = count
    end

    # adding fields "is_discretized" and "num_sub_pipes" for each pipe in the original data
    for i in short_pipes
        data["pipe"][i]["is_discretized"] = false
        data["pipe"][i]["num_sub_pipes"] = 0
    end

    for i in long_pipes
        data["pipe"][i]["is_discretized"] = true
        data["pipe"][i]["num_sub_pipes"] = num_sub_pipes[i]
    end

    # adding a field "is_physical" for each junction in the original data
    for (key, value) in data["junction"]
        data["junction"][key]["is_physical"] = true
    end

    # adding fields "is_discretized" and "num_sub_pipes" for each compressor in the original data
    for (key, compressor) in data["compressor"]
        data["compressor"][key]["is_discretized"] = false
        data["compressor"][key]["num_sub_pipes"] = 0
    end

    # adding fields "is_discretized" and "num_sub_pipes" for each resistor in the original data
    for (key, resistor) in get(data, "resistor", [])
        data["resistor"][key]["is_discretized"] = false
        data["resistor"][key]["num_sub_pipes"] = 0
    end

    # adding fields "is_discretized" and "num_sub_pipes" for each regulator in the original data
    for (key, regulator) in get(data, "regulator", [])
        data["regulator"][key]["is_discretized"] = false
        data["regulator"][key]["num_sub_pipes"] = 0
    end

    # adding fields "is_discretized" and "num_sub_pipes" for each short_pipe in the original data
    for (key, short_pipe) in get(data, "short_pipe", [])
        data["short_pipe"][key]["is_discretized"] = false
        data["short_pipe"][key]["num_sub_pipes"] = 0
    end

    # saving the original_pipe and original_junctions separately in the data dictionary
    data["original_pipe"] = Dict{String,Any}()
    data["original_junction"] = Dict{String,Any}()
    for (key, pipe) in data["pipe"]
        data["original_pipe"][key] = pipe
    end

    for (key, junction) in data["junction"]
        data["original_junction"][key] = junction
    end

    delete!(data, "pipe")

    data["pipe"] = Dict{String,Any}()

    # if original pipe is a not discretized add it to the pipe list, else add a list of discretized pipe segments with junctions
    for (key, pipe) in data["original_pipe"]
        if !pipe["is_discretized"]
            pipe_fields = [
                "id",
                "fr_junction",
                "to_junction",
                "diameter",
                "length",
                "friction_factor",
                "p_min",
                "p_max",
                "status",
                "is_bidirectional",
                "is_si_units",
                "is_english_units",
                "is_per_unit",
            ]
            data["pipe"][key] = Dict{String,Any}()
            for field in pipe_fields
                if haskey(pipe, field)
                    data["pipe"][key][field] = pipe[field]
                end
            end
            data["original_pipe"][key]["fr_pipe"] = pipe["id"]
            data["original_pipe"][key]["to_pipe"] = pipe["id"]
            continue
        end

        fr_junction = data["junction"][string(pipe["fr_junction"])]
        to_junction = data["junction"][string(pipe["to_junction"])]
        sub_pipe_count = pipe["num_sub_pipes"]
        intermediate_junction_count = pipe["num_sub_pipes"] - 1
        data["original_pipe"][key]["fr_pipe"] = max_pipe_id + pipe["id"] * 1000 + 1
        data["original_pipe"][key]["to_pipe"] = max_pipe_id + pipe["id"] * 1000 + sub_pipe_count

        for i = 1:intermediate_junction_count
            id = max_pipe_id + pipe["id"] * 1000 + i
            data["junction"][string(id)] = Dict{String,Any}(
                "id" => id,
                "p_min" => min(fr_junction["p_min"], to_junction["p_min"]),
                "p_max" => max(fr_junction["p_max"], to_junction["p_max"]),
                "p_nominal" =>
                    (fr_junction["p_nominal"] + to_junction["p_nominal"]) / 2.0,
                "junction_type" => 0,
                "status" => 1,
                "is_physical" => false,
                "is_si_units" => data["is_si_units"],
                "is_english_units" => data["is_english_units"],
                "is_per_unit" => data["is_english_units"],
            )
        end

        for i = 1:sub_pipe_count
            id = max_pipe_id + pipe["id"] * 1000 + i
            new_length = pipe["length"] / sub_pipe_count
            fr_id = (i == 1) ? fr_junction["id"] : (id - 1)
            to_id = (i == sub_pipe_count) ? to_junction["id"] : id
            data["pipe"][string(id)] = Dict{String,Any}(
                "id" => id,
                "fr_junction" => fr_id,
                "to_junction" => to_id,
                "diameter" => pipe["diameter"],
                "length" => new_length,
                "friction_factor" => pipe["friction_factor"],
                "status" => pipe["status"],
                "index" => id,
                "p_min" => pipe["p_min"],
                "p_max" => pipe["p_max"],
                "is_bidirectional" => pipe["is_bidirectional"],
                "is_si_units" => data["is_si_units"],
                "is_english_units" => data["is_english_units"],
                "is_per_unit" => data["is_english_units"],
            )
        end
    end

    update_lat_lon!(data)
end

"creates a time series block from the csv data which is later used create a multinetwork data"
function _create_time_series_block(
    data::Array{Dict{String,Any},1};
    total_time = 86400.0,
    time_step = 3600.0,
    additional_time = 21600.0,
    periodic = true,
)::Dict{String,Any}
    # create time information
    time_series_block = Dict{String,Any}()
    end_time = total_time + additional_time
    if (time_step > 3600.0 && time_step % 3600.0 != 0.0)
        Memento.error(
            _LOGGER,
            "the 3600 seconds has to be exactly divisible by the time step,
provide a time step that exactly divides 3600.0",
        )
    end
    if time_step < 3600.0 && ~isinteger(3600.0 / time_step)
        Memento.error(_LOGGER, "time step should divide 3600.0 exactly when < 3600.0")
    end
    if total_time > 86400.0
        Memento.warn(
            _LOGGER,
            "the solver takes a substantial performance hit when trying to solve
transient optimization problems for more than a day's worth of data; if it takes too long to
converge, please restrict the final time horizon to a day or less",
        )
    end
    if (additional_time == 0.0)
        Memento.warn(
            _LOGGER,
            "the transient optimization problem will only work for time-periodic
time-series data. Please ensure the time-series data is time-periodic with a period of $total_time;
if the data is not time-periodic GasModels will perform a time-periodic spline interpolation if
at least 4 time series data points are available (and result in an error otherwise)",
        )
    end
    num_time_points = Int(ceil(end_time / time_step)) + 1
    num_physical_time_points = Int(ceil(total_time / time_step)) + 1
    time_points = collect(LinRange(0.0, end_time, num_time_points))

    time_series_block["num_steps"] = num_time_points
    time_series_block["num_physical_time_points"] = num_physical_time_points
    time_series_block["num_time_points"] = length(time_points)
    time_series_block["time_point"] = time_points
    time_series_block["time_step"] = time_step

    interpolators = Dict{String,Any}()
    fields = Set()
    for line in data
        type = line["component_type"]
        id = line["component_id"]
        param = line["parameter"]
        push!(fields, (type, id, param))
        val = parse(Float64, line["value"])
        timestamp = DateTime(split(line["timestamp"], "+")[1])

        if !haskey(interpolators, type)
            interpolators[type] = Dict{String,Any}()
        end

        if !haskey(interpolators[type], id)
            interpolators[type][id] = Dict{String,Any}()
        end

        if !haskey(interpolators[type][id], param)
            interpolators[type][id][param] = Dict{String,Any}(
                "values" => [],
                "timestamps" => [],
                "times" => [],
                "reduced_data_points" => [],
            )
        end

        push!(interpolators[type][id][param]["values"], val)
        push!(interpolators[type][id][param]["timestamps"], timestamp)
        time_val = (
                interpolators[type][id][param]["timestamps"][end] -
                interpolators[type][id][param]["timestamps"][1]
            ) / Millisecond(1) * 1 / 1000.0
        if (time_val <= total_time)
            push!(interpolators[type][id][param]["times"], time_val)
            push!(interpolators[type][id][param]["reduced_data_points"], val)
        end
    end

    for (type, id, param) in fields
        if (additional_time > 0.0)
            start_val = interpolators[type][id][param]["reduced_data_points"][1]
            #= remove cubic spline interpolation
            end_val = interpolators[type][id][param]["reduced_data_points"][end]
            middle_time = total_time + additional_time / 2
            middle_val = (end_val + start_val) / 2
            push!(interpolators[type][id][param]["times"], middle_time)
            push!(interpolators[type][id][param]["reduced_data_points"], middle_val)
            =#
            push!(interpolators[type][id][param]["times"], end_time)
            push!(interpolators[type][id][param]["reduced_data_points"], start_val)
        end
        x = interpolators[type][id][param]["times"]
        y = interpolators[type][id][param]["reduced_data_points"]
        interpolators[type][id][param]["itp"] = Spline1D(x, y, k = 1, periodic = periodic)

        if !haskey(time_series_block, type)
            time_series_block[type] = Dict{String,Any}()
        end

        if !haskey(time_series_block[type], id)
            time_series_block[type][id] = Dict{String,Any}()
        end

        if !haskey(time_series_block[type][id], param)
            time_series_block[type][id][param] = []
        end

        itp = interpolators[type][id][param]["itp"]
        for t in time_series_block["time_point"]
            itp_val = round(itp(t), digits = 2)
            (abs(itp_val) <= 1e-4) && (itp_val = 0.0)
            push!(time_series_block[type][id][param], itp_val)
        end
    end
    _fix_time_series_block!(time_series_block)
    return time_series_block
end

function _fix_time_series_block!(block)
    for (i, val) in get(block, "transfer", [])
        if haskey(val, "withdrawal_max")
            val["withdrawal_max"] = max.(val["withdrawal_max"], zeros(length(val["withdrawal_max"])))
        end
        if haskey(val, "withdrawal_min")
            val["withdrawal_min"] = min.(val["withdrawal_min"], zeros(length(val["withdrawal_min"])))
        end
    end
    for (i, val) in get(block, "delivery", [])
        if haskey(val, "withdrawal_max")
            val["withdrawal_max"] = max.(val["withdrawal_max"], zeros(length(val["withdrawal_max"])))
        end
        if haskey(val, "withdrawal_min")
            val["withdrawal_min"] = min.(val["withdrawal_min"], zeros(length(val["withdrawal_min"])))
        end
    end
    for (i, val) in get(block, "receipt", [])
        if haskey(val, "injection_max")
            val["injection_max"] = max.(val["injection_max"], zeros(length(val["injection_max"])))
        end
        if haskey(val, "injection_min")
            val["injection_min"] = min.(val["injection_min"], zeros(length(val["injection_min"])))
        end
    end
end