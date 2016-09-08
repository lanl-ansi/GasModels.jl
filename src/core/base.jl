# stuff that is universal to all gas models

export 
    GenericGasModel,
    setdata, setsolver, solve

# Gas data
type GasDataSets
    junctions
    junction_indexes
    connections
    connection_indexes
    pipe_indexes
    short_pipe_indexes
    compressor_indexes
    valve_indexes
    control_valve_indexes
    resistor_indexes
    new_pipes
    new_compressors 
    junction_connections
    parallel_connections       
end

abstract AbstractGasModel
abstract AbstractGasFormulation
#abstract AbstractConicGasFormulation <: AbstractGasFormulation



type GenericGasModel{T<:AbstractGasFormulation} <: AbstractGasModel
    model::Model
    data::Dict{AbstractString,Any}
    set::GasDataSets
    setting::Dict{AbstractString,Any}
    solution::Dict{AbstractString,Any}
end


# default generic constructor
function GenericGasModel{T}(data::Dict{AbstractString,Any}, vars::T; setting = Dict{AbstractString,Any}(), solver = JuMP.UnsetSolver())
    data, sets = process_raw_data(data)

    gm = GenericGasModel{T}(
        Model(solver = solver), # model
        data, # data
        sets, # sets
        setting, # setting
        Dict{AbstractString,Any}(), # solution
    )

    return gm
end

# function for augmenting the data sets
function process_raw_data(data::Dict{AbstractString,Any})
  
    sets = build_sets(data)

    # TODO, process the data about share paths etc. 
    add_network_structure(data)
    
    return data, sets
end

# Set the solver
function JuMP.setsolver(gm::GenericGasModel, solver::MathProgBase.AbstractMathProgSolver)
    setsolver(gm.model, solver)
end

# Do a solve of the problem
function JuMP.solve(gm::GenericGasModel)
    status, solve_time, solve_bytes_alloc, sec_in_gc = @timed solve(gm.model)

    try
        solve_time = getsolvetime(gm.model)
    catch
        warn("there was an issue with getsolvetime() on the solver, falling back on @timed.  This is not a rigorous timing value.");
    end

    return status, solve_time
end

# do the run on the abstract model
function run_generic_model(file, model_constructor, solver, post_method; solution_builder = get_solution, kwargs...)
    data = GasModels.parse_file(file)

    gm = model_constructor(data; solver = solver, kwargs...)

    post_method(gm)

    status, solve_time = solve(gm)

    return build_solution(gm, status, solve_time; solution_builder = solution_builder)
end

# build all the sets that we need for making things easier
function build_sets(data :: Dict{AbstractString,Any})
    junction_lookup = [ Int(junction["index"]) => junction for junction in data["junction"] ]
    connection_lookup = [ Int(connection["index"]) => connection for connection in data["connection"] ]
                
    # filter turned off stuff 
    connection_lookup = filter((i, connection) -> connection["status"] == 1 && connection["f_junction"] in keys(junction_lookup) && pipe["t_junction"] in keys(junction_lookup), connection_lookup)

    junction_idxs = collect(keys(junction_lookup))
    connection_idxs = collect(keys(connection_lookup))
    
    pipe_idxs = i in filter((i, connection) -> connection["type"] == "pipe", connection_lookup)
    short_pipe_idxs = i in filter((i, connection) -> connection["type"] == "short_pipe", connection_lookup)
    compressor_idxs = i in filter((i, connection) -> connection["type"] == "compressor", connection_lookup)
    valve_idxs = i in filter((i, connection) -> connection["type"] == "valve", connection_lookup)
    control_valve_idxs = i in filter((i, connection) -> connection["type"] == "control_valve", connection_lookup)
    resistor_idxs = i in filter((i, connection) -> connection["type"] == "resistor", connection_lookup)

    new_pipes = i in filter((i, connection) -> connection["type"] == "pipe" && (hasKey("construction_cost",connection]) && connection["construction_cost"] != 0), connection_lookup)
    new_compressors = i in filter((i, connection) -> connection["type"] == "compressor" && (hasKey("construction_cost",connection]) && connection["construction_cost"] != 0), connection_lookup)
      
    arcs_from = [(i,connection["f_junction"],connection["t_junction"]) for (i,connection) in connection_lookup]
    arcs_to   = [(i,connection["t_junction"],connection["f_junction"]) for (i,connection) in connection_lookup]
    arcs = [arcs_from; arcs_to]
      
    parallel_connections = [(i,j) => [] for (l,i,j) in arcs && i < j]     
    junction_connections = [i => [] for (i,junction) in junction_lookup]

    for connection in data["connection"]
        i = connection["f_junction"]
        j = connection["t_junction"]
        idx = connection["idx"]
                      
        push!(junction_branches[i], idx)
        push!(junction_branches[j], idx)
        
        push!(parallel_connections[ (min(i,j), max(i,j))], idx)
        
    end
                
    return GasDataSets(junction_lookup, junction_idxs, connection_lookup, connection_idxs, pipe_idxs, short_pipe_idxs, compressor_idxs, valve_idxs, control_valve_idxs, resistor_idxs, new_pipes, new_compressors, junction_connections,parallel_connections      
end

# Add some necessary data structures for constructing various constraints and variables
function add_network_structure(data :: Dict{AbstractString,Any}, set :: GasDataSets)
    max_flow = 0
  
    for junction in data["junction"]
        if junction["qmax"] > 0
          max_flow = max_flow + junction["qmax"]
        end
        junction["degree"] = 0
    end

    for (i,j) in keys(set.paralell_connections)
        if size(set.paralell_connections) > 0
          set.junctionlookup[i]["degree"] = set.junctionlookup[i]["degree"] + 1
          set.junctionlookup[j]["degree"] = set.junctionlookup[j]["degree"] + 1          
        end
    end
    
    
    data["max_flow"] = max_flow
    
  
    for connection in data["connection"]
        i_idx = connection["f_junction"]
        j_idx = connection["t_junction"]
      
        i = set.junctions[i_idx]  
        j = set.junctions[j_idx]  
                
        pd_max = i["p_max"]^2 - j["p_min"]^2
        pd_min = i["p_min"]^2 - j["p_max"]^2
                 
        branch["pd_max"] =  pd_max
        branch["pd_min"] =  pd_min
     end
     
     
end

