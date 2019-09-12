#
# Constraint Template Definitions
#
# Constraint templates help simplify data wrangling across multiple Gas
# Flow formulations by providing an abstraction layer between the network data
# and network constraint definitions.  The constraint template's job is to
# extract the required parameters from a given network data structure and
# pass the data as named arguments to the Gas Flow formulations.
#
# Constraint templates should always be defined over "GenericGasModel"
# and should never refer to model variables

#################################################################################################
# Templates for constraints associated with pipes
#################################################################################################

" Template: Constraint on mass flow across a pipe"
function constraint_pipe_mass_flow(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm,n,:connection,k)
    w              = ref(gm,n,:w)[k]
    f_min          = calc_pipe_fmin(gm, n, k, w)
    f_max          = calc_pipe_fmax(gm, n, k, w)
    constraint_pipe_mass_flow(gm, n, k, f_min, f_max)
end
constraint_pipe_mass_flow(gm::GenericGasModel, k::Int) = constraint_pipe_mass_flow(gm, gm.cnw, k)

" Template: Constraint on flow across a pipe where the flow is constrained to one direction as defined by data attribute directed"
function constraint_pipe_mass_flow_directed(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm,n,:connection,k)
    direction      = pipe["directed"]
    w              = ref(gm,n,:w)[k]
    f_min          = (direction == 1) ? 0 : calc_pipe_fmin(gm, n, k, w)
    f_max          = (direction == 1) ? calc_pipe_fmax(gm, n, k, w) : 0
    constraint_pipe_mass_flow_directed(gm, n, k, f_min, f_max)
end
constraint_pipe_mass_flow_directed(gm::GenericGasModel, k::Int) = constraint_pipe_mass_flow_directed(gm, gm.cnw, k)

