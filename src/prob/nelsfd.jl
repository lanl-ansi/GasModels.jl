# Definitions for running a pipe expansion problem to maximize load when the directions of
# of the pipes is fixed.

export run_nelsfd

" entry point into running the gas flow feasability problem "
function run_nelsfd(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_nelsfd; solution_builder = get_ne_solution, kwargs...) 
end

" construct the gas flow expansion problem to maximize load "
function post_nelsfd(gm::GenericGasModel)
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_flux_ne(gm)  
    variable_flux_square(gm) 
    variable_flux_square_ne(gm)         
    variable_valve_operation(gm)
    variable_load(gm)
    variable_production(gm)
    
    # expansion variables
    variable_pipe_ne(gm)
    variable_compressor_ne(gm)

    # expansion cost objective
    objective_max_load(gm)

    for (i,junction) in gm.ref[:junction]
        constraint_junction_flow_balance_ne_ls(gm, i) 
    end

    for i in [collect(keys(gm.ref[:pipe])); collect(keys(gm.ref[:resistor]))]
        constraint_on_off_pressure_drop_fixed_direction(gm, i) 
        constraint_on_off_pipe_flow_direction_fixed_direction(gm, i) 
        constraint_weymouth_fixed_direction(gm, i)
    end

    for (i, pipe) in gm.ref[:ne_pipe]
        constraint_on_off_pressure_drop_ne_fixed_direction(gm, i) 
        constraint_on_off_pipe_flow_direction_ne_fixed_direction(gm, i) 
        constraint_on_off_pipe_flow_ne(gm, i) 
        constraint_weymouth_ne_fixed_direction(gm, i) 
    end
    
    for (i, pipe) in gm.ref[:short_pipe]
        constraint_short_pipe_pressure_drop(gm, i)
        constraint_on_off_short_pipe_flow_direction_fixed_direction(gm, i)      
    end
    
    # We assume that we already have a short pipe connecting two nodes 
    # and we just want to add a compressor to it.  Use constraint 
    # constraint_on_off_compressor_flow_expansion to disallow flow
    # if the compressor is not built 
    for (i, compressor) in gm.ref[:compressor]
        constraint_on_off_compressor_flow_direction_fixed_direction(gm, i) 
        constraint_on_off_compressor_ratios_fixed_direction(gm, i)         
    end

    for (i, compressor) in gm.ref[:ne_compressor]
        constraint_on_off_compressor_flow_direction_ne_fixed_direction(gm, i) 
        constraint_on_off_compressor_ratios_ne_fixed_direction(gm, i) 
    end  
          
    for (i, valve) in gm.ref[:valve]    
        constraint_on_off_valve_flow_direction_fixed_direction(gm, i)
        constraint_on_off_valve_pressure_drop(gm, i)  
    end
    
    for (i, valve) in gm.ref[:control_valve]    
        constraint_on_off_control_valve_flow_direction_fixed_direction(gm, i)
        constraint_on_off_control_valve_pressure_drop_fixed_direction(gm, i)  
    end
    
    exclusive = Dict()
    for (idx, pipe) in gm.ref[:ne_pipe]
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


