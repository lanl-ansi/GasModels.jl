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
function constraint_resistor_mass_flow(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :resistor, k)
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]

    constraint_resistor_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Pressure drop across resistor with on/off direction variables"
function constraint_resistor_pressure(gm::AbstractGasModel, k; n::Int=nw_id_default)
    resistor         = ref(gm, n, :resistor, k)
    i                = resistor["fr_junction"]
    j                = resistor["to_junction"]
    i_junction       = ref(gm, n, :junction, i)
    j_junction       = ref(gm, n, :junction, j)
    pd_min, pd_max   = _calc_resistor_pd_bounds(resistor, i_junction, j_junction)

    constraint_resistor_pressure(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Darcy-Weisbach equation for defining the relationship between pressure drop and flow across a resistor"
function constraint_resistor_darcy_weisbach(gm::AbstractGasModel, k; n::Int=nw_id_default)
    resistor         = ref(gm, n, :resistor, k)
    i                = resistor["fr_junction"]
    j                = resistor["to_junction"]
    density          = get(gm.ref[:it][gm_it_sym], :standard_density, _estimate_standard_density(gm.data))
    w                = _calc_resistor_resistance(resistor, Float64(gm.ref[:it][gm_it_sym][:base_pressure]),
                                                 Float64(gm.ref[:it][gm_it_sym][:base_flow]), density)
    pd_min, pd_max   = _calc_resistor_pd_bounds(resistor, ref(gm, n, :junction, i), ref(gm, n, :junction, j))
    f_min            = resistor["flow_min"]
    f_max            = resistor["flow_max"]

    constraint_resistor_darcy_weisbach(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max)
end


###############################################################################################
# Templates for constraints associated with loss_resistors
###############################################################################################

"Template: Constraint on mass flow across a loss_resistor"
function constraint_loss_resistor_mass_flow(gm::AbstractGasModel, k; n::Int = nw_id_default)
    loss_resistor = ref(gm, n, :loss_resistor, k)
    f_min = loss_resistor["flow_min"]
    f_max = loss_resistor["flow_max"]

    constraint_loss_resistor_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Pressure drop across loss_resistor with on/off direction variables"
function constraint_loss_resistor_pressure(gm::AbstractGasModel, k; n::Int = nw_id_default)
    loss_resistor = ref(gm, n, :loss_resistor, k)
    i, j = loss_resistor["fr_junction"], loss_resistor["to_junction"]
    pd = loss_resistor["p_loss"]

    constraint_loss_resistor_pressure(gm, n, k, i, j, pd)
end


#################################################################################################
# Templates for constraints associated with pipes
#################################################################################################

"Template: Constraint on mass flow across a pipe"
function constraint_pipe_mass_flow(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :pipe, k)
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]

    constraint_pipe_mass_flow(gm, n, k, f_min, f_max)
end


"Template: Pressure drop across pipes"
function constraint_pipe_pressure(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :pipe, k)
    i = pipe["fr_junction"]
    j = pipe["to_junction"]
    pd_min, pd_max = _calc_pipe_pd_bounds_sqr(pipe, ref(gm, n, :junction, i), ref(gm, n, :junction, j))

    constraint_pipe_pressure(gm, n, k, i, j, pd_min, pd_max)
end


"Template: Constraints on flow across an expansion pipe with on/off direction variables"
function constraint_pipe_mass_flow_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :ne_pipe, k)
    w = _calc_pipe_resistance(pipe, gm.ref[:it][gm_it_sym][:base_length], gm.ref[:it][gm_it_sym][:base_pressure], gm.ref[:it][gm_it_sym][:base_flow], gm.ref[:it][gm_it_sym][:sound_speed])
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]

    constraint_pipe_mass_flow_ne(gm, n, k, f_min, f_max)
end


"Template: Constraints on pressure drop across pipes"
function constraint_pipe_pressure_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :ne_pipe, k)
    i = pipe["fr_junction"]
    j = pipe["to_junction"]
    pd_min_on, pd_max_on, pd_min_off, pd_max_off = _calc_ne_pipe_pd_bounds_sqr(pipe, ref(gm, n, :junction, i), ref(gm, n, :junction, j))

    constraint_pipe_pressure_ne(gm, n, k, i, j, pd_min_on, pd_max_on, pd_min_off, pd_max_off)
end