"Template: Pressure drop across pipes with on/off direction variables"
function constraint_pipe_pressure(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_max         = ref(gm,n,:pd_max)[k]
    pd_min         = ref(gm,n,:pd_min)[k]
    constraint_pipe_pressure(gm, n, k, i, j, pd_min, pd_max)
end
constraint_pipe_pressure(gm::GenericGasModel, k::Int) = constraint_pipe_pressure(gm, gm.cnw, k)

" Template: Constraint on pressure drop across a pipe where the flow is constrained to one direction as defined by data attribute directed"
function constraint_pipe_pressure_directed(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    direction      = pipe["directed"]
    pd_max         = (direction == 1) ? ref(gm,n,:pd_max)[k] : min(0, ref(gm,n,:pd_max)[k])
    pd_min         = (direction == 1) ? max(0, ref(gm,n,:pd_min)[k]) : ref(gm,n,:pd_min)[k]
    constraint_pipe_pressure_directed(gm, n, k, i, j, pd_min, pd_max)
end
constraint_pipe_pressure_directed(gm::GenericGasModel, k::Int) = constraint_pipe_pressure_directed(gm, gm.cnw, k)

"Template: Constraints on flow across an expansion pipe with on/off direction variables "
function constraint_pipe_mass_flow_ne(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm,n,:ne_connection, k)
    mf             = ref(gm,n,:max_mass_flow)
    pd_max         = ref(gm,n,:pd_max_ne)[k]
    pd_min         = ref(gm,n,:pd_min_ne)[k]
    w              = ref(gm,n,:w_ne)[k]
    f_min          = -min(mf, sqrt(w*max(abs(pd_max), abs(pd_min))))
    f_max          = min(mf, sqrt(w*max(abs(pd_max), abs(pd_min))))
    constraint_pipe_mass_flow_ne(gm, n, k, f_min, f_max)
end
constraint_pipe_mass_flow_ne(gm::GenericGasModel, k::Int) = constraint_pipe_mass_flow_ne(gm, gm.cnw, k)

"Template: Constraints on pressure drop across pipes"
function constraint_pipe_pressure_ne(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm, n, :ne_connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    pd_max         = ref(gm,n,:pd_max_ne)[k]
    pd_min         = ref(gm,n,:pd_min_ne)[k]
    constraint_pipe_pressure_ne(gm, n, k, i, j, pd_min, pd_max)
end
constraint_pipe_pressure_ne(gm::GenericGasModel, k::Int) = constraint_pipe_pressure_ne(gm, gm.cnw, k)

" Template: Constraint on pressure drop across an expansion pipe where the flow is constrained to one direction as defined by data attribute directed"
function constraint_pressure_ne_directed(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm, n, :ne_connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    direction      = pipe["directed"]
    pd_max         = ref(gm,n,:pd_max_ne)[k]
    pd_min         = ref(gm,n,:pd_min_ne)[k]
    constraint_pressure_ne_directed(gm, n, k, i, j, pd_min, pd_max, direction)
end
constraint_pressure_ne_directed(gm::GenericGasModel, k::Int) = constraint_pressure_ne_directed(gm, gm.cnw, k)

"Template: Constraints on flow across an expansion pipe where the flow is constrained to one direction "
function constraint_pipe_mass_flow_ne_directed(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm,n,:ne_connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    direction      = pipe["directed"]
    w              = ref(gm,n,:w_ne)[k]
    f_min          = (direction == 1) ? 0 : calc_pipe_ne_fmin(gm, n, k, w)
    f_max          = (direction == 1) ? calc_pipe_ne_fmax(gm, n, k, w) : 0
    constraint_pipe_mass_flow_ne_directed(gm, n, k, f_min, f_max)
end
constraint_pipe_mass_flow_ne_directed(gm::GenericGasModel, k::Int) = constraint_pipe_mass_flow_ne_directed(gm, gm.cnw, k)

"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe "
function constraint_weymouth(gm::GenericGasModel, n::Int, k)
    pipe    = ref(gm,n,:connection,k)
    i       = pipe["f_junction"]
    j       = pipe["t_junction"]
    mf      = gm.ref[:nw][n][:max_mass_flow]
    w       = ref(gm,n,:w)[k]
    pd_max  = ref(gm,n,:pd_max)[k]
    pd_min  = ref(gm,n,:pd_min)[k]
    f_min   = calc_pipe_fmin(gm, n, k, w)
    f_max   = calc_pipe_fmax(gm, n, k, w)
    constraint_weymouth(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max)
end
constraint_weymouth(gm::GenericGasModel, k::Int) = constraint_weymouth(gm, gm.cnw, k)

"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe where flow is constrained in one direction"
function constraint_weymouth_directed(gm::GenericGasModel, n::Int, k)
    pipe      = ref(gm,n,:connection,k)
    i         = pipe["f_junction"]
    j         = pipe["t_junction"]
    w         = ref(gm, n, :w)[k]
    direction = pipe["directed"]
    constraint_weymouth_directed(gm, n, k, i, j, w, direction)
end
constraint_weymouth_directed(gm::GenericGasModel, k::Int) = constraint_weymouth_directed(gm, gm.cnw, k)

"Template: Constraint associatd with turning off flow depending on the status of expansion pipes"
function constraint_pipe_ne(gm::GenericGasModel, n::Int, k)
    pipe   = gm.ref[:nw][n][:ne_connection][k]
    w      = ref(gm,n,:w_ne)[k]
    f_min  = calc_pipe_ne_fmin(gm, n, k, w)
    f_max  = calc_pipe_ne_fmax(gm, n, k, w)
    constraint_pipe_ne(gm, n, k, w, f_min, f_max)
end
constraint_pipe_ne(gm::GenericGasModel, k::Int) = constraint_pipe_ne(gm, gm.cnw, k)

" Template: Weymouth equation for expansion pipes "
function constraint_weymouth_ne(gm::GenericGasModel,  n::Int, k)
    pipe           = gm.ref[:nw][n][:ne_connection][k]
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    mf             = gm.ref[:nw][n][:max_mass_flow]
    w              = ref(gm,n,:w_ne)[k]
    pd_max         = ref(gm,n,:pd_max_ne)[k]
    pd_min         = ref(gm,n,:pd_min_ne)[k]
    f_min          = calc_pipe_ne_fmin(gm, n, k, w)
    f_max          = calc_pipe_ne_fmax(gm, n, k, w)
    constraint_weymouth_ne(gm, n, k, i, j, w, f_min, f_max, pd_min, pd_max)
end
constraint_weymouth_ne(gm::GenericGasModel, k::Int) = constraint_weymouth_ne(gm, gm.cnw, k)

" Template: Weymouth equation for expansion pipes where flow is restricted to one direction "
function constraint_weymouth_ne_directed(gm::GenericGasModel,  n::Int, k)
    pipe           = gm.ref[:nw][n][:ne_connection][k]
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    mf             = gm.ref[:nw][n][:max_mass_flow]
    w              = ref(gm,n,:w_ne)[k]
    direction      = pipe["directed"]
    pd_max         = ref(gm,n,:pd_max_ne)[k]
    pd_min         = ref(gm,n,:pd_min_ne)[k]
    constraint_weymouth_ne_directed(gm, n, k, i, j, w, pd_min, pd_max, direction)
end
constraint_weymouth_ne_directed(gm::GenericGasModel, k::Int) = constraint_weymouth_ne_directed(gm, gm.cnw, k)

#################################################################################################
# Templates for constraints associated with junctions
#################################################################################################

" Template: Constraints for mass flow balance equation where demand and production are constants"
function constraint_mass_flow_balance(gm::GenericGasModel, n::Int, i)
    junction   = ref(gm,n,:junction,i)
    consumer   = ref(gm,n,:consumer)
    producer   = ref(gm,n,:producer)
    consumers  = ref(gm,n,:junction_consumers,i)
    producers  = ref(gm,n,:junction_producers,i)
    f_branches = ref(gm,n,:f_connections,i)
    t_branches = ref(gm,n,:t_connections,i)

    fg         = length(producers) > 0 ? sum(calc_fg(gm.data,producer[j]) for j in producers) : 0
    fl         = length(consumers) > 0 ? sum(calc_fl(gm.data,consumer[j]) for j in consumers) : 0
    constraint_mass_flow_balance(gm, n, i, f_branches, t_branches, fg, fl)
end
constraint_mass_flow_balance(gm::GenericGasModel, i::Int) = constraint_mass_flow_balance(gm, gm.cnw, i)

" Template: Constraints for mass flow balance equation where demand and production are constants and there are expansion connections "
function constraint_mass_flow_balance_ne(gm::GenericGasModel, n::Int, i)
    junction      = ref(gm,n,:junction,i)
    consumer      = ref(gm,n,:consumer)
    producer      = ref(gm,n,:producer)
    consumers     = ref(gm,n,:junction_consumers,i)
    producers     = ref(gm,n,:junction_producers,i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

    fg         = length(producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in producers) : 0
    fl         = length(consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in consumers) : 0

    constraint_mass_flow_balance_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fg, fl)
end
constraint_mass_flow_balance_ne(gm::GenericGasModel, i::Int) = constraint_mass_flow_balance_ne(gm, gm.cnw, i)

" Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_mass_flow_balance_ls(gm::GenericGasModel, n::Int, i)
    junction                = ref(gm,n,:junction,i)
    f_branches              = ref(gm,n,:f_connections,i)
    t_branches              = ref(gm,n,:t_connections,i)
    consumer                = ref(gm,n,:consumer)
    producer                = ref(gm,n,:producer)
    consumers               = ref(gm,n,:junction_consumers,i)
    producers               = ref(gm,n,:junction_producers,i)
    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg       = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl        = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0
    fgmax     = length(dispatch_producers) > 0 ? sum(calc_fgmax(gm.data, producer[j]) for j in dispatch_producers) : 0
    flmax     = length(dispatch_consumers) > 0 ? sum(calc_flmax(gm.data, consumer[j]) for j in dispatch_consumers) : 0
    fgmin     = length(dispatch_producers) > 0 ? sum(calc_fgmin(gm.data, producer[j]) for j in dispatch_producers) : 0
    flmin     = length(dispatch_consumers) > 0 ? sum(calc_flmin(gm.data, consumer[j]) for j in dispatch_consumers) : 0

    constraint_mass_flow_balance_ls(gm, n, i, f_branches, t_branches, fl, fg, dispatch_consumers, dispatch_producers, flmin, flmax, fgmin, fgmax)
end
constraint_mass_flow_balance_ls(gm::GenericGasModel, i::Int) = constraint_mass_flow_balance_ls(gm, gm.cnw, i)

" Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables and there are expansion connections"
function constraint_mass_flow_balance_ne_ls(gm::GenericGasModel, n::Int, i)
    junction      = ref(gm,n,:junction,i)
    consumer      = ref(gm,n,:consumer)
    producer      = ref(gm,n,:producer)
    consumers     = ref(gm,n,:junction_consumers,i)
    producers     = ref(gm,n,:junction_producers,i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    f_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["f_junction"] == i)))
    t_branches_ne = collect(keys(Dict(x for x in gm.ref[:nw][n][:ne_connection] if x.second["t_junction"] == i)))

    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg        = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl        = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0
    fgmax     = length(dispatch_producers) > 0 ? sum(calc_fgmax(gm.data, producer[j])  for  j in dispatch_producers)  : 0
    flmax     = length(dispatch_consumers) > 0 ? sum(calc_flmax(gm.data, consumer[j])  for  j in dispatch_consumers)  : 0
    fgmin     = length(dispatch_producers) > 0 ? sum(calc_fgmin(gm.data, producer[j])  for  j in dispatch_producers)  : 0
    flmin     = length(dispatch_consumers) > 0 ? sum(calc_flmin(gm.data, consumer[j])  for  j in dispatch_consumers)  : 0

    constraint_mass_flow_balance_ne_ls(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fl, fg, dispatch_consumers, dispatch_producers, flmin, flmax, fgmin, fgmax)
end
constraint_mass_flow_balance_ne_ls(gm::GenericGasModel, i::Int) = constraint_mass_flow_balance_ne_ls(gm, gm.cnw, i)

#################################################################################################
# Templates for constraints associated with short pipes
#################################################################################################

" Template: Constraint on pressure drop across a short pipe "
function constraint_short_pipe_pressure(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm,n,:connection,k)
    i    = pipe["f_junction"]
    j    = pipe["t_junction"]
    constraint_short_pipe_pressure(gm, n, k, i, j)
end
constraint_short_pipe_pressure(gm::GenericGasModel, k::Int) = constraint_short_pipe_pressure(gm, gm.cnw, k)

"Constraint: constraints on flow across a short pipe"
function constraint_short_pipe_mass_flow(gm::GenericGasModel, n::Int, k)
    pipe    = ref(gm,n,:connection,k)
    mf      = ref(gm,n,:max_mass_flow)
    f_min   = -mf
    f_max   = mf
    constraint_short_pipe_mass_flow(gm, n, k, f_min, f_max)
end
constraint_short_pipe_mass_flow(gm::GenericGasModel, k::Int) = constraint_short_pipe_mass_flow(gm, gm.cnw, k)

" Template: Constraint on flow across a short pipe when the flow direction is constrained in one direction"
function constraint_short_pipe_mass_flow_directed(gm::GenericGasModel, n::Int, k)
    pipe      = ref(gm,n,:connection,k)
    i         = pipe["f_junction"]
    j         = pipe["t_junction"]
    direction = pipe["directed"]
    mf        = ref(gm,n,:max_mass_flow)
    f_min     = (direction == 1) ? 0 : -mf
    f_max     = (direction == 1) ? mf : 0

    constraint_short_pipe_mass_flow_directed(gm, n, k, f_min, f_max)
end
constraint_short_pipe_mass_flow_directed(gm::GenericGasModel, k::Int) = constraint_short_pipe_mass_flow_directed(gm, gm.cnw, k)

#################################################################################################
# Templates for constraints associated with valves
#################################################################################################

" Template: Constraint on pressure drop across valves, where the valve may be closed or opened "
function constraint_on_off_valve_pressure(gm::GenericGasModel, n::Int, k)
    valve  = ref(gm,n,:connection,k)
    i      = valve["f_junction"]
    j      = valve["t_junction"]
    j_pmax = gm.ref[:nw][n][:junction][j]["pmax"]
    i_pmax = gm.ref[:nw][n][:junction][i]["pmax"]
    constraint_on_off_valve_pressure(gm, n, k, i, j, i_pmax, j_pmax)
end
constraint_on_off_valve_pressure(gm::GenericGasModel, k::Int) = constraint_on_off_valve_pressure(gm, gm.cnw, k)

"Template: constraints on flow across valves modeled with on/off direction variables "
function constraint_on_off_valve_mass_flow(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    mf    = ref(gm,n,:max_mass_flow)
    f_min = -mf
    f_max = mf
    constraint_on_off_valve_mass_flow(gm, n, k, f_min, f_max)
end
constraint_on_off_valve_mass_flow(gm::GenericGasModel, k::Int) = constraint_on_off_valve_mass_flow(gm, gm.cnw, k)

" Template: Constraints on flow across a valve when flow is restricted in one direction and the valve may be turned on or off"
function constraint_on_off_valve_mass_flow_directed(gm::GenericGasModel, n::Int, k)
    valve     = ref(gm,n,:connection,k)
    mf        = ref(gm,n,:max_mass_flow)
    direction = valve["directed"]
    f_min     = (direction == 1) ? 0 : -mf
    f_max     = (direction == 1) ? mf : 0
    constraint_on_off_valve_mass_flow_directed(gm, n, k, f_min, f_max)
end
constraint_on_off_valve_mass_flow_directed(gm::GenericGasModel, k::Int) = constraint_on_off_valve_mass_flow_directed(gm, gm.cnw, k)

#################################################################################################
# Templates for constraints associated with compressors
#################################################################################################

"Template: Compression ratios for a compressor "
function constraint_compressor_ratios(gm::GenericGasModel, n::Int, k)
    compressor     = ref(gm,n,:connection,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    constraint_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax)
end
constraint_compressor_ratios(gm::GenericGasModel, k::Int) = constraint_compressor_ratios(gm, gm.cnw, k)

" Template: Constraint for turning on or off flow through expansion compressor "
function constraint_compressor_ne(gm::GenericGasModel,  n::Int, k)
    compressor = gm.ref[:nw][n][:ne_connection][k]
    mf         = gm.ref[:nw][n][:max_mass_flow]
    f_min      = -mf
    f_max      = mf
    constraint_compressor_ne(gm, n, k, f_min, f_max)
end
constraint_compressor_ne(gm::GenericGasModel, k::Int) = constraint_compressor_ne(gm, gm.cnw, k::Int)

" Template: Constraints on compressor ratios when flow is restricted to one direction"
function constraint_compressor_ratios_directed(gm::GenericGasModel, n::Int, k)
    compressor     = ref(gm,n,:connection,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    direction      = compressor["directed"]
    constraint_compressor_ratios_directed(gm, n, k, i, j, min_ratio, max_ratio, direction)
end
constraint_compressor_ratios_directed(gm::GenericGasModel, k::Int) = constraint_compressor_ratios_directed(gm, gm.cnw, k)

"Template: constraints on flow across a compressor"
function constraint_compressor_mass_flow(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm, n, :connection, k)
    mf         = ref(gm,n,:max_mass_flow)
    f_min      = -mf
    f_max      = mf
    constraint_compressor_mass_flow(gm, n, k, f_min, f_max)
end
constraint_compressor_mass_flow(gm::GenericGasModel, k::Int) = constraint_compressor_mass_flow(gm, gm.cnw, k)

"Template: constraints on flow across compressors where direction "
function constraint_compressor_mass_flow_ne(gm::GenericGasModel, n::Int, k)
    compressor     = ref(gm,n,:ne_connection,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    mf             = ref(gm,n,:max_mass_flow)
    f_min          = -mf
    f_max          = mf
    constraint_compressor_mass_flow_ne(gm, n, k, f_min, f_max)
end
constraint_compressor_mass_flow_ne(gm::GenericGasModel, i::Int) = constraint_compressor_mass_flow_ne(gm, gm.cnw, i)

" Template: Constraints on flow across a compressor when flow is restricted to one direction"
function constraint_compressor_mass_flow_directed(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm, n, :connection, k)
    i          = compressor["f_junction"]
    j          = compressor["t_junction"]
    direction  = compressor["directed"]
    mf         = ref(gm,n,:max_mass_flow)
    f_min      = (direction == 1) ? 0 : -mf
    f_max      = (direction == 1) ? mf : 0
    constraint_compressor_mass_flow_directed(gm, n, k, f_min, f_max)
end
constraint_compressor_mass_flow_directed(gm::GenericGasModel, k::Int) = constraint_compressor_mass_flow_directed(gm, gm.cnw, k)

"Template: constraints on pressure drop across a compressor "
function constraint_compressor_ratios_ne(gm::GenericGasModel, n::Int, k)
    compressor     = ref(gm,n,:ne_connection, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmin         = ref(gm,n,:junction,i)["pmin"]
    mf             = ref(gm,n,:max_mass_flow)
    f_max          = mf
    constraint_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmax)
end
constraint_compressor_ratios_ne(gm::GenericGasModel, k::Int) = constraint_compressor_ratios_ne(gm, gm.cnw, k)

" Template: Constraints on compressor ratios when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_ratios_ne_directed(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm,n,:ne_connection, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmin         = ref(gm,n,:junction,i)["pmin"]
    mf             = gm.ref[:nw][n][:max_mass_flow]
    direction      = compressor["directed"]
    constraint_compressor_ratios_ne_directed(gm, n, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, direction)
end
constraint_compressor_ratios_ne_directed(gm::GenericGasModel, k::Int) = constraint_compressor_ratios_ne_directed(gm, gm.cnw, k)

" Template: Constraints on compressor flows when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_mass_flow_ne_directed(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm,n,:ne_connection,k)
    i          = compressor["f_junction"]
    j          = compressor["t_junction"]
    mf         = ref(gm,n,:max_mass_flow)
    direction  = compressor["directed"]
    f_min     = (direction == 1) ? 0 : -mf
    f_max     = (direction == 1) ? mf : 0
    constraint_compressor_mass_flow_ne_directed(gm, n, k, f_min, f_max)
end
constraint_compressor_mass_flow_ne_directed(gm::GenericGasModel, i::Int) = constraint_compressor_mass_flow_ne_directed(gm, gm.cnw, i)

#################################################################################################
# Templates for control valves
#################################################################################################

"Template: constraints on flow across control valves with on/off direction variables "
function constraint_on_off_control_valve_mass_flow(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    mf    = ref(gm,n,:max_mass_flow)
    f_min = -mf
    f_max = mf
    constraint_on_off_control_valve_mass_flow(gm, n, k, f_min, f_max)
end
constraint_on_off_control_valve_mass_flow(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_mass_flow(gm, gm.cnw, k)

" Template: Constraints on control valve flows when flow is restricted to one direction"
function constraint_on_off_control_valve_mass_flow_directed(gm::GenericGasModel, n::Int, k)
    valve      = ref(gm,n,:connection,k)
    i          = valve["f_junction"]
    j          = valve["t_junction"]
    mf         = ref(gm,n,:max_mass_flow)
    direction  = valve["directed"]
    f_min = (direction == 1) ? 0 : -mf
    f_max = (direction == 1) ? mf : 0
    constraint_on_off_control_valve_mass_flow_directed(gm, n, k, f_min, f_max)
end
constraint_control_valve_on_off_mass_flow_directed(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_mass_flow_directed(gm, gm.cnw, k)

"Constraint Enforces pressure changes bounds that obey decompression ratios for "
function constraint_on_off_control_valve_pressure(gm::GenericGasModel, n::Int, k)
    control_valve = ref(gm,n,:control_valve,k)
    i             = control_valve["f_junction"]
    j             = control_valve["t_junction"]
    max_ratio     = control_valve["c_ratio_max"]
    min_ratio     = control_valve["c_ratio_min"]
    j_pmax        = ref(gm,n,:junction,j)["pmax"]
    i_pmax        = ref(gm,n,:junction,i)["pmax"]
    i_pmin        = ref(gm,n,:junction,i)["pmin"]
    mf            = ref(gm,n,:max_mass_flow)
    f_max         = mf

    constraint_on_off_control_valve_pressure(gm, n, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmax)
end
constraint_on_off_control_valve_pressure(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_pressure(gm, gm.cnw, k)

" Template: Constraints on control valve pressure when flow is restricted to one direction"
function constraint_on_off_control_valve_pressure_directed(gm::GenericGasModel, n::Int, k)
    valve     = ref(gm,n,:connection,k)
    i         = valve["f_junction"]
    j         = valve["t_junction"]
    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]
    j_pmax    = ref(gm,n,:junction,j)["pmax"]
    i_pmax    = ref(gm,n,:junction,i)["pmax"]
    direction = valve["direction"]
    constraint_on_off_control_valve_pressure_directed(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, direction)
end
constraint_on_off_control_valve_pressure_directed(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_pressure_directed(gm, gm.cnw, k)

#################################################################################################
# Templates for misc constraints
#################################################################################################

" Template: Constraint which restricts selction of expansion pipes that are in paralell to a single one "
function constraint_exclusive_new_pipes(gm::GenericGasModel,  n::Int, i, j)
    parallel = ref(gm,n,:parallel_ne_pipes, (i,j))
    constraint_exclusive_new_pipes(gm, n, i, j, parallel)
end
constraint_exclusive_new_pipes(gm::GenericGasModel, i::Int, j::Int) = constraint_exclusive_new_pipes(gm, gm.cnw, i, j)
