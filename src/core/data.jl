# tools for working with GasModels internal data format

"Computes the maximum volume of the Gas Model"
function _calc_max_volume_flow(data::Dict{String,Any})
    max_flow = 0
    for (idx, receipt) in data["receipt"]
        if receipt["qgmax"] > 0
          max_flow = max_flow + receipt["qgmax"]
        end
    end
    return max_flow
end


"Computes the max mass flow in the Gas Model"
function _calc_max_mass_flow(data::Dict{String,Any})
    return _calc_max_volume_flow(data) * data["standard_density"]
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

"calculates minimum mass flow consumption"
function _calc_flmin(data::Dict{String,Any}, delivery::Dict{String,Any})
    return delivery["qlmin"] * data["standard_density"]
end


"calculates maximum mass flow consumption"
function _calc_flmax(data::Dict{String,Any}, delivery::Dict{String,Any})
    return delivery["qlmax"] * data["standard_density"]
end


"calculates constant mass flow consumption"
function _calc_fl(data::Dict{String,Any}, delivery::Dict{String,Any})
    return delivery["ql"] * data["standard_density"]
end


"calculates minimum mass flow production"
function _calc_fgmin(data::Dict{String,Any}, receipt::Dict{String,Any})
    return receipt["qgmin"] * data["standard_density"]
end


"calculates maximum mass flow production"
function _calc_fgmax(data::Dict{String,Any}, receipt::Dict{String,Any})
    return receipt["qgmax"] * data["standard_density"]
end


"calculates constant mass flow production"
function _calc_fg(data::Dict{String,Any}, receipt::Dict{String,Any})
    return receipt["qg"] * data["standard_density"]
end


