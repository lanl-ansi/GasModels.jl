# Definitions for running a pipe expansion problem

export run_ne

" entry point into running the gas flow feasability problem "
function run_ne(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_ne; solution_builder = get_ne_solution, kwargs...) 
end

" construct the gas flow feasbility problem "
function post_ne(gm::GenericGasModel)
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_flux_ne(gm)  
    variable_connection_direction(gm) 
    variable_connection_direction_ne(gm)     
    
    variable_valve_operation(gm)

    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    # expansion cost objective
    objective_min_ne_cost(gm)

    for (i,junction) in gm.ref[:nw][gm.cnw][:junction]
        constraint_junction_flow_balance_ne(gm, i) 
        if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0
            constraint_source_flow_ne(gm, i) 
        end
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
            constraint_sink_flow_ne(gm, i)
        end              
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree_all"] == 2
           constraint_conserve_flow_ne(gm, i)
        end            
    end

    for i in ids(gm, :connection) #gm.ref[:connection]
        constraint_flow_direction_choice(gm, i) 
        constraint_parallel_flow_ne(gm, i)  
    end
    
    for i in ids(gm, :ne_connection) #gm.ref[:ne_connection]
        constraint_flow_direction_choice_ne(gm, i) 
        constraint_parallel_flow_ne(gm, i)  
    end

    for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] #[collect(keys(gm.ref[:pipe])); collect(keys(gm.ref[:resistor]))]
        constraint_on_off_pressure_drop(gm, i) 
        constraint_on_off_pipe_flow_direction(gm, i) 
        constraint_weymouth(gm, i)
    end

    for i in ids(gm,:ne_pipe) #gm.ref[:ne_pipe]
        constraint_on_off_pressure_drop_ne(gm, i) 
        constraint_on_off_pipe_flow_direction_ne(gm, i) 
        constraint_on_off_pipe_flow_ne(gm, i) 
        constraint_weymouth_ne(gm, i) 
    end
    
    for i in ids(gm, :short_pipe) #gm.ref[:short_pipe]
        constraint_short_pipe_pressure_drop(gm, i)
        constraint_on_off_short_pipe_flow_direction(gm, i)      
    end
    
    # We assume that we already have a short pipe connecting two nodes 
    # and we just want to add a compressor to it.  Use constraint 
    # constraint_on_off_compressor_flow_expansion to disallow flow
    # if the compressor is not built 
    for i in ids(gm, :compressor) #gm.ref[:compressor]
        constraint_on_off_compressor_flow_direction(gm, i) 
        constraint_on_off_compressor_ratios(gm, i)         
    end
    for i in ids(gm, :ne_compressor) #gm.ref[:ne_compressor]
        constraint_on_off_compressor_flow_direction_ne(gm, i) 
        constraint_on_off_compressor_ratios_ne(gm, i) 
    end  
         
    for i in ids(gm, :valve) #gm.ref[:valve]    
        constraint_on_off_valve_flow_direction(gm, i)
        constraint_on_off_valve_pressure_drop(gm, i)  
    end
    
    for i in ids(gm, :control_valve) #gm.ref[:control_valve]    
        constraint_on_off_control_valve_flow_direction(gm, i)
        constraint_on_off_control_valve_pressure_drop(gm, i)  
    end
    
    exclusive = Dict()
    for (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]
        i = min(pipe["f_junction"],pipe["t_junction"])
        j = max(pipe["f_junction"],pipe["t_junction"])
   
        if haskey(exclusive, i) == false  
            exclusive[i] = Dict()
        end  
           
        if haskey(exclusive[i], j) == false 
            constraint_exclusive_new_pipes(gm, i, j)         
            exclusive[i][j] = true
        end             
    end  
end




















# Special function for whether or not a connection is added
function add_connection_ne{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "ne_connection", "built", :zp; default_value = (item) -> 1)
end

# Get the direction solutions
function add_direction_ne_setpoint{T}(sol, gm::GenericGasModel{T})
    add_setpoint(sol, gm, "ne_connection", "yp", :yp_ne)
    add_setpoint(sol, gm, "ne_connection", "yn", :yn_ne)    
end

# Get all the solution values
function get_ne_solution{T}(gm::GenericGasModel{T},sol::Dict{String,Any})
    add_junction_pressure_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    add_connection_ne(sol, gm)
    add_direction_setpoint(sol, gm)
    add_direction_ne_setpoint(sol, gm)
end
