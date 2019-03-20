# tools for working with GasModels internal data format

"Computes the maximum volume of the Gas Model"
function calc_max_volume_flow(data::Dict{String,Any})
    max_flow = 0
    for (idx, producer) in data["producer"]
        if producer["qgmax"] > 0
          max_flow = max_flow + producer["qgmax"]
        end
#        if producer["qgfirm"] > 0
#          max_flow = max_flow + producer["qgfirm"]
#        end
    end
    return max_flow
end

"Computes the max mass flow in the Gas Model"
function calc_max_mass_flow(data::Dict{String,Any})
    return calc_max_volume_flow(data) * data["standard_density"]
end

"Ensures that status exists as a field in connections"
function add_default_status(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)
    for (n,data) in nws_data
        for entry in [data["pipe"]; data["compressor"]; data["short_pipe"]; data["resistor"]; data["valve"]; data["control_valve"]; data["ne_pipe"]; data["ne_compressor"]; data["junction"]; data["consumer"]; data["producer"]]
            for (idx,component) in entry
                if !haskey(component,"status")
                    component["status"] = 1
                end
            end
        end
    end
end

"The fields 'yp' and 'yn are used for directionality in many of the math formulations.  If the directed field is included, then we add those values here"
function add_default_direction(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)
    for (n,data) in nws_data
        for entry in [data["pipe"]; data["compressor"]; data["short_pipe"]; data["resistor"]; data["valve"]; data["control_valve"]; data["ne_pipe"]; data["ne_compressor"]]
            for (idx,component) in entry
                if haskey(component,"directed")
                    if component["directed"] == 1
                        component["yp"] = 1
                        component["yn"] = 0
                    end
                    if component["directed"] == -1
                        component["yp"] = 0
                        component["yn"] = 1
                    end
                end
            end
        end
    end
end

"Ensures that consumer priority exists as a field in loads"
function add_default_consumer_priority(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)

    for (n,data) in nws_data
        for (idx,component) in data["consumer"]
            if !haskey(component,"priority")
                component["priority"] = 1
            end
        end
    end
end


"Ensures that construction cost exists as a field for new connections"
function add_default_construction_cost(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)

    for (n,data) in nws_data
        for entry in [data["ne_pipe"];data["ne_compressor"]]
           for (idx, connection) in entry
               if !haskey(connection,"construction_cost")
                   connection["construction_cost"] = 0
               end
           end
        end
    end
end

"Add the degree information"
function add_degree(ref::Dict{Symbol,Any})
    for (i,junction) in ref[:junction]
        junction["degree"] = 0
        junction["degree_all"] = 0
    end

    for (i,j) in keys(ref[:parallel_connections])
        if length(ref[:parallel_connections]) > 0
            ref[:junction][i]["degree"] = ref[:junction][i]["degree"] + 1
            ref[:junction][j]["degree"] = ref[:junction][j]["degree"] + 1
        end
    end

    for (i,j) in keys(ref[:all_parallel_connections])
        if length(ref[:parallel_connections]) > 0
            ref[:junction][i]["degree_all"] = ref[:junction][i]["degree_all"] + 1
            ref[:junction][j]["degree_all"] = ref[:junction][j]["degree_all"] + 1
        end
    end
end

"Add the bounds for minimum and maximum pressure"
function add_pd_bounds_sqr(ref::Dict{Symbol,Any})
    for entry in [ref[:connection]; ref[:ne_connection]]
        for (idx,connection) in entry
            i_idx = connection["f_junction"]
            j_idx = connection["t_junction"]

            i = ref[:junction][i_idx]
            j = ref[:junction][j_idx]

            pd_max = i["pmax"]^2 - j["pmin"]^2
            pd_min = i["pmin"]^2 - j["pmax"]^2

            connection["pd_max"] =  pd_max
            connection["pd_min"] =  pd_min
        end
    end
end

"Calculates pipeline resistance from this paper Thorley and CH Tiley. Unsteady and transient flow of compressible
fluids in pipelines–a review of theoretical and some experimental studies.
International Journal of Heat and Fluid Flow, 8(1):3–15, 1987
This is used in many of Zlotniks papers
This calculation expresses resistance in terms of mass flow equations"
function calc_pipe_resistance_thorley(data::Dict{String,Any}, pipe::Dict{String,Any})
    R          = 8.314 # universal gas constant
    z          = data["compressibility_factor"]
    T          = data["temperature"]
    m          = data["gas_molar_mass"]
    lambda     = pipe["friction_factor"]
    D          = pipe["diameter"]
    L          = pipe["length"]

    a_sqr = z * (R/m) * T
    A     = (pi*D^2) / 4 # cross sectional area
    resistance = ( (D * A^2) / (lambda * L * a_sqr)) * (data["baseP"]^2 / data["baseQ"]^2) # second half is the non-dimensionalization
    return resistance
end

