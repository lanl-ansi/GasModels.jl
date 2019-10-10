# tools for working with GasModels internal data format

"Computes the maximum volume of the Gas Model"
function _calc_max_volume_flow(data::Dict{String,Any})
    max_flow = 0
    for (idx, producer) in data["producer"]
        if producer["qgmax"] > 0
          max_flow = max_flow + producer["qgmax"]
        end
    end
    return max_flow
end


"Computes the max mass flow in the Gas Model"
function _calc_max_mass_flow(data::Dict{String,Any})
    return _calc_max_volume_flow(data) * data["standard_density"]
end


"Computes the maximum volume of the Gas Model"
function _calc_max_volume_flow(ref::Dict{Symbol,Any})
    max_flow = 0
    for (idx, producer) in ref[:producer]
        if producer["qgmax"] > 0
          max_flow = max_flow + producer["qgmax"]
        end
    end
    return max_flow
end


"Computes the max mass flow in the Gas Model"
function _calc_max_mass_flow(ref::Dict{Symbol,Any})
    return _calc_max_volume_flow(ref) * ref[:standard_density]
end


"Calculate the bounds on minimum and maximum pressure difference squared"
function _calc_pd_bounds_sqr(ref::Dict{Symbol,Any}, i_idx::Int, j_idx::Int)
    i = ref[:junction][i_idx]
    j = ref[:junction][j_idx]

    pd_max = i["pmax"]^2 - j["pmin"]^2
    pd_min = i["pmin"]^2 - j["pmax"]^2

    return pd_min, pd_max
end


"Calculates pipeline resistance from this paper Thorley and CH Tiley. Unsteady and transient flow of compressible
fluids in pipelines–a review of theoretical and some experimental studies.
International Journal of Heat and Fluid Flow, 8(1):3–15, 1987
This is used in many of Zlotnik's papers
This calculation expresses resistance in terms of mass flow equations"
function _calc_pipe_resistance_thorley(ref::Dict{Symbol,Any}, pipe::Dict{String,Any})
    R          = ref[:R] #8.314 # universal gas constant
    z          = ref[:compressibility_factor]
    T          = ref[:temperature]
    m          = ref[:gas_molar_mass]
    lambda     = pipe["friction_factor"]
    D          = pipe["diameter"]
    L          = pipe["length"]

    a_sqr = z * (R/m) * T
    A     = (pi*D^2) / 4 # cross sectional area
    resistance = ( (D * A^2) / (lambda * L * a_sqr)) * (ref[:baseP]^2 / ref[:baseQ]^2) # second half is the non-dimensionalization
    return resistance
end


"A very simple model of computing resistance for resistors that is based on the Thorley model.  The are other more realistic models that could
be used.  See Physical and technical fundamentals of gas networks by Fugenschu et al. for an example"
function _calc_resistor_resistance_simple(ref::Dict{Symbol,Any}, pipe::Dict{String,Any})
    R          = ref[:R] #8.314 # universal gas constant
    z          = ref[:compressibility_factor]
    T          = ref[:temperature]
    m          = ref[:gas_molar_mass]
    lambda     = pipe["drag"]
    D          = pipe["diameter"]
    L          = pipe["length"]

    a_sqr = z * (R/m) * T
    A     = (pi*D^2) / 4 # cross sectional area

    resistance = ( (D * A^2) / (lambda * L * a_sqr)) * (ref[:baseP]^2 / ref[:baseQ]^2) # second half is the non-dimensionalization
    return resistance
end


"Calculate the pipe resistance using the method described in De Wolf and Smeers. The Gas Transmission Problem Solved by an Extension of the Simplex Algorithm. Management Science. 46 (11) 1454-1465, 2000
 This function assumes that diameters are in mm, lengths are in km, volumetric flow is in 10^6 m^3/day, and pressure is in bars"