"Template: Weymouth equation for defining the relationship between pressure drop and flow across a pipe"
function constraint_pipe_weymouth(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :pipe, k)
    i = pipe["fr_junction"]
    j = pipe["to_junction"]
    pd_min, pd_max = _calc_pipe_pd_bounds_sqr(pipe, ref(gm, n, :junction, i), ref(gm, n, :junction, j))
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]
    theta = pipe["theta"]
    D = pipe["diameter"]

    if(D!=0.0)
        if(rad2deg(abs(theta)) <= 5)
            w = _calc_pipe_resistance(pipe, gm.ref[:it][gm_it_sym][:base_length], gm.ref[:it][gm_it_sym][:base_pressure], gm.ref[:it][gm_it_sym][:base_flow], gm.ref[:it][gm_it_sym][:sound_speed])
            constraint_pipe_weymouth(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max)
        else
            r_1,r_2 = _calc_inclined_pipe_resistance(pipe,gm.ref[:it][gm_it_sym][:base_length], gm.ref[:it][gm_it_sym][:base_pressure], gm.ref[:it][gm_it_sym][:base_flow], gm.ref[:it][gm_it_sym][:sound_speed])
            constraint_inclined_pipe_pressure_drop(gm, n, k, i, j, r_1, r_2)
        end
    end
end


"Template: Constraint associatd with turning off flow depending on the status of expansion pipes"
function constraint_pipe_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :ne_pipe, k)
    w = _calc_pipe_resistance(pipe, gm.ref[:it][gm_it_sym][:base_length], gm.ref[:it][gm_it_sym][:base_pressure], gm.ref[:it][gm_it_sym][:base_flow], gm.ref[:it][gm_it_sym][:sound_speed])
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]

    constraint_pipe_ne(gm, n, k, w, f_min, f_max)
end


"Template: Weymouth equation for expansion pipes"
function constraint_pipe_weymouth_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :ne_pipe, k)
    i = pipe["fr_junction"]
    j = pipe["to_junction"]
    w = _calc_pipe_resistance(pipe, gm.ref[:it][gm_it_sym][:base_length], gm.ref[:it][gm_it_sym][:base_pressure], gm.ref[:it][gm_it_sym][:base_flow], gm.ref[:it][gm_it_sym][:sound_speed])
    pd_min_on, pd_max_on, pd_min_off, pd_max_off = _calc_ne_pipe_pd_bounds_sqr(pipe, ref(gm, n, :junction, i), ref(gm, n, :junction, j))
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]

    constraint_pipe_weymouth_ne(gm, n, k, i, j, w, f_min, f_max, pd_min_off, pd_max_off)
end


#################################################################################################
# Templates for constraints associated with junctions
#################################################################################################

"Template: Constraints for fixing pressure at a node"
function constraint_pressure(gm::AbstractGasModel, i; n::Int = nw_id_default)
    junction = ref(gm, n, :junction)[i]
    p = junction["p_nominal"]
    constraint_pressure(gm, n, i, p)
end


"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_mass_flow_balance(gm::AbstractGasModel, i; n::Int = nw_id_default)
    junction = ref(gm, n, :junction, i)
    f_pipes = ref(gm, n, :pipes_fr, i)
    t_pipes = ref(gm, n, :pipes_to, i)
    f_compressors = ref(gm, n, :compressors_fr, i)
    t_compressors = ref(gm, n, :compressors_to, i)
    f_resistors = ref(gm, n, :resistors_fr, i)
    t_resistors = ref(gm, n, :resistors_to, i)
    f_loss_resistors = ref(gm, n, :loss_resistors_fr, i)
    t_loss_resistors = ref(gm, n, :loss_resistors_to, i)
    f_short_pipes = ref(gm, n, :short_pipes_fr, i)
    t_short_pipes = ref(gm, n, :short_pipes_to, i)
    f_valves = ref(gm, n, :valves_fr, i)
    t_valves = ref(gm, n, :valves_to, i)
    f_regulators = ref(gm, n, :regulators_fr, i)
    t_regulators = ref(gm, n, :regulators_to, i)
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

    constraint_mass_flow_balance(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, fl, fg, dispatch_deliveries, dispatch_receipts, dispatch_transfers, storages, flmin, flmax, fgmin, fgmax)
end


