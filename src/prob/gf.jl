# Definitions for running a feasible gas flow

# Note that this particular formulation assumes the binary variable implementation of flow direction
# We would need to do some abstraction to support the absolute value formulation

export run_gf

" entry point into running the gas flow feasability problem "
function run_gf(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_gf; kwargs...) 
end

""
function run_soc_gf(file, solver; kwargs...)
    return run_pf(file, MISOCPGasModel, solver; kwargs...)
end

""
function run_nl_gf(file, solver; kwargs...)
    return run_pf(file, MINLPGasModel, solver; kwargs...)
end

" construct the gas flow feasbility problem "
function post_gf(gm::GenericGasModel)
    variable_pressure_sqr(gm)
    variable_flux(gm)
    variable_connection_direction(gm)
    variable_flux_square(gm)
    variable_valve_operation(gm)

    for (i,junction) in gm.ref[:junction]
        constraint_junction_flow_balance(gm, i)
      
        if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0 
            constraint_source_flow(gm, i)
        end      
        
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
            constraint_sink_flow(gm, i)
        end      
                
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree"] == 2
           constraint_conserve_flow(gm, i)           
        end        
    end
    
    for (i,connection) in gm.ref[:connection]
        constraint_flow_direction_choice(gm, i)
        constraint_parallel_flow(gm, i)
    end
    
    for i in [collect(keys(gm.ref[:pipe])); collect(keys(gm.ref[:resistor]))]
        constraint_on_off_pressure_drop(gm, i)
        constraint_on_off_pipe_flow_direction(gm, i)
        constraint_weymouth(gm, i)        
    end

    for (i,pipe) in gm.ref[:short_pipe]
        constraint_short_pipe_pressure_drop(gm, i)
        constraint_on_off_short_pipe_flow_direction(gm, i)      
    end
        
    for (i, compressor) in gm.ref[:compressor]
        constraint_on_off_compressor_flow_direction(gm, i)
        constraint_on_off_compressor_ratios(gm, i)    
    end
    
    for (i,valve) in gm.ref[:valve]    
        constraint_on_off_valve_flow_direction(gm, i)
        constraint_on_off_valve_pressure_drop(gm, i)  
    end
    
    for (i, valve) in gm.ref[:control_valve]    
        constraint_on_off_control_valve_flow_direction(gm, i)
        constraint_on_off_control_valve_pressure_drop(gm, i)  
    end
end