function _calc_pipe_resistance_smeers(ref::Dict{Symbol,Any},pipe::Dict{String,Any})
    c          = 96.074830e-15    # Gas relative constant
    L          = pipe["length"] / 1000.0  # length of the pipe [km]
    D          = pipe["diameter"] * 1000.0 # interior diameter of the pipe [mm]
    T          = 281.15           # gas temperature [K]
    epsilon    = 0.05       # absolute rugosity of pipe [mm]
    delta      = 0.6106       # density of the gas relative to air [-]
    z          = 0.8                      # gas compressibility factor [-]
    B          = 3.6*D/epsilon
    lambda     = 1/((2*log10(B))^2)
    resistance = c*(D^5/(lambda*z*T*L*delta));

    return resistance
end


"Transforms network data into per-unit (non-dimensionalized)"
function make_per_unit!(data::Dict{String,Any})
    if !haskey(data, "per_unit") || data["per_unit"] == false
        data["per_unit"] = true
        p_base = data["baseP"]
        q_base = data["baseQ"]
        if InfrastructureModels.ismultinetwork(data)
            for (i,nw_data) in data["nw"]
                _make_per_unit!(nw_data, p_base, q_base)
            end
        else
            _make_per_unit!(data, p_base, q_base)
        end
    end
end


""
function _make_per_unit!(data::Dict{String,Any}, p_base::Real, q_base::Real)
    rescale_q      = x -> x/q_base
    rescale_p      = x -> x/p_base
    rescale_psqr   = x -> x/p_base^2

    if haskey(data, "junction")
        for (i, junction) in data["junction"]
            _apply_func!(junction, "pmax", rescale_p)
            _apply_func!(junction, "pmin", rescale_p)
            _apply_func!(junction, "p", rescale_p)
            _apply_func!(junction, "psqr", rescale_psqr)
        end
    end

    if haskey(data, "consumer")
        for (i, consumer) in data["consumer"]
            _apply_func!(consumer, "qlmin", rescale_q)
            _apply_func!(consumer, "qlmax", rescale_q)
            _apply_func!(consumer, "ql", rescale_q)
            _apply_func!(consumer, "fl", rescale_q)
        end
    end

    if haskey(data, "producer")
        for (i, producer) in data["producer"]
            _apply_func!(producer, "qgmin", rescale_q)
            _apply_func!(producer, "qgmax", rescale_q)
            _apply_func!(producer, "qg", rescale_q)
            _apply_func!(producer, "fg", rescale_q)
        end
    end

    if haskey(data, "pipe")
        for (i, pipe) in data["pipe"]
            _apply_func!(pipe, "f", rescale_q)
        end
    end

    if haskey(data, "compressor")
        for (i, compressor) in data["compressor"]
            _apply_func!(compressor, "f", rescale_q)
            _apply_func!(compressor, "power_max", rescale_q)
        end
    end

    if haskey(data, "resistor")
        for (i, resistor) in data["resistor"]
            _apply_func!(resistor, "f", rescale_q)
        end
    end

    if haskey(data, "short_pipe")
        for (i, pipe) in data["short_pipe"]
            _apply_func!(pipe, "f", rescale_q)
        end
    end

    if haskey(data, "valve")
        for (i, valve) in data["valve"]
            _apply_func!(valve, "f", rescale_q)
        end
    end

    if haskey(data, "control_valve")
        for (i, valve) in data["control_valve"]
            _apply_func!(valve, "f", rescale_q)
        end
    end

end


"Transforms network data into si-units (inverse of per-unit)--non-dimensionalized"
function make_si_unit!(data::Dict{String,Any})
    if haskey(data, "per_unit") && data["per_unit"] == true
        data["per_unit"] = false
        p_base = data["baseP"]
        q_base = data["baseQ"]
        if InfrastructureModels.ismultinetwork(data)
            for (i,nw_data) in data["nw"]
                _make_si_unit!(nw_data, p_base, q_base)
            end
        else
             _make_si_unit!(data, p_base, q_base)
        end
    end
end


