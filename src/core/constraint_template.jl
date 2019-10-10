#
# Constraint Template Definitions
#
# Constraint templates help simplify data wrangling across multiple Gas
# Flow formulations by providing an abstraction layer between the network data
# and network constraint definitions.  The constraint template's job is to
# extract the required parameters from a given network data structure and
# pass the data as named arguments to the Gas Flow formulations.
#
# Constraint templates should always be defined over "AbstractGasModel"
# and should never refer to model variables

###############################################################################################
# Templates for constraints associated with resistors
###############################################################################################

"Template: Constraint on mass flow across a pipe"
function constraint_resistor_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm,n,:resistor,k)
    f_min          = ref(gm,n,:resistor_ref,k)[:f_min]
    f_max          = ref(gm,n,:resistor_ref,k)[:f_max]
    constraint_resistor_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Constraint on flow across a resistor where the flow is constrained to one direction as defined by data attribute directed"
function constraint_resistor_mass_flow_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm,n,:resistor,k)
    direction      = pipe["directed"]
    f_min          = (direction == 1) ? 0 : ref(gm,n,:resistor_ref,k)[:f_min]
    f_max          = (direction == 1) ? ref(gm,n,:resistor_ref,k)[:f_max] : 0
    constraint_resistor_mass_flow_directed(gm, n, k, f_min, f_max)
end


