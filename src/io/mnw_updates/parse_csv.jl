# parse file into io, parse io into 

#=
workflow: call parse_file on the static data? will have to check that this will still work with the data checks removed
call parse_csv (maybe rename to parse_timeseries?)
call create_timeseries(static data, transient data)
something in that should apply the data checks to the static file (reference existing code)
=#

function parse_csv(filename::String)
    raw = open(filename, "r") do io
        readlines(io)
    end
    return parse_csv(raw) 
end

function parse_csv(io::IO)
    lines = readlines(io)
    return parse_csv(lines)
end

function parse_csv(lines::Vector{String})
    header = split(lines[1], ",")
    data = []
    for line in lines[2:end]
        values = split(line, ",")
        row_dict = Dict{String,Any}()
        for (i, col_name) in enumerate(header)
            if i <= length(values) 
                row_dict[col_name] = values[i]
            end
        end
        push!(data, row_dict)
    end
    return data
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

    if time_step < 3600.0 && !isinteger(3600.0 / time_step)
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