""
function _make_si_unit!(data::Dict{String,Any}, p_base::Real, q_base::Real)
    rescale_q      = x -> x*q_base
    rescale_p      = x -> x*p_base
    rescale_psqr   = x -> x*p_base^2

    if haskey(data, "junction")
        for (i, junction) in data["junction"]
            _apply_func!(junction, "pmax", rescale_p)
            _apply_func!(junction, "pmin", rescale_p)
            _apply_func!(junction, "p", rescale_p)
            _apply_func!(junction, "psqr", rescale_psqr)
        end
    end

    if haskey(data, "consumer")
        for (i, consumer) in data["consumer"]
            _apply_func!(consumer, "qlmin", rescale_q)
            _apply_func!(consumer, "qlmax", rescale_q)
            _apply_func!(consumer, "ql", rescale_q)
            _apply_func!(consumer, "fl", rescale_q)
        end
    end

    if haskey(data, "producer")
        for (i, producer) in data["producer"]
            _apply_func!(producer, "qgmin", rescale_q)
            _apply_func!(producer, "qgmax", rescale_q)
            _apply_func!(producer, "qg", rescale_q)
            _apply_func!(producer, "fg", rescale_q)
        end
    end

    if haskey(data, "pipe")
        for (i, pipe) in data["pipe"]
            _apply_func!(pipe, "f", rescale_q)
        end
    end

    if haskey(data, "compressor")
        for (i, compressor) in data["compressor"]
            _apply_func!(compressor, "f", rescale_q)
            _apply_func!(compressor, "power_max", rescale_q)
        end
    end

    if haskey(data, "resistor")
        for (i, resistor) in data["resistor"]
            _apply_func!(resistor, "f", rescale_q)
        end
    end

    if haskey(data, "short_pipe")
        for (i, pipe) in data["short_pipe"]
            _apply_func!(pipe, "f", rescale_q)
        end
    end

    if haskey(data, "valve")
        for (i, valve) in data["valve"]
            _apply_func!(valve, "f", rescale_q)
        end
    end

    if haskey(data, "control_valve")
        for (i, valve) in data["control_valve"]
            _apply_func!(valve, "f", rescale_q)
        end
    end
end


""
function _apply_func!(data::Dict{String,Any}, key::String, func)
    if haskey(data, key)
        data[key] = func(data[key])
    end
end


"calculates minimum mass flow consumption"
function _calc_flmin(data::Dict{String,Any}, consumer::Dict{String,Any})
    return consumer["qlmin"] * data["standard_density"]
end


"calculates maximum mass flow consumption"
function _calc_flmax(data::Dict{String,Any}, consumer::Dict{String,Any})
    return consumer["qlmax"] * data["standard_density"]
end


"calculates constant mass flow consumption"
function _calc_fl(data::Dict{String,Any}, consumer::Dict{String,Any})
    return consumer["ql"] * data["standard_density"]
end


"calculates minimum mass flow production"
function _calc_fgmin(data::Dict{String,Any}, producer::Dict{String,Any})
    return producer["qgmin"] * data["standard_density"]
end


"calculates maximum mass flow production"
function _calc_fgmax(data::Dict{String,Any}, producer::Dict{String,Any})
    return producer["qgmax"] * data["standard_density"]
end


"calculates constant mass flow production"
function _calc_fg(data::Dict{String,Any}, producer::Dict{String,Any})
    return producer["qg"] * data["standard_density"]
end