"A very simple model of computing resistance for resistors that is based on the Thorley model.  The are other more realistic models that could
be used.  See Physical and technical fundamentals of gas networks by Fugenschu et al. for an example"
function calc_resistor_resistance_simple(data::Dict{String,Any}, pipe::Dict{String,Any})
    R          = 8.314 # universal gas constant
    z          = data["compressibility_factor"]
    T          = data["temperature"]
    m          = data["gas_molar_mass"]
    lambda     = pipe["drag"]
    D          = pipe["diameter"]
    L          = pipe["length"]

    a_sqr = z * (R/m) * T
    A     = (pi*D^2) / 4 # cross sectional area

    resistance = ( (D * A^2) / (lambda * L * a_sqr)) * (data["baseP"]^2 / data["baseQ"]^2) # second half is the non-dimensionalization
    return resistance
end


"Calculate the pipe resistance using the method described in De Wolf and Smeers. The Gas Transmission Problem Solved by an Extension of the Simplex Algorithm. Management Science. 46 (11) 1454-1465, 2000
 This function assumes that diameters are in mm, lengths are in km, volumetric flow is in 10^6 m^3/day, and pressure is in bars"
function calc_pipe_resistance_smeers(data::Dict{String,Any},pipe::Dict{String,Any})
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
function make_per_unit(data::Dict{String,Any})
    if !haskey(data, "per_unit") || data["per_unit"] == false
        data["per_unit"] = true
        p_base = data["baseP"]
        q_base = data["baseQ"]
        if InfrastructureModels.ismultinetwork(data)
            for (i,nw_data) in data["nw"]
                _make_per_unit(nw_data, p_base, q_base)
            end
        else
            _make_per_unit(data, p_base, q_base)
        end
    end
end


""
function _make_per_unit(data::Dict{String,Any}, p_base::Real, q_base::Real)
    rescale_q      = x -> x/q_base
    rescale_p      = x -> x/p_base

    if haskey(data, "junction")
        for (i, junction) in data["junction"]
            apply_func(junction, "pmax", rescale_p)
            apply_func(junction, "pmin", rescale_p)
        end
    end

    if haskey(data, "consumer")
        for (i, consumer) in data["consumer"]
            apply_func(consumer, "qlmin", rescale_q)
            apply_func(consumer, "qlmax", rescale_q)
            apply_func(consumer, "ql", rescale_q)

        end
    end

    if haskey(data, "producer")
        for (i, producer) in data["producer"]
            apply_func(producer, "qgmin", rescale_q)
            apply_func(producer, "qgmax", rescale_q)
            apply_func(producer, "qg", rescale_q)

        end
    end

end


"Transforms network data into si-units (inverse of per-unit)--non-dimensionalized"
function make_si_units(data::Dict{String,Any})
    if haskey(data, "per_unit") && data["per_unit"] == true
        data["per_unit"] = false
        p_base = data["baseP"]
        q_base = data["baseQ"]
        if InfrastructureModels.ismultinetwork(data)
            for (i,nw_data) in data["nw"]
                _make_si_units(nw_data, p_base, q_base)
            end
        else
             _make_si_units(data, p_base, q_base)
        end
    end
end


""
function _make_si_units(data::Dict{String,Any}, p_base::Real, q_base::Real)
    rescale_q      = x -> x*q_base
    rescale_p      = x -> x*p_base

    if haskey(data, "junction")
        for (i, junction) in data["junction"]
            apply_func(junction, "pmax", rescale_p)
            apply_func(junction, "pmin", rescale_p)
        end
    end

    if haskey(data, "consumer")
        for (i, consumer) in data["consumer"]
            apply_func(consumer, "qlmin", rescale_q)
            apply_func(consumer, "qlmax", rescale_q)
            apply_func(consumer, "ql", rescale_q)

        end
    end

    if haskey(data, "producer")
        for (i, producer) in data["producer"]
            apply_func(producer, "qgmin", rescale_q)
            apply_func(producer, "qgmax", rescale_q)
            apply_func(producer, "qg", rescale_q)

        end
    end
end

""
function apply_func(data::Dict{String,Any}, key::String, func)
    data[key] = func(data[key])
end

"calculates minimum mass flow consumption"
function calc_flmin(data::Dict{String,Any}, consumer::Dict{String,Any})
    consumer["qlmin"] * data["standard_density"]
end

"calculates maximum mass flow consumption"
function calc_flmax(data::Dict{String,Any}, consumer::Dict{String,Any})
    consumer["qlmax"] * data["standard_density"]
end

"calculates constant mass flow consumption"
function calc_fl(data::Dict{String,Any}, consumer::Dict{String,Any})
    consumer["ql"] * data["standard_density"]
end

"calculates minimum mass flow production"
function calc_fgmin(data::Dict{String,Any}, producer::Dict{String,Any})
    producer["qgmin"] * data["standard_density"]
end

"calculates maximum mass flow production"
function calc_fgmax(data::Dict{String,Any}, producer::Dict{String,Any})
    producer["qgmax"] * data["standard_density"]
end

"calculates constant mass flow production"
function calc_fg(data::Dict{String,Any}, producer::Dict{String,Any})
    producer["qg"] * data["standard_density"]
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

gm_component_types_order = Dict(
    "junction" => 1.0, "connection" => 2.0, "producer" => 3.0, "consumer" => 4.0
)

gm_component_parameter_order = Dict(
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
        component_types_order = gm_component_types_order,
        component_parameter_order = gm_component_parameter_order,
        kwargs...)
end
