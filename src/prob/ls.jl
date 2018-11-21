# Definitions for running a minimum load shed model

# Note that this particular formulation assumes the binary variable implementation of flow direction
# We would need to do some abstraction to support the absolute value formulation

export run_ls

" entry point into running the gas flow feasability problem "
function run_ls(file, model_constructor, solver; kwargs...)
    return run_generic_model(file, model_constructor, solver, post_ls; solution_builder = get_ls_solution, kwargs...) 
end

" construct the gas flow feasbility problem "
function post_ls(gm::GenericGasModel)
    variable_flow(gm)  
    variable_pressure_sqr(gm)
    variable_valve_operation(gm)
    variable_load_mass_flow(gm)
    variable_production_mass_flow(gm)
        
    objective_max_load(gm)

    for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] 
        constraint_pipe_flow(gm, i) 
    end
    
    for i in ids(gm, :junction)
        constraint_junction_mass_flow_ls(gm, i)
    end
    
    for i in ids(gm, :short_pipe)
        constraint_short_pipe_flow(gm, i) 
    end
        
    for i in ids(gm, :compressor) 
        constraint_compressor_flow(gm, i) 
    end
    
    for i in ids(gm, :valve)
        constraint_valve_flow(gm, i) 
    end
    
    for i in ids(gm, :control_valve) 
        constraint_control_valve_flow(gm, i) 
    end
end

# Get all the load shedding solution values
function get_ls_solution(gm::GenericGasModel,sol::Dict{String,Any})
    add_junction_pressure_setpoint(sol, gm)
    add_connection_flow_setpoint(sol, gm)
    add_direction_setpoint(sol, gm)
    add_load_volume_setpoint(sol, gm)
    add_load_mass_flow_setpoint(sol, gm)
    add_production_volume_setpoint(sol, gm)
    add_production_mass_flow_setpoint(sol, gm)
    add_compressor_ratio_setpoint(sol, gm)
end