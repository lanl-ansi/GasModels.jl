"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_junction_flow_balance(gm::AbstractGasModel, i; n::Int = nw_id_default)
    junction = ref(gm, n, :junction, i)
    f_pipes = ref(gm, n, :pipes_fr, i)
    t_pipes = ref(gm, n, :pipes_to, i)
    f_compressors = ref(gm, n, :compressors_fr, i)
    t_compressors = ref(gm, n, :compressors_to, i)
    delivery = ref(gm, n, :delivery)
    receipt = ref(gm, n, :receipt)
    transfer = ref(gm, n, :transfer)
    dispatch_receipts = ref(gm, n, :dispatchable_receipts_in_junction, i)
    nondispatch_receipts = ref(gm, n, :nondispatchable_receipts_in_junction, i)
    dispatch_deliveries = ref(gm, n, :dispatchable_deliveries_in_junction, i)
    nondispatch_deliveries = ref(gm, n, :nondispatchable_deliveries_in_junction, i)
    dispatch_transfers = ref(gm, n, :dispatchable_transfers_in_junction, i)
    nondispatch_transfers = ref(gm, n, :nondispatchable_transfers_in_junction, i)
    storages = ref(gm, n, :storages_in_junction, i)

    fg = length(nondispatch_receipts) > 0 ? sum(receipt[j]["injection_nominal"] for j in nondispatch_receipts) : 0
    fl = length(nondispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_nominal"] for j in nondispatch_deliveries) : 0
    fl += length(nondispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_nominal"] for j in nondispatch_transfers) : 0
    fgmax = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_max"] for j in dispatch_receipts) : 0
    flmax = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_max"] for j in dispatch_deliveries) : 0
    flmax += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_max"] for j in dispatch_transfers) : 0
    fgmin = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_min"] for j in dispatch_receipts) : 0
    flmin = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_min"] for j in dispatch_deliveries) : 0
    flmin += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_min"] for j in dispatch_transfers) : 0

    constraint_junction_flow_balance(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, fl, fg, dispatch_deliveries, dispatch_receipts, dispatch_transfers, storages, flmin, flmax, fgmin, fgmax)
end

"Template: Constraints for fixing pressure at a node"
function constraint_slack_potential(gm::AbstractGasModel, i; n::Int = nw_id_default)
    b1, b2 = ref(gm, nw, :non_ideal_coeffs)
    get_potential = x -> b1 * x^2/2.0 + b2 * x^3/3.0 
    junction = ref(gm, n, :junction)[i]
    is_slack = junction["junction_type"] == 1
    if is_slack
        potential = get_potential(junction["p_max"])
        constraint_slack_potential(gm, n, i, potential)
    end 
end

"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe"
function constraint_pipe_physics(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :pipe, k)
    i = pipe["fr_junction"]
    j = pipe["to_junction"]
    D = pipe["diameter"]
    L = pipe["length"]
    A = pipe["area"]
    euler_num = ref(gm, n, :euler_num) 
    mach_num = ref(gm, n, :mach_num)
    lambda = pipe["friction_factor"]
    resistance = (D == 0.0) ? 0. : (-lambda * L * mach_num^2 / 2.0 / D / A^2 / euler_num) 
    constraint_pipe_physics(gm, n, k, i, j, resistance)
end

"Template: Compression ratios for a compressor"
function constraint_compressor_physics(gm::AbstractGasModel, k; n::Int = nw_id_default)
    b1, b2 = ref(gm, nw, :non_ideal_coeffs)
    get_potential = x -> b1 * x^2/2.0 + b2 * x^3/3.0 
    compressor = ref(gm, n, :compressor, k)
    i = compressor["fr_junction"]
    j = compressor["to_junction"]
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    j_potential_max = get_potential(ref(gm, n, :junction, j)["p_max"])
    i_potential_max = get_potential(ref(gm, n, :junction, i)["p_max"])
    j_potential_min = get_potential(ref(gm, n, :junction, j)["p_min"])
    i_potential_min = get_potential(ref(gm, n, :junction, i)["p_min"])
    type = get(compressor, "directionality", 0)

    constraint_compressor_physics(gm, n, k, i, j, min_ratio, max_ratio, i_potential_min, i_potenial_max, j_potential_min, j_potential_max, type)
end

"Template: Constraints on the compressor power"
function constraint_compressor_power(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :compressor, k)
    power_max = compressor["power_max"]
    gamma = get_specific_heat_capacity_ratio(gm.data)
    T = get_temperature(gm.data)
    G = get_gas_specific_gravity(gm.data)
    C = gamma / (gamma - 1) * 286.0 / G * T
    constraint_compressor_power(gm, n, k, power_max, C)
end