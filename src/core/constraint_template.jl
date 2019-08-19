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
function constraint_pipe_mass_flow(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe           = ref(gm,n,:connection,k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    mf             = ref(gm,n,:max_mass_flow)
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    w              = haskey(ref(gm,n,:pipe),k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    constraint_pipe_mass_flow(gm, n, k, i, j, mf, pd_min, pd_max, w)
end
constraint_pipe_mass_flow(gm::GenericGasModel, k::Int) = constraint_pipe_mass_flow(gm, gm.cnw, k)

" Template: Constraint on pressure drop across a pipe where the flow is constrained to one direction as defined by data attributes yp and yn"
function constraint_pressure_drop_one_way(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm, n, :connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]
    constraint_pressure_drop_one_way(gm, n, k, i, j, yp, yn)
end
constraint_pressure_drop_one_way(gm::GenericGasModel, k::Int) = constraint_pressure_drop_one_way(gm, gm.cnw, k)

" Template: Constraint on flow across a pipe where the flow is constrained to one direction as defined by data attributes yp and yn"
function constraint_pipe_flow_one_way(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe           = ref(gm,n,:connection,k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]
    constraint_pipe_flow_one_way(gm, n, k, i, j, yp, yn)
end
constraint_pipe_flow_one_way(gm::GenericGasModel, k::Int) = constraint_pipe_flow_one_way(gm, gm.cnw, k)

" Template: Constraint on pressure drop across an expansion pipe where the flow is constrained to one direction as defined by data attributes yp and yn"
function constraint_pressure_drop_ne_one_way(gm::GenericGasModel, n::Int, k)
    pipe           = ref(gm, n, :ne_connection, k)
    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]
    constraint_pressure_drop_ne_one_way(gm, n, k, i, j, yp, yn)
end
constraint_pressure_drop_ne_one_way(gm::GenericGasModel, k::Int) = constraint_pressure_drop_ne_one_way(gm, gm.cnw, k)

"Template: Constraints on flow across an expansion pipe where the flow is constrained to one direction "
function constraint_pipe_flow_ne_one_way(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:ne_connection, k)

    i              = pipe["f_junction"]
    j              = pipe["t_junction"]
    yp             = pipe["yp"]
    yn             = pipe["yn"]

    constraint_pipe_flow_ne_one_way(gm, n, k, i, j, yp, yn)
end
constraint_pipe_flow_ne_one_way(gm::GenericGasModel, k::Int) = constraint_pipe_flow_ne_one_way(gm, gm.cnw, k)

"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe "
function constraint_weymouth(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe   = ref(gm,n,:connection,k)
    i      = pipe["f_junction"]
    j      = pipe["t_junction"]
    mf     = gm.ref[:nw][n][:max_mass_flow]
    w      = haskey(gm.ref[:nw][n][:pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    constraint_weymouth(gm, n, k, i, j, mf, w, pd_min, pd_max)
end
constraint_weymouth(gm::GenericGasModel, k::Int) = constraint_weymouth(gm, gm.cnw, k)

"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe where flow is constrained in one direction"
function constraint_weymouth_one_way(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = ref(gm,n,:connection,k)
    i    = pipe["f_junction"]
    j    = pipe["t_junction"]
    w    = haskey(gm.ref[:nw][n][:pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    yp   = pipe["yp"]
    yn   = pipe["yn"]
    constraint_weymouth_one_way(gm, n, k, i, j, w, yp, yn)
end
constraint_weymouth_one_way(gm::GenericGasModel, k::Int) = constraint_weymouth_one_way(gm, gm.cnw, k)

"Template: Constraint associatd with turning off flow depending on the status of expansion pipes"
function constraint_pipe_ne(gm::GenericGasModel, n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe   = gm.ref[:nw][n][:ne_connection][k]
    mf     = gm.ref[:nw][n][:max_mass_flow]
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    w      = haskey(gm.ref[:nw][n][:ne_pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    constraint_pipe_ne(gm, n, k, w, mf, pd_min, pd_max)
end
constraint_pipe_ne(gm::GenericGasModel, k::Int) = constraint_pipe_ne(gm, gm.cnw, k)

" Template: Weymouth equation for expansion pipes "
function constraint_weymouth_ne(gm::GenericGasModel,  n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe   = gm.ref[:nw][n][:ne_connection][k]
    i      = pipe["f_junction"]
    j      = pipe["t_junction"]
    mf     = gm.ref[:nw][n][:max_mass_flow]
    w      = haskey(gm.ref[:nw][n][:ne_pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    pd_max = pipe["pd_max"]
    pd_min = pipe["pd_min"]
    constraint_weymouth_ne(gm, n, k, i, j, w, mf, pd_min, pd_max)
end
constraint_weymouth_ne(gm::GenericGasModel, k::Int) = constraint_weymouth_ne(gm, gm.cnw, k)

" Template: Weymouth equation for expansion pipes where flow is restricted to one direction "
function constraint_weymouth_ne_one_way(gm::GenericGasModel,  n::Int, k; pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple)
    pipe = gm.ref[:nw][n][:ne_connection][k]
    i    = pipe["f_junction"]
    j    = pipe["t_junction"]
    mf   = gm.ref[:nw][n][:max_mass_flow]
    w    = haskey(gm.ref[:nw][n][:ne_pipe],k) ? pipe_resistance(gm.data, pipe) : resistor_resistance(gm.data, pipe)
    yp   = pipe["yp"]
    yn   = pipe["yn"]
    constraint_weymouth_ne_one_way(gm, n, k, i, j, w, mf, yp, yn)
end
constraint_weymouth_ne_one_way(gm::GenericGasModel, k::Int) = constraint_weymouth_ne_one_way(gm, gm.cnw, k)

#################################################################################################
# Templates for constraints associated with junctions
#################################################################################################

" Template: Constraints for mass flow balance equation where demand and production are constants "
function constraint_junction_mass_flow_balance(gm::GenericGasModel, n::Int, i)
    junction   = ref(gm,n,:junction,i)
    consumer   = ref(gm,n,:consumer)
    producer   = ref(gm,n,:producer)
    consumers  = ref(gm,n,:junction_consumers,i)
    producers  = ref(gm,n,:junction_producers,i)
    f_branches = ref(gm,n,:f_connections,i)
    t_branches = ref(gm,n,:t_connections,i)

    fg         = length(producers) > 0 ? sum(calc_fg(gm.data,producer[j]) for j in producers) : 0
    fl         = length(consumers) > 0 ? sum(calc_fl(gm.data,consumer[j]) for j in consumers) : 0
    constraint_junction_mass_flow_balance(gm, n, i, f_branches, t_branches, fg, fl)
end
constraint_junction_mass_flow_balance(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance(gm, gm.cnw, i)

" Template: Constraints for mass flow balance equation where demand and production are constants and there are expansion connections "
function constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, n::Int, i)
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

    constraint_junction_mass_flow_balance_ne(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fg, fl)
end
constraint_junction_mass_flow_balance_ne(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ne(gm, gm.cnw, i)

" Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, n::Int, i)
    junction      = ref(gm,n,:junction,i)
    f_branches    = ref(gm,n,:f_connections,i)
    t_branches    = ref(gm,n,:t_connections,i)
    consumer      = ref(gm,n,:consumer)
    producer      = ref(gm,n,:producer)
    consumers     = ref(gm,n,:junction_consumers,i)
    producers     = ref(gm,n,:junction_producers,i)
    dispatch_producers      = ref(gm,n,:junction_dispatchable_producers,i)
    nondispatch_producers   = ref(gm,n,:junction_nondispatchable_producers,i)
    dispatch_consumers      = ref(gm,n,:junction_dispatchable_consumers,i)
    nondispatch_consumers   = ref(gm,n,:junction_nondispatchable_consumers,i)

    fg = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0

    constraint_junction_mass_flow_balance_ls(gm, n, i, f_branches, t_branches, fl, fg, dispatch_consumers, dispatch_producers)
end
constraint_junction_mass_flow_balance_ls(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ls(gm, gm.cnw, i)

" Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables and there are expansion connections"
function constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, n::Int, i)
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

    fg  = length(nondispatch_producers) > 0 ? sum(calc_fg(gm.data, producer[j]) for j in nondispatch_producers) : 0
    fl  = length(nondispatch_consumers) > 0 ? sum(calc_fl(gm.data, consumer[j]) for j in nondispatch_consumers) : 0

    constraint_junction_mass_flow_balance_ne_ls(gm, n, i, f_branches, t_branches, f_branches_ne, t_branches_ne, fl, fg, dispatch_consumers, dispatch_producers)
end
constraint_junction_mass_flow_balance_ne_ls(gm::GenericGasModel, i::Int) = constraint_junction_mass_flow_balance_ne_ls(gm, gm.cnw, i)


#################################################################################################
# Templates for constraints associated with short pipes
#################################################################################################

" Template: Constraint on pressure drop across a short pipe "
function constraint_short_pipe_pressure_drop(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm,n,:connection,k)
    i    = pipe["f_junction"]
    j    = pipe["t_junction"]
    constraint_short_pipe_pressure_drop(gm, n, k, i, j)
end
constraint_short_pipe_pressure_drop(gm::GenericGasModel, k::Int) = constraint_short_pipe_pressure_drop(gm, gm.cnw, k)

" Template: Constraint on flow across a short pipe when the flow direction is constrained in one direction"
function constraint_short_pipe_flow_one_way(gm::GenericGasModel, n::Int, k)
    pipe = ref(gm,n,:connection,k)
    i    = pipe["f_junction"]
    j    = pipe["t_junction"]
    yp   = pipe["yp"]
    yn   = pipe["yn"]
    constraint_short_pipe_flow_one_way(gm, n, k, i, j, yp, yn)
end
constraint_short_pipe_flow_one_way(gm::GenericGasModel, k::Int) = constraint_short_pipe_flow_one_way(gm, gm.cnw, k)

#################################################################################################
# Templates for constraints associated with valves
#################################################################################################

" Template: Constraint on pressure drop across valves, where the valve may be closed or opened "
function constraint_valve_pressure_drop(gm::GenericGasModel, n::Int, k)
    valve  = ref(gm,n,:connection,k)
    i      = valve["f_junction"]
    j      = valve["t_junction"]
    j_pmax = gm.ref[:nw][n][:junction][j]["pmax"]
    i_pmax = gm.ref[:nw][n][:junction][i]["pmax"]
    constraint_valve_pressure_drop(gm, n, k, i, j, i_pmax, j_pmax)
end
constraint_valve_pressure_drop(gm::GenericGasModel, k::Int) = constraint_valve_pressure_drop(gm, gm.cnw, k)

"Template: constraints on flow across valves modeled with on/off direction variables "
function constraint_on_off_valve_flow(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    i     = valve["f_junction"]
    j     = valve["t_junction"]
    mf    = ref(gm,n,:max_mass_flow)

    constraint_on_off_valve_flow(gm, n, k, i, j, mf)
end
constraint_on_off_valve_flow(gm::GenericGasModel, k::Int) = constraint_on_off_valve_flow(gm, gm.cnw, k)

" Template: Constraints on flow across a valve when flow is restricted in one direction and the valve may be turned on or off"
function constraint_valve_flow_one_way(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    i     = valve["f_junction"]
    j     = valve["t_junction"]
    mf    = ref(gm,n,:max_mass_flow)
    yp    = valve["yp"]
    yn    = valve["yn"]
    constraint_valve_flow_one_way(gm, n, k, i, j, mf, yp, yn)
end
constraint_valve_flow_one_way(gm::GenericGasModel, k::Int) = constraint_valve_flow_one_way(gm, gm.cnw, k)

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

    constraint_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio)
end
constraint_compressor_ratios(gm::GenericGasModel, k::Int) = constraint_compressor_ratios(gm, gm.cnw, k)

" Template: Constraint for turning on or off flow through expansion compressor "
function constraint_compressor_ne(gm::GenericGasModel,  n::Int, k)
    compressor = gm.ref[:nw][n][:ne_connection][k]
    mf         = gm.ref[:nw][n][:max_mass_flow]
    constraint_compressor_ne(gm, n, k, mf)
end
constraint_compressor_ne(gm::GenericGasModel, k::Int) = constraint_compressor_ne(gm, gm.cnw, k::Int)

" Template: Constraints on compressor ratios when flow is restricted to one direction"
function constraint_compressor_ratios_one_way(gm::GenericGasModel, n::Int, k)
    compressor     = ref(gm,n,:connection,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    yp             = compressor["yp"]
    yn             = compressor["yn"]
    constraint_compressor_ratios_one_way(gm, n, k, i, j, min_ratio, max_ratio, yp, yn)
end
constraint_compressor_ratios_one_way(gm::GenericGasModel, k::Int) = constraint_compressor_ratios_one_way(gm, gm.cnw, k)

" Template: Constraints on flow across a compressor when flow is restricted to one direction"
function constraint_compressor_flow_one_way(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm, n, :connection, k)

    i        = compressor["f_junction"]
    j        = compressor["t_junction"]
    yp       = compressor["yp"]
    yn       = compressor["yn"]

    constraint_compressor_flow_one_way(gm, n, k, i, j, yp, yn)
end
constraint_compressor_flow_one_way(gm::GenericGasModel, k::Int) = constraint_compressor_flow_one_way(gm, gm.cnw, k)

"Template: constraints on pressure drop across a compressor "
function constraint_compressor_ratios_ne(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm,n,:ne_connection, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmin         = ref(gm,n,:junction,i)["pmin"]
    mf       = ref(gm,n,:max_mass_flow)

    constraint_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax)
end
constraint_compressor_ratios_ne(gm::GenericGasModel, k::Int) = constraint_compressor_ratios_ne(gm, gm.cnw, k)

" Template: Constraints on compressor ratios when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_ratios_ne_one_way(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm,n,:ne_connection, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmin         = ref(gm,n,:junction,i)["pmin"]
    mf             = gm.ref[:nw][n][:max_mass_flow]
    yp             = compressor["yp"]
    yn             = compressor["yn"]
    constraint_compressor_ratios_ne_one_way(gm, n, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, yp, yn)
end
constraint_compressor_ratios_ne_one_way(gm::GenericGasModel, k::Int) = constraint_compressor_ratios_ne_one_way(gm, gm.cnw, k)

" Template: Constraints on compressor flows when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_flow_ne_one_way(gm::GenericGasModel, n::Int, k)
    compressor = ref(gm,n,:ne_connection,k)
    i          = compressor["f_junction"]
    j          = compressor["t_junction"]
    mf         = ref(gm,n,:max_mass_flow)
    yp         = compressor["yp"]
    yn         = compressor["yn"]
    constraint_compressor_flow_ne_one_way(gm, n, k, i, j, mf, yp, yn)
end
constraint_compressor_flow_ne_one_way(gm::GenericGasModel, i::Int) = constraint_one_way_compressor_flow_ne(gm, gm.cnw, i)

#################################################################################################
# Templates for control valves
#################################################################################################

"Template: constraints on flow across control valves with on/off direction variables "
function constraint_on_off_control_valve_flow(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    i     = valve["f_junction"]
    j     = valve["t_junction"]
    mf    = ref(gm,n,:max_mass_flow)

    constraint_on_off_control_valve_flow(gm, n, k, i, j, mf)
end
constraint_on_off_control_valve_flow(gm::GenericGasModel, k::Int) = constraint_on_off_control_valve_flow(gm, gm.cnw, k)

" Template: Constraints on control valve flows when flow is restricted to one direction"
function constraint_control_valve_flow_one_way(gm::GenericGasModel, n::Int, k)
    valve = ref(gm,n,:connection,k)
    i     = valve["f_junction"]
    j     = valve["t_junction"]
    mf    = ref(gm,n,:max_mass_flow)
    yp    = valve["yp"]
    yn    = valve["yn"]
    constraint_control_valve_flow_one_way(gm, n, k, i, j, mf, yp, yn)
end
constraint_control_valve_flow_one_way(gm::GenericGasModel, k::Int) = constraint_control_valve_flow_one_way(gm, gm.cnw, k)

"Constraint Enforces pressure changes bounds that obey decompression ratios for "
function constraint_control_valve_pressure_drop(gm::GenericGasModel, n::Int, k)
    control_valve     = ref(gm,n,:control_valve,k)
    i              = control_valve["f_junction"]
    j              = control_valve["t_junction"]
    max_ratio      = control_valve["c_ratio_max"]
    min_ratio      = control_valve["c_ratio_min"]

    constraint_control_valve_pressure_drop(gm, n, k, i, j, min_ratio, max_ratio)
end
constraint_control_valve_pressure_drop(gm::GenericGasModel, k::Int) = constraint_control_valve_pressure_drop(gm, gm.cnw, k)

" Template: Constraints on control valve pressure when flow is restricted to one direction"
function constraint_control_valve_pressure_drop_one_way(gm::GenericGasModel, n::Int, k)
    valve     = ref(gm,n,:connection,k)
    i         = valve["f_junction"]
    j         = valve["t_junction"]
    max_ratio = valve["c_ratio_max"]
    min_ratio = valve["c_ratio_min"]
    j_pmax    = ref(gm,n,:junction,j)["pmax"]
    i_pmax    = ref(gm,n,:junction,i)["pmax"]
    yp        = valve["yp"]
    yn        = valve["yn"]
    constraint_control_valve_pressure_drop_one_way(gm, n, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax, yp, yn)
end
constraint_control_valve_pressure_drop_one_way(gm::GenericGasModel, k::Int) = constraint_control_valve_pressure_drop_one_way(gm, gm.cnw, k)

#################################################################################################
# Templates for misc constraints
#################################################################################################

" Template: Constraint which restricts selction of expansion pipes that are in paralell to a single one "
function constraint_exclusive_new_pipes(gm::GenericGasModel,  n::Int, i, j)
    parallel = ref(gm,n,:parallel_ne_pipes, (i,j))
    constraint_exclusive_new_pipes(gm, n, i, j, parallel)
end
constraint_exclusive_new_pipes(gm::GenericGasModel, i::Int, j::Int) = constraint_exclusive_new_pipes(gm, gm.cnw, i, j)