"calculates the minimum flow on a pipe"
function _calc_pipe_fmin(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_min         = ref[:pipe][k]["pd_min"]
    w              = ref[:pipe][k]["resistance"]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a pipe"
function _calc_pipe_fmax(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_max         = ref[:pipe][k]["pd_max"]
    w              = ref[:pipe][k]["resistance"]
    pf_max         = pd_max < 0 ? -sqrt(w*abs(pd_max)) : sqrt(w*abs(pd_max))
    return min(mf, pf_max)
end


"calculates the minimum flow on a resistor"
function _calc_resistor_fmin(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_min         = ref[:resistor][k]["pd_min"]
    w              = ref[:resistor][k]["resistance"]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a resistor"
function _calc_resistor_fmax(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_max         = ref[:resistor][k]["pd_max"]
    w              = ref[:resistor][k]["resistance"]
    pf_max         = pd_max < 0 ? -sqrt(w*abs(pd_max)) : sqrt(w*abs(pd_max))
    return min(mf, pf_max)
end


"calculates the minimum flow on a pipe"
function _calc_ne_pipe_fmin(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_min         = ref[:ne_pipe][k]["pd_min"]
    w              = ref[:ne_pipe][k]["resistance"]
    pf_min         = pd_min < 0 ? -sqrt(w*abs(pd_min)) : sqrt(w*abs(pd_min))
    return max(-mf, pf_min)
end


"calculates the maximum flow on a pipe"
function _calc_ne_pipe_fmax(ref::Dict{Symbol,Any}, k)
    mf             = ref[:max_mass_flow]
    pd_max         = ref[:ne_pipe][k]["pd_max"]
    w              = ref[:ne_pipe][k]["resistance"]
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
function _calc_regulator_fmin(ref::Dict{Symbol,Any}, k)
    return -ref[:max_mass_flow]
end


"calculates the maximum flow on a control valve"
function _calc_regulator_fmax(ref::Dict{Symbol,Any}, k)
    return ref[:max_mass_flow]
end


"prints the text summary for a data file or dictionary to stdout"
function print_summary(obj::Union{String, Dict{String,Any}}; kwargs...)
    summary(stdout, obj; kwargs...)
end


"prints the text summary for a data file to IO"
function summary(io::IO, file::String; kwargs...)
    data = parse_file(file)
    summary(io, data; kwargs...)
    return data
end


const _gm_component_types_order = Dict(
    "junction" => 1.0, "connection" => 2.0, "receipt" => 3.0, "delivery" => 4.0
)


const _gm_component_parameter_order = Dict(
    "junction_i" => 1.0, "junction_type" => 2.0,
    "p_min" => 3.0, "p_max" => 4.0, "p_nominal" => 5.0,

    "type" => 10.0,
    "fr_junction" => 11.0, "to_junction" => 12.0,
    "length" => 13.0, "diameter" => 14.0, "friction_factor" => 15.0,
    "qmin" => 16.0, "qmax" => 17.0,
    "c_ratio_min" => 18.0, "c_ratio_max" => 19.0,
    "power_max" => 20.0,

    "receipt_i" => 50.0, "junction" => 51.0,
    "qg" => 52.0, "qgmin" => 53.0, "qgmax" => 54.0,

    "delivery_i" => 70.0, "junction" => 71.0,
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



"checks pressure min/max on junctions"
function check_pressure_limits(data::Dict{String,<:Any})
    if get(data, "is_per_unit", false) == true
        base_pressure = get(data, "base_pressure", calc_base_pressure(data))
    else
        base_pressure = 1.0
    end

    for (i, junction) in get(data, "junction", Dict())
        if junction["p_min"] * base_pressure < 0.0 || junction["p_max"] * base_pressure < 0.0
            Memento.error(_LOGGER, "p_min or p_max at junction $i is < 0")
        end

        if get(data, "is_english_units", false) == true
            if junction["p_min"] * base_pressure < 300.0
                Memento.warn(_LOGGER, "p_min $(junction["p_min"] * base_pressure) at junction $i is < 300 PSI")
            end

            if junction["p_max"] * base_pressure > 850.0
                Memento.warn(_LOGGER, "p_max $(junction["p_max"] * base_pressure) at junction $i is > 850 PSI")
            end
        end

        if get(data, "is_si_units", false) == true
            if junction["p_min"] * base_pressure < 2.068e6
                Memento.warn(_LOGGER, "p_min $(junction["p_min"] * base_pressure) at junction $i is < 2.068e6 Pa (300 PSI)")
            end

            if junction["p_max"] * base_pressure > 5.861e6
                Memento.warn(_LOGGER, "p_max $(junction["p_max"] * base_pressure) at junction $i is > 5.861e6 Pa (850 PSI)")
            end
        end

    end
end


"checks pipe diameters and friction factors"
function check_pipe_parameters(data::Dict{String,<:Any})
    for (i, pipe) in get(data, "pipe", Dict())
        if get(data, "is_si_units", false) == true
            if pipe["diameter"] < 0.1 || pipe["diameter"] > 1.6
                if pipe["diameter"] < 0.0
                    Memento.error(_LOGGER, "diameter of pipe $i is < 0 m")
                else
                    Memento.warn(_LOGGER, "diameter $(pipe["diameter"]) m of pipe $i is unrealistic")
                end
            end
        end

        if get(data, "is_english_units", false) == true
            if inches_to_m(pipe["diameter"]) < 0.1 || inches_to_m(pipe["diameter"]) > 1.6
                if inches_to_m(pipe["diameter"]) < 0.0
                    Memento.error(_LOGGER, "diameter of pipe $i is < 0.0 m")
                else
                    Memento.warn(_LOGGER, "diameter $(inches_to_m(pipe["diameter"])) m of pipe $i is unrealistic")
                end
            end
        end

        if pipe["friction_factor"] < 0.0005 || pipe["friction_factor"] > 0.1
            if pipe["friction_factor"] < 0
                Memento.error(_LOGGER, "friction factor of pipe $i is < 0")
            else
                Memento.warn(_LOGGER, "friction factor $(pipe["friction_factor"]) of pipe $i is unrealistic")
            end
        end
    end
end


"check compressor ratios, powers, and mass flows"
function check_compressor_parameters(data::Dict{String,<:Any})
    # need to add some data integrity checks here
end




"""
computes the connected components of the network graph
returns a set of sets of juntion ids, each set is a connected component
"""
function calc_connected_components(data::Dict{String,<:Any}; edges=_gm_edge_types)
    if InfrastructureModels.ismultinetwork(data)
        Memento.error(_LOGGER, "calc_connected_components does not yet support multinetwork data")
    end

    active_junction = Dict(x for x in data["junction"] if x.second["status"] != 0)
    active_junction_ids = Set{Int64}([junction["junction_i"] for (i,junction) in active_junction])

    neighbors = Dict(i => [] for i in active_junction_ids)
    for edge_type in edges
        for edge in values(get(data, edge_type, Dict()))
            if get(edge, "status", 1) != 0 && edge["fr_junction"] in active_junction_ids && edge["to_junction"] in active_junction_ids
                push!(neighbors[edge["fr_junction"]], edge["to_junction"])
                push!(neighbors[edge["to_junction"]], edge["fr_junction"])
            end
        end
    end

    component_lookup = Dict(i => Set{Int64}([i]) for i in active_junction_ids)
    touched = Set{Int64}()

    for i in active_junction_ids
        if !(i in touched)
            _dfs(i, neighbors, component_lookup, touched)
        end
    end

    ccs = (Set(values(component_lookup)))

    return ccs
end


"perModels DFS on a graph"
function _dfs(i, neighbors, component_lookup, touched)
    push!(touched, i)
    for j in neighbors[i]
        if !(j in touched)
            new_comp = union(component_lookup[i], component_lookup[j])
            for k in new_comp
                component_lookup[k] = new_comp
            end
            _dfs(j, neighbors, component_lookup, touched)
        end
    end
end








"for converting data types from old gasmodels to new matlab format"
const _old_gm_matlab_data_map = Dict{String,String}(
    "regulator" => "regulator",
    "delivery" => "receipt",
    "receipt" => "delivery",
    "gas_specific_gravity" => "specific_gravity",
    "gas_molar_mass" => "molar_mass",
    "baseP" => "base_pressure",
    "baseF" => "base_flow",
    "baseQ" => "base_flow"
)


"for converting data fields from old gasmodels to new matlab format"
const _old_gm_matlab_field_map = Dict{String,Dict{String,String}}(
    "junction"  => Dict(
        "junction_i" => "id",
        "p_min" => "pressure_lb",
        "p_max" => "pressure_ub",
        "p" => "pressure",
    ),
    "compressor" => Dict(
        "compressor_i" => "id",
        "fr_junction" => "fr_junction",
        "to_junction" => "to_junction",
        "c_ratio_min" => "compression_ratio_lb",
        "c_ratio_max" => "compression_ratio_ub",
        "power_max" => "power_ub",
        "qmin" => "flow_lb",
        "qmax" => "flow_ub",
    ),
    "pipe" => Dict(
        "pipe_i" => "id",
        "fr_junction" => "fr_junction",
        "to_junction" => "to_junction"
    ),
    "short_pipe" => Dict(
        "short_pipe_i" => "id",
        "fr_junction" => "fr_junction",
        "to_junction" => "to_junction"
    ),
    "resistor" => Dict(
        "resistor_i" => "id",
        "fr_junction" => "fr_junction",
        "to_junction" => "to_junction"
    ),
    "regulator" => Dict(
        "regulator_i" => "id",
        "fr_junction" => "fr_junction",
        "to_junction" => "to_junction",
        "c_ratio_min" => "reduction_factor_lb",
        "c_ratio_max" => "reduction_factor_ub",
        "qmin" => "flow_lb",
        "qmax" => "flow_ub"
    ),
    "valve" => Dict(
        "valve_i" => "id",
        "fr_junction" => "fr_junction",
        "to_junction" => "to_junction"
    ),
    "delivery" => Dict(
        "delivery_i" => "id",
        "qlmin" => "flow_lb",
        "qlmax" => "flow_ub",
        "ql" => "flow",
        "qlfirm" => "flow",
        "ql_junc" => "junction"
    ),
    "receipt" => Dict(
        "receipt_i" => "id",
        "qgmin" => "flow_lb",
        "qgmax" => "flow_ub",
        "qg" => "flow",
        "qgfirm" => "flow",
        "qg_junc" => "junction"
    )
)


"converts old gasmodels format to new"
function _convert_old_gm!(data::Dict{String,Any})

    for (comp_type, fields) in _old_gm_matlab_field_map
        if haskey(data, comp_type)
            for (i, comp) in data[comp_type]
                for (old_field, new_field) in fields
                    # @warn comp_type old_field new_field i comp
                    if old_field == "$(comp_type)_i" && !haskey(comp, old_field)
                        comp[new_field] = parse(Int, i)
                    elseif haskey(comp, old_field)
                        comp[new_field] = deepcopy(comp[old_field])
                        delete!(comp, old_field)
                    end
                end
            end
        end
    end

    for (old_item, new_item) in _old_gm_matlab_data_map
        if haskey(data, old_item)
            # @warn old_item new_item
            data[new_item] = deepcopy(data[old_item])
            delete!(data, old_item)
        end
    end

    for comp_type in _matlab_data_order
        if haskey(data, comp_type)
            for (i, comp) in data[comp_type]
                comp["index"] = get(comp, "index", parse(Int, i))
                comp["status"] = get(comp, "status", 1)

                if comp_type == "junction"
                    comp["type"] = get(comp, "type", 0)
                    comp["pressure"] = get(comp, "pressure", 0.0)
                end

                if comp_type in ["delivery", "receipt"]
                    comp["is_dispatchable"] = get(comp, "dispatchable", 0)
                    comp["flow"] = get(comp, "flow", 0.0)
                end

                if comp_type == "compressor"
                    comp["flow_lb"] = get(comp, "flow_lb", 0.0)
                    comp["flow_ub"] = get(comp, "flow_ub", 1.0)  # TODO needs correct value
                    comp["power_ub"] = get(comp, "power_ub", 1e6)
                end

                if comp_type == "regulator"
                    comp["flow_lb"] = get(comp, "flow_lb", 0.0)
                    comp["flow_ub"] = get(comp, "flow_ub", 1.0)  # TODO needs correct value
                end
            end
        end
    end

    data["specific_gravity"] = get(data, "specific_gravity", 0.6)
    data["specific_heat_capacity_ratio"] = get(data, "specific_heat_capacity_ratio", 1.4)
    data["temperature"] = get(data, "temperature", 273.15)
    data["compressibility_factor"] = get(data, "compressibility_factor", 0.8)
    data["R"] = get(data, "R", 8.314)
    data["sound_speed"] = get(data, "sound_speed", 312.805)
    data["molar_mass"] = get(data, "molar_mass", 0.0185674)

    for param in _matlab_global_params_order_required
        if !haskey(data, param)
            @warn "missing $param"
        end
    end

    for (comp_type, fields) in _matlab_field_order
        if haskey(data, comp_type)
            for (i, comp) in data[comp_type]
                for field in fields
                    if !haskey(comp, field)
                        @warn "$comp_type $i does not have required field for matlab output $field"
                    end
                end
            end
        end
    end
end


"helper function to quickly convert old json files"
function _convert_old_json!(path)
    files = filter(x -> endswith(x, ".json") && !startswith(x, "grail"), readdir(path))
    for file in files
        @info file
        data = GasModels.parse_file("$path/$file")
        GasModels._convert_old_gm!(data)
        data["name"] = get(data, "name", file[1:end-5])
        GasModels.write_matlab!(data, "$path/new_matlab/$(file[1:end-5]).m")
    end
end


"helper function to quickly convert old matlab files"
function _convert_old_matlab!(path)
    files = filter(x -> endswith(x, ".m"), readdir(path))
    for file in files
        @info file
        data = GasModels.parse_file("$path/$file"; skip_correct=true)
        GasModels._convert_old_gm!(data)
        data["name"] = get(data, "name", file[1:end-2])
        GasModels.write_matlab!(data, "$path/new_matlab/$file")
    end
end
