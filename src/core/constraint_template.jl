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
    pipe             = ref(gm,n,:resistor,k)
    f_min            = pipe["flow_min"]
    f_max            = pipe["flow_max"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min = max(0, f_min)
    end

    if flow_direction == -1
        f_max = min(0, f_max)
    end

    constraint_resistor_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Pressure drop across resistor with on/off direction variables"
function constraint_resistor_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm, n,:resistor, k)
    i                = pipe["fr_junction"]
    j                = pipe["to_junction"]
    pd_max           = pipe["pd_max"]
    pd_min           = pipe["pd_min"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        pd_min = max(0, pd_min)
    end

    if flow_direction == -1
        pd_max = min(0, pd_max)
    end

    constraint_resistor_pressure(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Weymouth equation for defining the relationship between pressure drop and flow across a resistor"
function constraint_resistor_weymouth(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm,n,:resistor,k)
    i                = pipe["fr_junction"]
    j                = pipe["to_junction"]
    w                = pipe["resistance"]
    pd_max           = pipe["pd_max"]
    pd_min           = pipe["pd_min"]
    f_min            = pipe["flow_min"]
    f_max            = pipe["flow_max"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        pd_min = max(0, pd_min)
        f_min  = max(0,f_min)
    end

    if flow_direction == -1
        pd_max = min(0, pd_max)
        f_max  = min(0, f_max)
    end

    constraint_resistor_weymouth(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max)
end


#################################################################################################
# Templates for constraints associated with pipes
#################################################################################################

"Template: Constraint on mass flow across a pipe"
function constraint_pipe_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm,n,:pipe,k)
    f_min            = pipe["flow_min"]
    f_max            = pipe["flow_max"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min = max(0, f_min)
    end

    if flow_direction == -1
        f_max = min(0, f_max)
    end

    constraint_pipe_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Pressure drop across pipes"
function constraint_pipe_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm, n,:pipe, k)
    i                = pipe["fr_junction"]
    j                = pipe["to_junction"]
    pd_max           = pipe["pd_max"]
    pd_min           = pipe["pd_min"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        pd_min = max(0, pd_min)
    end

    if flow_direction == -1
        pd_max = min(0, pd_max)
    end

    constraint_pipe_pressure(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Constraints on flow across an expansion pipe with on/off direction variables"
function constraint_pipe_mass_flow_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm,n,:ne_pipe, k)
    pd_max           = pipe["pd_max"]
    pd_min           = pipe["pd_min"]
    w                = pipe["resistance"]
    f_min            = pipe["flow_min"]
    f_max            = pipe["flow_max"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min  = max(0,f_min)
    end

    if flow_direction == -1
        f_max  = min(0, f_max)
    end

    constraint_pipe_mass_flow_ne(gm, n, k, f_min, f_max)
end


"Template: Constraints on pressure drop across pipes"
function constraint_pipe_pressure_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm,n,:ne_pipe,k)
    i                = pipe["fr_junction"]
    j                = pipe["to_junction"]
    pd_max           = pipe["pd_max"]
    pd_min           = pipe["pd_min"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)
    pd_min_M         = pd_min
    pd_max_M         = pd_max

    if is_bidirectional == 0 || flow_direction == 1
        pd_min = max(0, pd_min)
    end

    if flow_direction == -1
        pd_max = min(0, pd_max)
    end

    constraint_pipe_pressure_ne(gm, n, k, i, j, pd_min, pd_max, pd_min_M, pd_max_M)
end


"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe"
function constraint_pipe_weymouth(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm,n,:pipe,k)
    i                = pipe["fr_junction"]
    j                = pipe["to_junction"]
    w                = pipe["resistance"]
    pd_max           = pipe["pd_max"]
    pd_min           = pipe["pd_min"]
    f_min            = pipe["flow_min"]
    f_max            = pipe["flow_max"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        pd_min = max(0, pd_min)
        f_min  = max(0,f_min)
    end

    if flow_direction == -1
        pd_max = min(0, pd_max)
        f_max  = min(0, f_max)
    end

    constraint_pipe_weymouth(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max)
end


"Template: Constraint associatd with turning off flow depending on the status of expansion pipes"
function constraint_pipe_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = gm.ref[:nw][n][:ne_pipe][k]
    w                = pipe["resistance"]
    f_min            = pipe["flow_min"]
    f_max            = pipe["flow_max"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min  = max(0,f_min)
    end

    if flow_direction == -1
        f_max  = min(0, f_max)
    end

    constraint_pipe_ne(gm, n, k, w, f_min, f_max)
end


"Template: Weymouth equation for expansion pipes"
function constraint_pipe_weymouth_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe           = gm.ref[:nw][n][:ne_pipe][k]
    i              = pipe["fr_junction"]
    j              = pipe["to_junction"]
    w              = pipe["resistance"]
    pd_max         = pipe["pd_max"]
    pd_min         = pipe["pd_min"]
    f_min          = pipe["flow_min"]
    f_max          = pipe["flow_max"]

    # These all get used as big M's....

    constraint_pipe_weymouth_ne(gm, n, k, i, j, w, f_min, f_max, pd_min, pd_max)
end


#################################################################################################
# Templates for constraints associated with junctions
#################################################################################################

"Template: Constraints for fixing pressure at a node"
function constraint_pressure(gm::AbstractGasModel, i; n::Int=gm.cnw)
    junction       = gm.ref[:nw][n][:junction][i]
    p              = junction["p_nominal"]^2
    constraint_pressure(gm, n, i, p)
end


"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_mass_flow_balance(gm::AbstractGasModel, i; n::Int=gm.cnw)
    junction                = ref(gm,n,:junction,i)
    f_pipes                 = ref(gm,n,:pipes_fr,i)
    t_pipes                 = ref(gm,n,:pipes_to,i)
    f_compressors           = ref(gm,n,:compressors_fr,i)
    t_compressors           = ref(gm,n,:compressors_to,i)
    f_resistors             = ref(gm,n,:resistors_fr,i)
    t_resistors             = ref(gm,n,:resistors_to,i)
    f_short_pipes           = ref(gm,n,:short_pipes_fr,i)
    t_short_pipes           = ref(gm,n,:short_pipes_to,i)
    f_valves                = ref(gm,n,:valves_fr,i)
    t_valves                = ref(gm,n,:valves_to,i)
    f_regulators            = ref(gm,n,:regulators_fr,i)
    t_regulators            = ref(gm,n,:regulators_to,i)
    delivery                = ref(gm,n,:delivery)
    receipt                 = ref(gm,n,:receipt)
    transfer                = ref(gm,n,:transfer)
    dispatch_receipts       = ref(gm,n,:dispatchable_receipts_in_junction,i)
    nondispatch_receipts    = ref(gm,n,:nondispatchable_receipts_in_junction,i)
    dispatch_deliveries     = ref(gm,n,:dispatchable_deliveries_in_junction,i)
    nondispatch_deliveries  = ref(gm,n,:nondispatchable_deliveries_in_junction,i)
    dispatch_transfers      = ref(gm,n,:dispatchable_transfers_in_junction,i)
    nondispatch_transfers   = ref(gm,n,:nondispatchable_transfers_in_junction,i)
    fg                      = length(nondispatch_receipts) > 0 ? sum(receipt[j]["injection_nominal"] for j in nondispatch_receipts) : 0
    fl                      = length(nondispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_nominal"] for j in nondispatch_deliveries) : 0
    fl                      += length(nondispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_nominal"] for j in nondispatch_transfers) : 0
    fgmax                   = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_max"] for j in dispatch_receipts) : 0
    flmax                   = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_max"] for j in dispatch_deliveries) : 0
    flmax                   += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_max"] for j in dispatch_transfers) : 0
    fgmin                   = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_min"] for j in dispatch_receipts) : 0
    flmin                   = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_min"] for j in dispatch_deliveries) : 0
    flmin                   += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_min"] for j in dispatch_transfers) : 0

    constraint_mass_flow_balance(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, fl, fg, dispatch_deliveries, dispatch_receipts, dispatch_transfers, flmin, flmax, fgmin, fgmax)
end


"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables and there are expansion connections"
function constraint_mass_flow_balance_ne(gm::AbstractGasModel, i; n::Int=gm.cnw)
    junction                = ref(gm,n,:junction,i)
    f_pipes                 = ref(gm,n,:pipes_fr,i)
    t_pipes                 = ref(gm,n,:pipes_to,i)
    f_compressors           = ref(gm,n,:compressors_fr,i)
    t_compressors           = ref(gm,n,:compressors_to,i)
    f_resistors             = ref(gm,n,:resistors_fr,i)
    t_resistors             = ref(gm,n,:resistors_to,i)
    f_short_pipes           = ref(gm,n,:short_pipes_fr,i)
    t_short_pipes           = ref(gm,n,:short_pipes_to,i)
    f_valves                = ref(gm,n,:valves_fr,i)
    t_valves                = ref(gm,n,:valves_to,i)
    f_regulators            = ref(gm,n,:regulators_fr,i)
    t_regulators            = ref(gm,n,:regulators_to,i)
    delivery                = ref(gm,n,:delivery)
    receipt                 = ref(gm,n,:receipt)
    transfer                = ref(gm,n,:transfer)
    dispatch_receipts       = ref(gm,n,:dispatchable_receipts_in_junction,i)
    nondispatch_receipts    = ref(gm,n,:nondispatchable_receipts_in_junction,i)
    dispatch_deliveries     = ref(gm,n,:dispatchable_deliveries_in_junction,i)
    nondispatch_deliveries  = ref(gm,n,:nondispatchable_deliveries_in_junction,i)
    dispatch_transfers      = ref(gm,n,:dispatchable_transfers_in_junction,i)
    nondispatch_transfers   = ref(gm,n,:nondispatchable_transfers_in_junction,i)
    fg                      = length(nondispatch_receipts) > 0 ? sum(receipt[j]["injection_nominal"] for j in nondispatch_receipts) : 0
    fl                      = length(nondispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_nominal"] for j in nondispatch_deliveries) : 0
    fl                      += length(nondispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_nominal"] for j in nondispatch_transfers) : 0
    fgmax                   = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_max"] for j in dispatch_receipts) : 0
    flmax                   = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_max"] for j in dispatch_deliveries) : 0
    flmax                   += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_max"] for j in dispatch_transfers) : 0
    fgmin                   = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_min"] for j in dispatch_receipts) : 0
    flmin                   = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_min"] for j in dispatch_deliveries) : 0
    flmin                   += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_min"] for j in dispatch_transfers) : 0

    ne_pipes_fr              = ref(gm,n,:ne_pipes_fr,i)
    ne_pipes_to              = ref(gm,n,:ne_pipes_to,i)
    ne_compressors_fr        = ref(gm,n,:ne_compressors_fr,i)
    ne_compressors_to        = ref(gm,n,:ne_compressors_to,i)

    constraint_mass_flow_balance_ne(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, ne_pipes_fr, ne_pipes_to, ne_compressors_fr, ne_compressors_to, fl, fg, dispatch_deliveries, dispatch_receipts, dispatch_transfers, flmin, flmax, fgmin, fgmax)
end


#################################################################################################
# Templates for constraints associated with short pipes
#################################################################################################

"Template: Constraint on pressure drop across a short pipe"
function constraint_short_pipe_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe = ref(gm,n,:short_pipe,k)
    i    = pipe["fr_junction"]
    j    = pipe["to_junction"]
    constraint_short_pipe_pressure(gm, n, k, i, j)
end


"Constraint: constraints on flow across a short pipe"
function constraint_short_pipe_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    pipe             = ref(gm,n,:short_pipe,k)
    f_min            = pipe["flow_min"]
    f_max            = pipe["flow_max"]
    is_bidirectional = get(pipe, "is_bidirectional", 1)
    flow_direction   = get(pipe, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min = max(0, f_min)
    end

    if flow_direction == -1
        f_max = min(0, f_max)
    end

    constraint_short_pipe_mass_flow(gm, n, k, f_min, f_max)
end


#################################################################################################
# Templates for constraints associated with valves
#################################################################################################

"Template: Constraint on pressure drop across valves, where the valve may be closed or opened"
function constraint_on_off_valve_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve  = ref(gm,n,:valve,k)
    i      = valve["fr_junction"]
    j      = valve["to_junction"]
    j_pmax = gm.ref[:nw][n][:junction][j]["p_max"]
    i_pmax = gm.ref[:nw][n][:junction][i]["p_max"]
    constraint_on_off_valve_pressure(gm, n, k, i, j, i_pmax, j_pmax)
end


"Template: constraints on flow across valves modeled with on/off direction variables"
function constraint_on_off_valve_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve            = ref(gm,n,:valve,k)
    f_min            = valve["flow_min"]
    f_max            = valve["flow_max"]
    is_bidirectional = get(valve, "is_bidirectional", 1)
    flow_direction   = get(valve, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min = max(0, f_min)
    end

    if flow_direction == -1
        f_max = min(0, f_max)
    end

    constraint_on_off_valve_mass_flow(gm, n, k, f_min, f_max)
end


#################################################################################################
# Templates for constraints associated with compressors
#################################################################################################

"Template: Compression ratios for a compressor"
function constraint_compressor_ratios(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor       = ref(gm,n,:compressor,k)
    i                = compressor["fr_junction"]
    j                = compressor["to_junction"]
    max_ratio        = compressor["c_ratio_max"]
    min_ratio        = compressor["c_ratio_min"]
    j_pmax           = ref(gm,n,:junction,j)["p_max"]
    i_pmax           = ref(gm,n,:junction,i)["p_max"]
    j_pmin           = ref(gm,n,:junction,j)["p_min"]
    i_pmin           = ref(gm,n,:junction,i)["p_min"]
    type             = get(compressor, "directionality", 0)

    constraint_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
end


"Template: Constraint for turning on or off flow through expansion compressor"
function constraint_compressor_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = gm.ref[:nw][n][:ne_compressor][k]
    f_min      = ref(gm,n,:ne_compressor,k)["flow_min"]
    f_max      = ref(gm,n,:ne_compressor,k)["flow_max"]
    constraint_compressor_ne(gm, n, k, f_min, f_max)
end


"Template: constraints on flow across a compressor"
function constraint_compressor_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor       = ref(gm, n, :compressor, k)
    f_min            = compressor["flow_min"]
    f_max            = compressor["flow_max"]
    directionality   = get(compressor, "directionality", 0)
    flow_direction   = get(compressor, "flow_direction", 0)

    if directionality == 1 || flow_direction == 1
        f_min = max(0, f_min)
    end

    if flow_direction == -1
        f_max = min(0, f_max)
    end


    constraint_compressor_mass_flow(gm, n, k, f_min, f_max)
end


"Template: constraints on flow across compressors where direction"
function constraint_compressor_mass_flow_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:ne_compressor,k)
    i              = compressor["fr_junction"]
    j              = compressor["to_junction"]
    f_min          = ref(gm,n,:ne_compressor,k)["flow_min"]
    f_max          = ref(gm,n,:ne_compressor,k)["flow_max"]
    constraint_compressor_mass_flow_ne(gm, n, k, f_min, f_max)
end


"Template: constraints on pressure drop across a compressor"
function constraint_compressor_ratios_ne(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:ne_compressor, k)
    i              = compressor["fr_junction"]
    j              = compressor["to_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["p_max"]
    j_pmin         = ref(gm,n,:junction,j)["p_min"]
    i_pmax         = ref(gm,n,:junction,i)["p_max"]
    i_pmin         = ref(gm,n,:junction,i)["p_min"]
    f_max          = ref(gm,n,:ne_compressor,k)["flow_max"]
    constraint_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, f_max, i_pmin, i_pmax, j_pmin, j_pmax)
end


"Template: Constraints on compressor ratios when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_ratios_ne_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = ref(gm,n,:ne_compressor, k)
    i              = compressor["fr_junction"]
    j              = compressor["to_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["p_max"]
    i_pmax         = ref(gm,n,:junction,i)["p_max"]
    i_pmin         = ref(gm,n,:junction,i)["p_min"]
    f_max          = ref(gm,n,:ne_compressor,k)["flow_max"]
    direction      = 1
    constraint_compressor_ratios_ne_directed(gm, n, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax, direction)
end


"Template: Constraints on compressor flows when flow is restricted to one direction and the compressor is an expanson option"
function constraint_compressor_mass_flow_ne_directed(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor = ref(gm,n,:ne_compressor,k)
    i          = compressor["fr_junction"]
    j          = compressor["to_junction"]
    mf         = ref(gm,n,:max_mass_flow)
    f_min     = max(0,ref(gm,n,:ne_compressor,k)["flow_min"])
    f_max     = ref(gm,n,:ne_compressor,k)["flow_max"]

    constraint_compressor_mass_flow_ne_directed(gm, n, k, f_min, f_max)
end


"Template: Constraints on the compressor ratio value"
function constraint_compressor_ratio_value(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:compressor,k)
    i              = compressor["fr_junction"]
    j              = compressor["to_junction"]
    constraint_compressor_ratio_value(gm, n, k, i, j)
end


"Template: Constraints on the compressor energy"
function constraint_compressor_energy(gm::AbstractGasModel, k; n::Int=gm.cnw)
    compressor     = ref(gm,n,:compressor,k)
    power_max      = compressor["power_max"]
    gamma          = gm.data["specific_heat_capacity_ratio"]
    magic_num      = 286.76
    m              = ((gamma - 1) / gamma) / 2
    T              = gm.data["temperature"]
    G              = gm.data["gas_specific_gravity"]
    work           = ((magic_num / G) * T * (gamma/(gamma-1)))
    constraint_compressor_energy(gm, n, k, power_max, m, work)
end


#################################################################################################
# Templates for control valves
#################################################################################################

"Template: constraints on flow across control valves with on/off direction variables"
function constraint_on_off_regulator_mass_flow(gm::AbstractGasModel, k; n::Int=gm.cnw)
    valve            = ref(gm,n,:regulator,k)
    f_min            = valve["flow_min"]
    f_max            = valve["flow_max"]
    is_bidirectional = get(valve, "is_bidirectional", 1)
    flow_direction   = get(valve, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min = max(0, f_min)
    end

    if flow_direction == -1
        f_max = min(0, f_max)
    end

    constraint_on_off_regulator_mass_flow(gm, n, k, f_min, f_max)
end


"Constraint Enforces pressure changes bounds that obey decompression ratios for"
function constraint_on_off_regulator_pressure(gm::AbstractGasModel, k; n::Int=gm.cnw)
    regulator = ref(gm,n,:regulator,k)
    i                = regulator["fr_junction"]
    j                = regulator["to_junction"]
    max_ratio        = regulator["reduction_factor_max"]
    min_ratio        = regulator["reduction_factor_min"]
    j_pmin           = ref(gm,n,:junction,j)["p_min"]
    j_pmax           = ref(gm,n,:junction,j)["p_max"]
    i_pmax           = ref(gm,n,:junction,i)["p_max"]
    i_pmin           = ref(gm,n,:junction,i)["p_min"]
    f_min            = regulator["flow_min"]
    is_bidirectional = get(regulator, "is_bidirectional", 1)
    flow_direction   = get(regulator, "flow_direction", 0)

    if is_bidirectional == 0 || flow_direction == 1
        f_min = max(0, f_min)
    end

    constraint_on_off_regulator_pressure(gm, n, k, i, j, min_ratio, max_ratio, f_min, i_pmin, i_pmax, j_pmin, j_pmax)
end
