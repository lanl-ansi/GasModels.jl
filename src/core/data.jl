# tools for working with GasModels internal data format

"Computes the maximum flow of the Gas Model"
function calc_max_flow(data::Dict{String,Any})
    max_flow = 0
    for (idx, producer) in data["producer"]
        if producer["qgmax"] > 0
          max_flow = max_flow + producer["qgmax"]
        end
        if producer["qgfirm"] > 0
          max_flow = max_flow + producer["qgfirm"]
        end
    end
    return max_flow
end

"Ensures that status exists as a field in connections"
function add_default_status(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)
    
    for (n,data) in nws_data
        for entry in [data["connection"]; data["ne_connection"]; data["junction"]; data["consumer"]; data["producer"]]
            for (idx,component) in entry
                if !haskey(component,"status")
                    component["status"] = 1
                end
            end
        end
    end
end

"Ensures that construction cost exists as a field for new connections"
function add_default_construction_cost(data::Dict{String,Any})
    nws_data = data["multinetwork"] ? data["nw"] : nws_data = Dict{String,Any}("0" => data)
    
    for (n,data) in nws_data
        for (idx, connection) in data["ne_connection"]
            if !haskey(connection,"construction_cost")
                connection["construction_cost"] = 0
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

""
function calc_pipe_resistance(data::Dict{String,Any}, pipe::Dict{String,Any})
    if (pipe["type"] == "pipe")
        return calc_pipe_resistance_thorley(data, pipe)
    else
        return calc_resistor_resistance_simple(data, pipe)
    end    
end


"Calculates pipeline resistance from this paperARD Thorley and CH Tiley. Unsteady and transient flow of compressible
fluids in pipelines–a review of theoretical and some experimental studies.
International Journal of Heat and Fluid Flow, 8(1):3–15, 1987
This is used in many of Zlotniks papers"
function calc_pipe_resistance_thorley(data::Dict{String,Any}, pipe::Dict{String,Any})
    R          = 8.314 # universal gas constant     
    z          = data["compressibility_factor"]
    T          = data["temperature"]
    m          = data["gas_molar_mass"]
    lambda     = pipe["friction_factor"]
    D          = pipe["diameter"]  
    L          = pipe["length"]  
     
    a_sqr = z * (R/m) * T          
    resistance = 2 * D / (lambda * L * a_sqr) 
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
    resistance = 2 * D / (lambda * L * a_sqr) 
    return resistance 
end


"Calculate the pipe resistance using the method described in De Wolf and Smeers. The Gas Transmission Problem Solved by an Extension of the Simplex Algorithm. Management Science. 46 (11) 1454-1465, 2000
 This function assumes that diameters are in mm, lengths are in km, volumetric flow is in 10^6 m^3/day, and pressure is in bars"
function calc_pipe_resistance_smeers(pipe::Dict{String,Any})
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


"prints the text summary for a data file or dictionary to STDOUT"
function print_summary(obj::Union{String, Dict{String,Any}}; kwargs...)
    summary(STDOUT, obj; kwargs...)
end

"prints the text summary for a data file to IO"
function summary(io::IO, file::String; kwargs...)
    data = parse_file(file)
    InfrastructureModels.summary(io, data; kwargs...)
    return data
end

"prints the text summary for a data dictionary to IO"
function summary(io::IO, data::Dict{String,Any}; kwargs...)
    InfrastructureModels.summary(io, data; kwargs...)
end