"calculates the minimum flow on a pipe"
function _calc_pipe_fmin(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_min         = ref[:pipe_ref][k][:pd_min]
    w              = ref[:pipe_ref][k][:w]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a pipe"
function _calc_pipe_fmax(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_max         = ref[:pipe_ref][k][:pd_max]
    w              = ref[:pipe_ref][k][:w]
    pf_max         = pd_max < 0 ? -sqrt(w*abs(pd_max)) : sqrt(w*abs(pd_max))
    return min(mf, pf_max)
end


"calculates the minimum flow on a resistor"
function _calc_resistor_fmin(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_min         = ref[:resistor_ref][k][:pd_min]
    w              = ref[:resistor_ref][k][:w]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a resistor"
function _calc_resistor_fmax(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_max         = ref[:resistor_ref][k][:pd_max]
    w              = ref[:resistor_ref][k][:w]
    pf_max         = pd_max < 0 ? -sqrt(w*abs(pd_max)) : sqrt(w*abs(pd_max))
    return min(mf, pf_max)
end


"calculates the minimum flow on a pipe"
function _calc_ne_pipe_fmin(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_min         = ref[:ne_pipe_ref][k][:pd_min]
    w              = ref[:ne_pipe_ref][k][:w]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a pipe"
function _calc_ne_pipe_fmax(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_max         = ref[:ne_pipe_ref][k][:pd_max]
    w              = ref[:ne_pipe_ref][k][:w]
    pf_max         = pd_max < 0 ? -sqrt(w*abs(pd_max)) : sqrt(w*abs(pd_max))
    return min(mf, pf_max)
end


"calculates the minimum flow on a short pipe"
function _calc_short_pipe_fmin(ref::Dict{Symbol,Any}, k)
    return -ref[:max_mass_flow]
end


"calculates the maximum flow on a short pipe"
function _calc_short_pipe_fmax(ref::Dict{Symbol,Any}, k)
    return ref[:max_mass_flow]
end


"calculates the minimum flow on a valve"
function _calc_valve_fmin(ref::Dict{Symbol,Any}, k)
    return -ref[:max_mass_flow]
end


"calculates the maximum flow on a valve"
function _calc_valve_fmax(ref::Dict{Symbol,Any}, k)
    return ref[:max_mass_flow]
end


"calculates the minimum flow on a compressor"
function _calc_compressor_fmin(ref::Dict{Symbol,Any}, k)
    return -ref[:max_mass_flow]
end


"calculates the maximum flow on a compressor"
function _calc_compressor_fmax(ref::Dict{Symbol,Any}, k)
    return ref[:max_mass_flow]
end


"calculates the minimum flow on an expansion compressor"
function _calc_ne_compressor_fmin(ref::Dict{Symbol,Any}, k)
    return -ref[:max_mass_flow]
end


"calculates the maximum flow on an expansion compressor"
function _calc_ne_compressor_fmax(ref::Dict{Symbol,Any}, k)
    return ref[:max_mass_flow]
end


"calculates the minimum flow on a control valve"
function _calc_control_valve_fmin(ref::Dict{Symbol,Any}, k)
    return -ref[:max_mass_flow]
end


"calculates the maximum flow on a control valve"
function _calc_control_valve_fmax(ref::Dict{Symbol,Any}, k)
    return ref[:max_mass_flow]
end


"prints the text summary for a data file or dictionary to stdout"
function print_summary(obj::Union{String, Dict{String,Any}}; kwargs...)
    summary(stdout, obj; kwargs...)
end


"calculates connections in parallel with one another and their orientation"
function _calc_parallel_ne_connections(gm::AbstractGasModel, n::Int, connection::Dict{String,Any})
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])

    parallel_pipes          = haskey(ref(gm,n,:parallel_pipes), (i,j)) ? ref(gm,n,:parallel_pipes, (i,j)) : []
    parallel_compressors    = haskey(ref(gm,n,:parallel_compressors), (i,j)) ? ref(gm,n,:parallel_compressors, (i,j)) : []
    parallel_short_pipes    = haskey(ref(gm,n,:parallel_short_pipes), (i,j)) ? ref(gm,n,:parallel_short_pipes, (i,j)) : []
    parallel_resistors      = haskey(ref(gm,n,:parallel_resistors), (i,j)) ? ref(gm,n,:parallel_resistors, (i,j)) : []
    parallel_valves         = haskey(ref(gm,n,:parallel_valves), (i,j)) ? ref(gm,n,:parallel_valves, (i,j)) : []
    parallel_control_valves = haskey(ref(gm,n,:parallel_control_valves), (i,j)) ? ref(gm,n,:parallel_control_valves, (i,j)) : []
    parallel_ne_pipes       = haskey(ref(gm,n,:parallel_ne_pipes), (i,j)) ? ref(gm,n,:parallel_ne_pipes, (i,j)) : []
    parallel_ne_compressors = haskey(ref(gm,n,:parallel_ne_compressors), (i,j)) ? ref(gm,n,:parallel_ne_compressors, (i,j)) : []

    num_connections = length(parallel_pipes) + length(parallel_compressors) + length(parallel_short_pipes) + length(parallel_resistors) +
                      length(parallel_valves) + length(parallel_control_valves) + length(parallel_ne_pipes) + length(parallel_ne_compressors)

    pipes = ref(gm,n,:pipe)
    compressors = ref(gm,n,:compressor)
    resistors = ref(gm,n,:resistor)
    short_pipes = ref(gm,n,:short_pipe)
    valves = ref(gm,n,:valve)
    control_valves = ref(gm,n,:control_valve)
    ne_pipes = ref(gm,n,:ne_pipe)
    ne_compressors = ref(gm,n,:ne_compressor)

    aligned_pipes           = filter(i -> pipes[i]["f_junction"] == connection["f_junction"], parallel_pipes)
    opposite_pipes          = filter(i -> pipes[i]["f_junction"] != connection["f_junction"], parallel_pipes)
    aligned_compressors     = filter(i -> compressors[i]["f_junction"] == connection["f_junction"], parallel_compressors)
    opposite_compressors    = filter(i -> compressors[i]["f_junction"] != connection["f_junction"], parallel_compressors)
    aligned_resistors       = filter(i -> resistors[i]["f_junction"] == connection["f_junction"], parallel_resistors)
    opposite_resistors      = filter(i -> resistors[i]["f_junction"] != connection["f_junction"], parallel_resistors)
    aligned_short_pipes     = filter(i -> short_pipes[i]["f_junction"] == connection["f_junction"], parallel_short_pipes)
    opposite_short_pipes    = filter(i -> short_pipes[i]["f_junction"] != connection["f_junction"], parallel_short_pipes)
    aligned_valves          = filter(i -> valves[i]["f_junction"] == connection["f_junction"], parallel_valves)
    opposite_valves         = filter(i -> valves[i]["f_junction"] != connection["f_junction"], parallel_valves)
    aligned_control_valves  = filter(i -> control_valves[i]["f_junction"] == connection["f_junction"], parallel_control_valves)
    opposite_control_valves = filter(i -> control_valves[i]["f_junction"] != connection["f_junction"], parallel_control_valves)
    aligned_ne_pipes        = filter(i -> ne_pipes[i]["f_junction"] == connection["f_junction"], parallel_ne_pipes)
    opposite_ne_pipes       = filter(i -> ne_pipes[i]["f_junction"] != connection["f_junction"], parallel_ne_pipes)
    aligned_ne_compressors  = filter(i -> ne_compressors[i]["f_junction"] == connection["f_junction"], parallel_ne_compressors)
    opposite_ne_compressors = filter(i -> ne_compressors[i]["f_junction"] != connection["f_junction"], parallel_ne_compressors)

    return num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_control_valves, opposite_control_valves, aligned_ne_pipes, opposite_ne_pipes, aligned_ne_compressors, opposite_ne_compressors
end


"calculates connections in parallel with one another and their orientation"
function _calc_parallel_connections(gm::AbstractGasModel, n::Int, connection::Dict{String,Any})
    i = min(connection["f_junction"], connection["t_junction"])
    j = max(connection["f_junction"], connection["t_junction"])

    parallel_pipes          = haskey(ref(gm,n,:parallel_pipes), (i,j)) ? ref(gm,n,:parallel_pipes, (i,j)) : []
    parallel_compressors    = haskey(ref(gm,n,:parallel_compressors), (i,j)) ? ref(gm,n,:parallel_compressors, (i,j)) : []
    parallel_short_pipes    = haskey(ref(gm,n,:parallel_short_pipes), (i,j)) ? ref(gm,n,:parallel_short_pipes, (i,j)) : []
    parallel_resistors      = haskey(ref(gm,n,:parallel_resistors), (i,j)) ? ref(gm,n,:parallel_resistors, (i,j)) : []
    parallel_valves         = haskey(ref(gm,n,:parallel_valves), (i,j)) ? ref(gm,n,:parallel_valves, (i,j)) : []
    parallel_control_valves = haskey(ref(gm,n,:parallel_control_valves), (i,j)) ? ref(gm,n,:parallel_control_valves, (i,j)) : []

    num_connections = length(parallel_pipes) + length(parallel_compressors) + length(parallel_short_pipes) + length(parallel_resistors) +
                      length(parallel_valves) + length(parallel_control_valves)

    pipes = ref(gm,n,:pipe)
    compressors = ref(gm,n,:compressor)
    resistors = ref(gm,n,:resistor)
    short_pipes = ref(gm,n,:short_pipe)
    valves = ref(gm,n,:valve)
    control_valves = ref(gm,n,:control_valve)

    aligned_pipes           = filter(i -> pipes[i]["f_junction"] == connection["f_junction"], parallel_pipes)
    opposite_pipes          = filter(i -> pipes[i]["f_junction"] != connection["f_junction"], parallel_pipes)
    aligned_compressors     = filter(i -> compressors[i]["f_junction"] == connection["f_junction"], parallel_compressors)
    opposite_compressors    = filter(i -> compressors[i]["f_junction"] != connection["f_junction"], parallel_compressors)
    aligned_resistors       = filter(i -> resistors[i]["f_junction"] == connection["f_junction"], parallel_resistors)
    opposite_resistors      = filter(i -> resistors[i]["f_junction"] != connection["f_junction"], parallel_resistors)
    aligned_short_pipes     = filter(i -> short_pipes[i]["f_junction"] == connection["f_junction"], parallel_short_pipes)
    opposite_short_pipes    = filter(i -> short_pipes[i]["f_junction"] != connection["f_junction"], parallel_short_pipes)
    aligned_valves          = filter(i -> valves[i]["f_junction"] == connection["f_junction"], parallel_valves)
    opposite_valves         = filter(i -> valves[i]["f_junction"] != connection["f_junction"], parallel_valves)
    aligned_control_valves  = filter(i -> control_valves[i]["f_junction"] == connection["f_junction"], parallel_control_valves)
    opposite_control_valves = filter(i -> control_valves[i]["f_junction"] != connection["f_junction"], parallel_control_valves)

    return num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_control_valves, opposite_control_valves
end


"prints the text summary for a data file to IO"
function summary(io::IO, file::String; kwargs...)
    data = parse_file(file)
    summary(io, data; kwargs...)
    return data
end


const _gm_component_types_order = Dict(
    "junction" => 1.0, "connection" => 2.0, "producer" => 3.0, "consumer" => 4.0
)


const _gm_component_parameter_order = Dict(
    "junction_i" => 1.0, "junction_type" => 2.0,
    "pmin" => 3.0, "pmax" => 4.0, "p_nominal" => 5.0,

    "type" => 10.0,
    "f_junction" => 11.0, "t_junction" => 12.0,
    "length" => 13.0, "diameter" => 14.0, "friction_factor" => 15.0,
    "qmin" => 16.0, "qmax" => 17.0,
    "c_ratio_min" => 18.0, "c_ratio_max" => 19.0,
    "power_max" => 20.0,

    "producer_i" => 50.0, "junction" => 51.0,
    "qg" => 52.0, "qgmin" => 53.0, "qgmax" => 54.0,

    "consumer_i" => 70.0, "junction" => 71.0,
    "ql" => 72.0, "qlmin" => 73.0, "qlmax" => 74.0,

    "status" => 500.0,
)


"prints the text summary for a data dictionary to IO"
function summary(io::IO, data::Dict{String,Any}; kwargs...)
    InfrastructureModels.summary(io, data;
        component_types_order = _gm_component_types_order,
        component_parameter_order = _gm_component_parameter_order,
        kwargs...)
end


"Helper function for determining if direction cuts can be applied"
function _apply_mass_flow_cuts(yp, branches)
    is_disjunction = true
    for k in branches
        is_disjunction &= isassigned(yp,k)
    end
    return is_disjunction
end


"extracts the start value"
function comp_start_value(set, item_key, value_key, default = 0.0)
    return get(get(set, item_key, Dict()), value_key, default)
end