"Template: Pressure drop across resistor with on/off direction variables"
function constraint_resistor_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm, n,:resistor, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_max         = ref(gm,n,:resistor_ref)[k][:pd_max]
    pd_min         = ref(gm,n,:resistor_ref)[k][:pd_min]
    constraint_resistor_pressure(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Constraint on pressure drop across a resistor where the flow is constrained to one direction as defined by data attribute directed"
function constraint_resistor_pressure_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm, n,:resistor, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    direction      = pipe["directed"]
    pd_max         = (direction == 1) ? ref(gm,n,:resistor_ref,k)[:pd_max] : min(0, ref(gm,n,:resistor_ref,k)[:pd_max])
    pd_min         = (direction == 1) ? max(0, ref(gm,n,:resistor_ref,k)[:pd_min]) : ref(gm,n,:resistor_ref,k)[:pd_min]
    constraint_resistor_pressure_directed(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Weymouth equation for defining the relationship between pressure drop and flow across a resistor"
function constraint_resistor_weymouth(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe    = ref(gm,n,:resistor,k)
    i       = pipe["f_junction"]
    j       = pipe["t_junction"]
    w       = ref(gm,n,:resistor_ref,k)[:w]
    pd_max  = ref(gm,n,:resistor_ref,k)[:pd_max]
    pd_min  = ref(gm,n,:resistor_ref,k)[:pd_min]
    f_min   = ref(gm,n,:resistor_ref,k)[:f_min]
    f_max   = ref(gm,n,:resistor_ref,k)[:f_max]
    constraint_resistor_weymouth(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max)
end


"Template: Weymouth equation for defining the relationship between pressure drop and flow across a resistor where flow is constrained in one direction"
function constraint_resistor_weymouth_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe      = ref(gm,n,:resistor,k)
    i         = pipe["f_junction"]
    j         = pipe["t_junction"]
    w         = ref(gm,n,:resistor_ref,k)[:w]
    direction = pipe["directed"]
    f_min     = ref(gm,n,:resistor_ref,k)[:f_min]
    f_max     = ref(gm,n,:resistor_ref,k)[:f_max]
    constraint_resistor_weymouth_directed(gm, n, k, i, j, w, f_min, f_max, direction)
end


#################################################################################################
# Templates for constraints associated with pipes
#################################################################################################

"Template: Constraint on mass flow across a pipe"
function constraint_pipe_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm,n,:pipe,k)
    f_min          = ref(gm,n,:pipe_ref,k)[:f_min]
    f_max          = ref(gm,n,:pipe_ref,k)[:f_max]
    constraint_pipe_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Constraint on flow across a pipe where the flow is constrained to one direction as defined by data attribute directed"
function constraint_pipe_mass_flow_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm,n,:pipe,k)
    direction      = pipe["directed"]
    f_min          = (direction == 1) ? 0 : ref(gm,n,:pipe_ref,k)[:f_min]
    f_max          = (direction == 1) ? ref(gm,n,:pipe_ref,k)[:f_max] : 0
    constraint_pipe_mass_flow_directed(gm, n, k, f_min, f_max)
end


"Template: Pressure drop across pipes with on/off direction variables"
function constraint_pipe_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm, n,:pipe, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_max         = ref(gm,n,:pipe_ref,k)[:pd_max]
    pd_min         = ref(gm,n,:pipe_ref,k)[:pd_min]
    constraint_pipe_pressure(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Constraint on pressure drop across a pipe where the flow is constrained to one direction as defined by data attribute directed"
function constraint_pipe_pressure_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm, n,:pipe,k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    direction      = pipe["directed"]
    pd_max         = (direction == 1) ? ref(gm,n,:pipe_ref,k)[:pd_max] : min(0, ref(gm,n,:pipe_ref,k)[:pd_max])
    pd_min         = (direction == 1) ? max(0, ref(gm,n,:pipe_ref,k)[:pd_min]) : ref(gm,n,:pipe_ref,k)[:pd_min]
    constraint_pipe_pressure_directed(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Constraints on flow across an expansion pipe with on/off direction variables"
function constraint_pipe_mass_flow_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe = ref(gm,n,:ne_pipe, k)
    pd_max         = ref(gm,n,:ne_pipe_ref,k)[:pd_max]
    pd_min         = ref(gm,n,:ne_pipe_ref,k)[:pd_min]
    w              = ref(gm,n,:ne_pipe_ref,k)[:w]
    f_min          = ref(gm,n,:ne_pipe_ref,k)[:f_min]
    f_max          = ref(gm,n,:ne_pipe_ref,k)[:f_max]
    constraint_pipe_mass_flow_ne(gm, n, k, f_min, f_max)
end


"Template: Constraints on pressure drop across pipes"
function constraint_pipe_pressure_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe = ref(gm,n,:ne_pipe,k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_max         = ref(gm,n,:ne_pipe_ref,k)[:pd_max]
    pd_min         = ref(gm,n,:ne_pipe_ref,k)[:pd_min]
    constraint_pipe_pressure_ne(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Constraint on pressure drop across an expansion pipe where the flow is constrained to one direction as defined by data attribute directed"
function constraint_pipe_pressure_ne_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm,n,:ne_pipe,k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    direction      = pipe["directed"]
    pd_max         = ref(gm,n,:ne_pipe_ref,k)[:pd_max]
    pd_min         = ref(gm,n,:ne_pipe_ref,k)[:pd_min]
    constraint_pipe_pressure_ne_directed(gm, n, k, i, j, pd_min, pd_max, direction)
end


"Template: Constraints on flow across an expansion pipe where the flow is constrained to one direction"
function constraint_pipe_mass_flow_ne_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = ref(gm,n,:ne_pipe, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    direction      = pipe["directed"]
    f_min          = (direction == 1) ? 0 : ref(gm,n,:ne_pipe_ref,k)[:f_min]
    f_max          = (direction == 1) ? ref(gm,n,:ne_pipe_ref,k)[:f_max] : 0
    constraint_pipe_mass_flow_ne_directed(gm, n, k, f_min, f_max)
end


"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe"
function constraint_pipe_weymouth(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe    = ref(gm,n,:pipe,k)
    i       = pipe["f_junction"]
    j       = pipe["t_junction"]
    w       = ref(gm,n,:pipe_ref,k)[:w]
    pd_max  = ref(gm,n,:pipe_ref,k)[:pd_max]
    pd_min  = ref(gm,n,:pipe_ref,k)[:pd_min]
    f_min   = ref(gm,n,:pipe_ref,k)[:f_min]
    f_max   = ref(gm,n,:pipe_ref,k)[:f_max]
    constraint_pipe_weymouth(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max)
end


"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe where flow is constrained in one direction"
function constraint_pipe_weymouth_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe      = ref(gm,n,:pipe,k)
    i         = pipe["f_junction"]
    j         = pipe["t_junction"]
    w         = ref(gm,n,:pipe_ref,k)[:w]
    direction = pipe["directed"]
    f_min     = ref(gm,n,:pipe_ref,k)[:f_min]
    f_max     = ref(gm,n,:pipe_ref,k)[:f_max]
    constraint_pipe_weymouth_directed(gm, n, k, i, j, w, f_min, f_max, direction)
end


"Template: Constraint associatd with turning off flow depending on the status of expansion pipes"
function constraint_pipe_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe   = gm.ref[:nw][n][:ne_pipe][k]
    w      = ref(gm,n,:ne_pipe_ref,k)[:w]
    f_min  = ref(gm,n,:ne_pipe_ref,k)[:f_min]
    f_max  = ref(gm,n,:ne_pipe_ref,k)[:f_max]
    constraint_pipe_ne(gm, n, k, w, f_min, f_max)
end


"Template: Weymouth equation for expansion pipes"
function constraint_pipe_weymouth_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = gm.ref[:nw][n][:ne_pipe][k]
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    w              = ref(gm,n,:ne_pipe_ref,k)[:w]
    pd_max         = ref(gm,n,:ne_pipe_ref,k)[:pd_max]
    pd_min         = ref(gm,n,:ne_pipe_ref,k)[:pd_min]
    f_min          = ref(gm,n,:ne_pipe_ref,k)[:f_min]
    f_max          = ref(gm,n,:ne_pipe_ref,k)[:f_max]
    constraint_pipe_weymouth_ne(gm, n, k, i, j, w, f_min, f_max, pd_min, pd_max)
end


"Template: Weymouth equation for expansion pipes where flow is restricted to one direction"
function constraint_pipe_weymouth_ne_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = gm.ref[:nw][n][:ne_pipe][k]
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    w              = ref(gm,n,:ne_pipe_ref,k)[:w]
    direction      = pipe["directed"]
    pd_max         = ref(gm,n,:ne_pipe_ref,k)[:pd_max]
    pd_min         = ref(gm,n,:ne_pipe_ref,k)[:pd_min]
    f_min          = ref(gm,n,:ne_pipe_ref,k)[:f_min]
    f_max          = ref(gm,n,:ne_pipe_ref,k)[:f_max]
    constraint_pipe_weymouth_ne_directed(gm, n, k, i, j, w, pd_min, pd_max, f_min, f_max, direction)
end


#################################################################################################
# Templates for constraints associated with junctions
#################################################################################################

"Template: Constraints for fixing pressure at a node"
function constraint_pressure(gm::AbstractGasModel, i; n::Int=gm.cnw)
    junction       = gm.ref[:nw][n][:junction][i]
    p              = junction["p"]^2
    constraint_pressure(gm, n, i, p)
end


"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_mass_flow_balance(gm::AbstractGasModel, i; n::Int=gm.cnw)
    junction                = ref(gm,n,:junction,i)
    f_pipes                 = ref(gm,n,:f_pipes,i)
    t_pipes                 = ref(gm,n,:t_pipes,i)
    f_compressors           = ref(gm,n,:f_compressors,i)
    t_compressors           = ref(gm,n,:t_compressors,i)
    f_resistors             = ref(gm,n,:f_resistors,i)
    t_resistors             = ref(gm,n,:t_resistors,i)
    f_short_pipes           = ref(gm,n,:f_short_pipes,i)
    t_short_pipes           = ref(gm,n,:t_short_pipes,i)
    f_valves                = ref(gm,n,:f_valves,i)
    t_valves                = ref(gm,n,:t_valves,i)
    f_control_valves        = ref(gm,n,:f_control_valves,i)
    t_control_valves        = ref(gm,n,:t_control_valves,i)
    consumer                = ref(gm,n,:consumer)
    producer                = ref(gm,n,:producer)
    consumers               = ref(gm,n,:junction_consumers,i)
    producers               = ref(gm,n,:junction_producers,i)
    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)
    fg                      = length(nondispatch_producers) > 0 ? sum(_calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl                      = length(nondispatch_consumers) > 0 ? sum(_calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0
    fgmax                   = length(dispatch_producers) > 0 ? sum(_calc_fgmax(gm.data, producer[j]) for j in dispatch_producers) : 0
    flmax                   = length(dispatch_consumers) > 0 ? sum(_calc_flmax(gm.data, consumer[j]) for j in dispatch_consumers) : 0
    fgmin                   = length(dispatch_producers) > 0 ? sum(_calc_fgmin(gm.data, producer[j]) for j in dispatch_producers) : 0
    flmin                   = length(dispatch_consumers) > 0 ? sum(_calc_flmin(gm.data, consumer[j]) for j in dispatch_consumers) : 0

    constraint_mass_flow_balance(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, fl, fg, dispatch_consumers, dispatch_producers, flmin, flmax, fgmin, fgmax)
end


"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables and there are expansion connections"
function constraint_mass_flow_balance_ne(gm::AbstractGasModel, i; n::Int=gm.cnw)
    junction         = ref(gm,n,:junction,i)
    consumer         = ref(gm,n,:consumer)
    producer         = ref(gm,n,:producer)
    consumers        = ref(gm,n,:junction_consumers,i)
    producers        = ref(gm,n,:junction_producers,i)
    f_pipes          = ref(gm,n,:f_pipes,i)
    t_pipes          = ref(gm,n,:t_pipes,i)
    f_compressors    = ref(gm,n,:f_compressors,i)
    t_compressors    = ref(gm,n,:t_compressors,i)
    f_resistors      = ref(gm,n,:f_resistors,i)
    t_resistors      = ref(gm,n,:t_resistors,i)
    f_short_pipes    = ref(gm,n,:f_short_pipes,i)
    t_short_pipes    = ref(gm,n,:t_short_pipes,i)
    f_valves         = ref(gm,n,:f_valves,i)
    t_valves         = ref(gm,n,:t_valves,i)
    f_control_valves = ref(gm,n,:f_control_valves,i)
    t_control_valves = ref(gm,n,:t_control_valves,i)
    f_ne_pipes       = ref(gm,n,:f_ne_pipes,i)
    t_ne_pipes       = ref(gm,n,:t_ne_pipes,i)
    f_ne_compressors = ref(gm,n,:f_ne_compressors,i)
    t_ne_compressors = ref(gm,n,:t_ne_compressors,i)


    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg        = length(nondispatch_producers) > 0 ? sum(_calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl        = length(nondispatch_consumers) > 0 ? sum(_calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0
    fgmax     = length(dispatch_producers) > 0 ? sum(_calc_fgmax(gm.data, producer[j])  for  j in dispatch_producers)  : 0
    flmax     = length(dispatch_consumers) > 0 ? sum(_calc_flmax(gm.data, consumer[j])  for  j in dispatch_consumers)  : 0
    fgmin     = length(dispatch_producers) > 0 ? sum(_calc_fgmin(gm.data, producer[j])  for  j in dispatch_producers)  : 0
    flmin     = length(dispatch_consumers) > 0 ? sum(_calc_flmin(gm.data, consumer[j])  for  j in dispatch_consumers)  : 0

    constraint_mass_flow_balance_ne(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_control_valves, t_control_valves, f_ne_pipes, t_ne_pipes, f_ne_compressors, t_ne_compressors, fl, fg, dispatch_consumers, dispatch_producers, flmin, flmax, fgmin, fgmax)
end


#################################################################################################
# Templates for constraints associated with short pipes
#################################################################################################

"Template: Constraint on pressure drop across a short pipe"
function constraint_short_pipe_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe = ref(gm,n,:short_pipe,k)
    i    = pipe["f_junction"]
    j    = pipe["t_junction"]
    constraint_short_pipe_pressure(gm, n, k, i, j)
end


"Constraint: constraints on flow across a short pipe"
function constraint_short_pipe_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe    = ref(gm,n,:short_pipe,k)
    f_min   = ref(gm,n,:short_pipe_ref,k)[:f_min]
    f_max   = ref(gm,n,:short_pipe_ref,k)[:f_max]
    constraint_short_pipe_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Constraint on flow across a short pipe when the flow direction is constrained in one direction"
function constraint_short_pipe_mass_flow_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe      = ref(gm,n,:short_pipe,k)
    i         = pipe["f_junction"]
    j         = pipe["t_junction"]
    direction = pipe["directed"]
    f_min     = (direction == 1) ? 0 : ref(gm,n,:short_pipe_ref,k)[:f_min]
    f_max     = (direction == 1) ? ref(gm,n,:short_pipe_ref,k)[:f_max] : 0
    constraint_short_pipe_mass_flow_directed(gm, n, k, f_min, f_max)
end


#################################################################################################
# Templates for constraints associated with valves
#################################################################################################

"Template: Constraint on pressure drop across valves, where the valve may be closed or opened"
function constraint_on_off_valve_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve  = ref(gm,n,:valve,k)
    i      = valve["f_junction"]
    j      = valve["t_junction"]
    j_pmax = gm.ref[:nw][n][:junction][j]["pmax"]
    i_pmax = gm.ref[:nw][n][:junction][i]["pmax"]
    constraint_on_off_valve_pressure(gm, n, k, i, j, i_pmax, j_pmax)
end


"Template: constraints on flow across valves modeled with on/off direction variables"
function constraint_on_off_valve_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve = ref(gm,n,:valve,k)
    f_min = ref(gm,n,:valve_ref,k)[:f_min]
    f_max = ref(gm,n,:valve_ref,k)[:f_max]
    constraint_on_off_valve_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Constraints on flow across a valve when flow is restricted in one direction and the valve may be turned on or off"
function constraint_on_off_valve_mass_flow_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve     = ref(gm,n,:valve,k)
    direction = valve["directed"]
    f_min     = (direction == 1) ? 0 : ref(gm,n,:valve_ref,k)[:f_min]
    f_max     = (direction == 1) ? ref(gm,n,:valve_ref,k)[:f_max] : 0
    constraint_on_off_valve_mass_flow_directed(gm, n, k, f_min, f_max)
end


#################################################################################################
# Templates for constraints associated with compressors
#################################################################################################

"Template: Compression ratios for a compressor"
function constraint_compressor_ratios(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:compressor,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    constraint_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax)
end


"Template: Constraint for turning on or off flow through expansion compressor"
function constraint_compressor_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = gm.ref[:nw][n][:ne_compressor][k]
    f_min      = ref(gm,n,:ne_compressor_ref,k)[:f_min]
    f_max      = ref(gm,n,:ne_compressor_ref,k)[:f_max]
    constraint_compressor_ne(gm, n, k, f_min, f_max)
end


"Template: Constraints on compressor ratios when flow is restricted to one direction"
function constraint_compressor_ratios_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:compressor,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    direction      = compressor["directed"]
    constraint_compressor_ratios_directed(gm, n, k, i, j, min_ratio, max_ratio, direction)
end


"Template: constraints on flow across a compressor"
function constraint_compressor_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = ref(gm, n, :compressor, k)
    f_min      = ref(gm,n,:compressor_ref,k)[:f_min]
    f_max      = ref(gm,n,:compressor_ref,k)[:f_max]
    constraint_compressor_mass_flow(gm, n, k, f_min, f_max)
end


"Template: constraints on flow across compressors where direction"
function constraint_compressor_mass_flow_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:ne_compressor,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    f_min          = ref(gm,n,:ne_compressor_ref,k)[:f_min]
    f_max          = ref(gm,n,:ne_compressor_ref,k)[:f_max]
    constraint_compressor_mass_flow_ne(gm, n, k, f_min, f_max)
end


"Template: Constraints on flow across a compressor when flow is restricted to one direction"
function constraint_compressor_mass_flow_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = ref(gm, n, :compressor, k)
    i          = compressor["f_junction"]
    j          = compressor["t_junction"]
    direction  = compressor["directed"]
    f_min      = (direction == 1) ? 0 : ref(gm,n,:compressor_ref,k)[:f_min]
    f_max      = (direction == 1) ? ref(gm,n,:compressor_ref,k)[:f_max] : 0
    constraint_compressor_mass_flow_directed(gm, n, k, f_min, f_max)
end


"Template: constraints on pressure drop across a compressor"
function constraint_compressor_ratios_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:ne_compressor, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    j_pmin         = ref(gm,n,:junction,j)["pmin"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmin         = ref(gm,n,:junction,i)["pmin"]
    f_max          = ref(gm,n,:ne_compressor_ref,k)[:f_max]
    constraint_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax)
end


"Template: Constraints on compressor ratios when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_ratios_ne_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = ref(gm,n,:ne_compressor, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmin         = ref(gm,n,:junction,i)["pmin"]
    f_max          = ref(gm,n,:ne_compressor_ref,k)[:f_max]
    direction      = compressor["directed"]
    constraint_compressor_ratios_ne_directed(gm, n, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, direction)
end


"Template: Constraints on compressor flows when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_mass_flow_ne_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = ref(gm,n,:ne_compressor,k)
    i          = compressor["f_junction"]
    j          = compressor["t_junction"]
    mf         = ref(gm,n,:max_mass_flow)
    direction  = compressor["directed"]
    f_min     = (direction == 1) ? 0 : ref(gm,n,:ne_compressor_ref,k)[:f_min]
    f_max     = (direction == 1) ? ref(gm,n,:ne_compressor_ref,k)[:f_max] : 0
    constraint_compressor_mass_flow_ne_directed(gm, n, k, f_min, f_max)
end


"Template: Constraints on the compressor ratio value"
function constraint_compressor_ratio_value(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:compressor,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    constraint_compressor_ratio_value(gm, n, k, i, j)
end


"Template: Constraints on the compressor energy"
function constraint_compressor_energy(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:compressor,k)
    power_max      = compressor["power_max"]
    gamma          = ref(gm,n,:specific_heat_capacity_ratio)
    magic_num      = 286.76
    m              = ((gamma - 1) / gamma) / 2
    T              = ref(gm,n,:temperature)
    G              = ref(gm,n,:gas_specific_gravity)
    work           = ((magic_num / G) * T * (gamma/(gamma-1)))
    constraint_compressor_energy(gm, n, k, power_max, m, work)
end


#################################################################################################
# Templates for control valves
#################################################################################################

"Template: constraints on flow across control valves with on/off direction variables"
function constraint_on_off_control_valve_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve = ref(gm,n,:control_valve,k)
    f_min = ref(gm,n,:control_valve_ref,k)[:f_min]
    f_max = ref(gm,n,:control_valve_ref,k)[:f_max]
    constraint_on_off_control_valve_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Constraints on control valve flows when flow is restricted to one direction"
function constraint_on_off_control_valve_mass_flow_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve      = ref(gm,n,:control_valve,k)
    i          = valve["f_junction"]
    j          = valve["t_junction"]
    direction  = valve["directed"]
    f_min = (direction == 1) ? 0 : ref(gm,n,:control_valve_ref,k)[:f_min]
    f_max = (direction == 1) ? ref(gm,n,:control_valve_ref,k)[:f_max] : 0
    constraint_on_off_control_valve_mass_flow_directed(gm, n, k, f_min, f_max)
end


"Constraint Enforces pressure changes bounds that obey decompression ratios for"
function constraint_on_off_control_valve_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    control_valve = ref(gm,n,:control_valve,k)
    i             = control_valve["f_junction"]
    j             = control_valve["t_junction"]
    max_ratio     = control_valve["c_ratio_max"]
    min_ratio     = control_valve["c_ratio_min"]
    j_pmin        = ref(gm,n,:junction,j)["pmin"]
    j_pmax        = ref(gm,n,:junction,j)["pmax"]
    i_pmax        = ref(gm,n,:junction,i)["pmax"]
    i_pmin        = ref(gm,n,:junction,i)["pmin"]
    f_max         = ref(gm,n,:control_valve_ref,k)[:f_max] #mf
    constraint_on_off_control_valve_pressure(gm, n, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax)
end


"Template: Constraints on control valve pressure when flow is restricted to one direction"
function constraint_on_off_control_valve_pressure_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve     = ref(gm,n,:control_valve,k)
    i         = valve["f_junction"]
    j         = valve["t_junction"]
    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]
    j_pmax    = ref(gm,n,:junction,j)["pmax"]
    i_pmax    = ref(gm,n,:junction,i)["pmax"]
    direction = valve["direction"]
    constraint_on_off_control_valve_pressure_directed(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, direction)
end


#################################################################################################
# Templates for misc constraints
#################################################################################################

"Template: Constraint which restricts selction of expansion pipes that are in paralell to a single one"
function constraint_exclusive_new_pipes(gm::AbstractGasModel, i, j; n::Int=gm.cnw)
    parallel = ref(gm,n,:parallel_ne_pipes, (i,j))
    constraint_exclusive_new_pipes(gm, n, i, j, parallel)
end