"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables and there are expansion connections"
function constraint_mass_flow_balance_ne(gm::AbstractGasModel, i; n::Int = nw_id_default)
    junction = ref(gm, n, :junction, i)
    f_pipes = ref(gm, n, :pipes_fr, i)
    t_pipes = ref(gm, n, :pipes_to, i)
    f_compressors = ref(gm, n, :compressors_fr, i)
    t_compressors = ref(gm, n, :compressors_to, i)
    f_resistors = ref(gm, n, :resistors_fr, i)
    t_resistors = ref(gm, n, :resistors_to, i)
    f_loss_resistors = ref(gm, n, :loss_resistors_fr, i)
    t_loss_resistors = ref(gm, n, :loss_resistors_to, i)
    f_short_pipes = ref(gm, n, :short_pipes_fr, i)
    t_short_pipes = ref(gm, n, :short_pipes_to, i)
    f_valves = ref(gm, n, :valves_fr, i)
    t_valves = ref(gm, n, :valves_to, i)
    f_regulators = ref(gm, n, :regulators_fr, i)
    t_regulators = ref(gm, n, :regulators_to, i)
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

    ne_pipes_fr = ref(gm, n, :ne_pipes_fr, i)
    ne_pipes_to = ref(gm, n, :ne_pipes_to, i)
    ne_compressors_fr = ref(gm, n, :ne_compressors_fr, i)
    ne_compressors_to = ref(gm, n, :ne_compressors_to, i)

    constraint_mass_flow_balance_ne(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, ne_pipes_fr, ne_pipes_to, ne_compressors_fr, ne_compressors_to, fl, fg, dispatch_deliveries, dispatch_receipts, dispatch_transfers, storages, flmin, flmax, fgmin, fgmax)
end


#################################################################################################
# Templates for constraints associated with short pipes
#################################################################################################

"Template: Constraint on pressure drop across a short pipe"
function constraint_short_pipe_pressure(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :short_pipe, k)
    i = pipe["fr_junction"]
    j = pipe["to_junction"]
    constraint_short_pipe_pressure(gm, n, k, i, j)
end


"Constraint: constraints on flow across a short pipe"
function constraint_short_pipe_mass_flow(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :short_pipe, k)
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]

    constraint_short_pipe_mass_flow(gm, n, k, f_min, f_max)
end


#################################################################################################
# Templates for constraints associated with valves
#################################################################################################

"Template: Constraint on pressure drop across valves, where the valve may be closed or opened"
function constraint_on_off_valve_pressure(gm::AbstractGasModel, k; n::Int = nw_id_default)
    valve = ref(gm, n, :valve, k)
    i = valve["fr_junction"]
    j = valve["to_junction"]
    j_pmax = ref(gm, n, :junction)[j]["p_max"]
    i_pmax = ref(gm, n, :junction)[i]["p_max"]
    constraint_on_off_valve_pressure(gm, n, k, i, j, i_pmax, j_pmax)
end


"Template: constraints on flow across valves modeled with on/off direction variables"
function constraint_on_off_valve_mass_flow(gm::AbstractGasModel, k; n::Int = nw_id_default)
    valve = ref(gm, n, :valve, k)
    f_min = valve["flow_min"]
    f_max = valve["flow_max"]

    constraint_on_off_valve_mass_flow(gm, n, k, f_min, f_max)
end


#################################################################################################
# Templates for constraints associated with compressors
#################################################################################################

"Template: Compression ratios for a compressor"
function constraint_compressor_ratios(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :compressor, k)
    i = compressor["fr_junction"]
    j = compressor["to_junction"]
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    j_pmax = ref(gm, n, :junction, j)["p_max"]
    i_pmax = ref(gm, n, :junction, i)["p_max"]
    j_pmin = ref(gm, n, :junction, j)["p_min"]
    i_pmin = ref(gm, n, :junction, i)["p_min"]
    type = get(compressor, "directionality", 0)

    constraint_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
end


"Template: Constraint for turning on or off flow through expansion compressor"
function constraint_compressor_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :ne_compressor, k)
    f_min = compressor["flow_min"]
    f_max = compressor["flow_max"]

    constraint_compressor_ne(gm, n, k, f_min, f_max)
end


"Template: constraints on flow across a compressor"
function constraint_compressor_mass_flow(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :compressor, k)
    f_min = compressor["flow_min"]
    f_max = compressor["flow_max"]

    constraint_compressor_mass_flow(gm, n, k, f_min, f_max)
end


"Template: constraints on flow across compressors where direction"
function constraint_compressor_mass_flow_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :ne_compressor, k)
    i = compressor["fr_junction"]
    j = compressor["to_junction"]
    f_min = compressor["flow_min"]
    f_max = compressor["flow_max"]

    constraint_compressor_mass_flow_ne(gm, n, k, f_min, f_max)
end


"Template: constraints on pressure drop across a compressor"
function constraint_compressor_ratios_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :ne_compressor, k)
    i = compressor["fr_junction"]
    j = compressor["to_junction"]
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    j_pmax = ref(gm, n, :junction, j)["p_max"]
    j_pmin = ref(gm, n, :junction, j)["p_min"]
    i_pmax = ref(gm, n, :junction, i)["p_max"]
    i_pmin = ref(gm, n, :junction, i)["p_min"]
    type = get(compressor, "directionality", 0)

    constraint_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, i_pmin, i_pmax, j_pmin, j_pmax, type)
end

"Template: Constraints on the compressor energy"
function constraint_compressor_energy_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :ne_compressor, k)
    power_max = compressor["power_max"]
    gamma = get_specific_heat_capacity_ratio(gm.data)
    m = _calc_compressor_m_sqr(gamma, compressor)
    T = get_temperature(gm.data)
    G = get_gas_specific_gravity(gm.data)
    work = _calc_compressor_work(gamma, G, T)
    flow_max = max(abs(compressor["flow_max"]), abs(compressor["flow_min"]))
    ratio_max = compressor["c_ratio_max"]

    constraint_compressor_energy_ne(gm, n, k, power_max, m, work, flow_max, ratio_max)
end

"Template: Constraints on the compressor ratio value"
function constraint_compressor_ratio_value(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :compressor, k)
    i = compressor["fr_junction"]
    j = compressor["to_junction"]
    i_pmax = ref(gm, n, :junction, i)["p_max"]
    j_pmax = ref(gm, n, :junction, j)["p_max"]
    type = get(compressor, "directionality", 0)
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    constraint_compressor_ratio_value(gm, n, k, i, j, type, i_pmax, j_pmax, min_ratio, max_ratio)
end

"Template: Constraints on the ne_compressor ratio value"
function constraint_compressor_ratio_value_ne(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :ne_compressor, k)
    i = compressor["fr_junction"]
    j = compressor["to_junction"]
    type = get(compressor, "directionality", 0)
    max_ratio = compressor["c_ratio_max"]
    min_ratio = compressor["c_ratio_min"]
    i_pmax = ref(gm, n, :junction, i)["p_max"]
    j_pmax = ref(gm, n, :junction, j)["p_max"]
    constraint_compressor_ratio_value_ne(gm, n, k, i, j, type, i_pmax, j_pmax, min_ratio,  max_ratio)
end

"Template: Constraints on the compressor energy"
function constraint_compressor_energy(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :compressor, k)
    power_max = compressor["power_max"]
    gamma = get_specific_heat_capacity_ratio(gm.data)
    m = _calc_compressor_m_sqr(gamma, compressor)
    T = get_temperature(gm.data)
    G = get_gas_specific_gravity(gm.data)
    work = _calc_compressor_work(gamma, G, T)
    flow_max = max(abs(compressor["flow_max"]), abs(compressor["flow_min"]))
    ratio_max = compressor["c_ratio_max"]
    constraint_compressor_energy(gm, n, k, power_max, m, work, flow_max, ratio_max)
end

"Template: Constraints to support the proxy for minimizing the compressor power"
function constraint_compressor_minpower_proxy(gm::AbstractGasModel, k; n::Int = nw_id_default)
    compressor = ref(gm, n, :compressor, k)
    i = compressor["fr_junction"]
    j = compressor["to_junction"]

    constraint_compressor_minpower_proxy(gm, n, k, i, j)
end
#################################################################################################
# Templates for control valves
#################################################################################################

"Template: constraints on flow across control valves with on/off direction variables"
function constraint_on_off_regulator_mass_flow(gm::AbstractGasModel, k; n::Int = nw_id_default)
    valve = ref(gm, n, :regulator, k)
    f_min = valve["flow_min"]
    f_max = valve["flow_max"]

    constraint_on_off_regulator_mass_flow(gm, n, k, f_min, f_max)
end


"Constraint Enforces pressure changes bounds that obey decompression ratios for"
function constraint_on_off_regulator_pressure(gm::AbstractGasModel, k; n::Int = nw_id_default)
    regulator = ref(gm, n, :regulator, k)
    i = regulator["fr_junction"]
    j = regulator["to_junction"]
    max_ratio = regulator["reduction_factor_max"]
    min_ratio = regulator["reduction_factor_min"]
    j_pmin = ref(gm, n, :junction, j)["p_min"]
    j_pmax = ref(gm, n, :junction, j)["p_max"]
    i_pmax = ref(gm, n, :junction, i)["p_max"]
    i_pmin = ref(gm, n, :junction, i)["p_min"]
    f_min = regulator["flow_min"]

    constraint_on_off_regulator_pressure(gm, n, k, i, j, min_ratio, max_ratio, f_min, i_pmin, i_pmax, j_pmin, j_pmax)
end
