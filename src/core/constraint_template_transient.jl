"Template: fixing slack node density value"
function constraint_slack_junction_density(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    fixed_density = ref(gm, nw, :slack_junctions, i)["p_nominal"]
    constraint_slack_junction_density(gm, nw, i, fixed_density)
end

"Template: slack junction mass balance"
function constraint_slack_junction_mass_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw,
)
    net_injection = var(gm, nw, :net_nodal_injection)[i]
    net_edge_out_flow = var(gm, nw, :net_nodal_edge_out_flow)[i]
    constraint_slack_junction_mass_balance(gm, nw, i, net_injection, net_edge_out_flow)
end

"Template: non-slack junction mass balance"
function constraint_non_slack_junction_mass_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw,
)
    derivative = var(gm, nw, :non_slack_derivative)[i]
    net_injection = var(gm, nw, :net_nodal_injection)[i]
    net_edge_out_flow = var(gm, nw, :net_nodal_edge_out_flow)[i]
    constraint_non_slack_junction_mass_balance(
        gm,
        nw,
        i,
        derivative,
        net_injection,
        net_edge_out_flow,
    )
end

"Template: pipe physics with ideal gas assumption"
function constraint_pipe_physics_ideal(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    pipe = ref(gm, nw, :pipe, i)
    fr_junction = pipe["fr_junction"]
    to_junction = pipe["to_junction"]
    resistance = _calc_pipe_resistance_rho_phi_space(pipe, gm.ref[:base_length])
    constraint_pipe_physics_ideal(gm, nw, i, fr_junction, to_junction, resistance)
end

"Template: compressor physics"
function constraint_compressor_physics(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    compressor = ref(gm, nw, :compressor, i)
    fr_junction = compressor["fr_junction"]
    to_junction = compressor["to_junction"]
    constraint_compressor_physics(gm, nw, i, fr_junction, to_junction)
end

"Template: compressor power"
function constraint_compressor_power(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    compressor_power = var(gm, nw, :compressor_power)[i]
    power_max = ref(gm, nw, :compressor, i)["power_max"]
    constraint_compressor_power(gm, nw, i, compressor_power, power_max)
end

"Template: storage compression/pressure-reduction"
function constraint_storage_compressor_regulator(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw,
)
    storage = ref(gm, nw, :storage, i)
    junction_id = storage["junction_id"]
    constraint_storage_compressor_regulator(gm, nw, i, junction_id)
end

"Template: well momentum balance"
function constraint_storage_well_momentum_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw;
    num_discretizations::Int = 4,
)
    well = ref(gm, nw, :storage, i)
    length = well["well_depth"]
    length_per_well_segment = length / num_discretizations
    beta =
        (-2.0 * gm.ref[:base_length] * 9.8 * length_per_well_segment) /
        gm.ref[:sound_speed] / gm.ref[:sound_speed]
    resistance =
        well["well_friction_factor"] * gm.ref[:base_length] * length_per_well_segment /
        well["well_diameter"]
    constraint_storage_well_momentum_balance(
        gm,
        nw,
        num_discretizations,
        i,
        beta,
        resistance,
    )
end

"Template: well mass balance"
function constraint_storage_well_mass_balance(
    gm::AbstractGasModel,
    i::Int,
    nw::Int = gm.cnw;
    num_discretizations::Int = 4,
)
    well = ref(gm, nw, :storage, i)
    L = well["well_depth"]
    length_per_well_segment = L / num_discretizations
    constraint_storage_well_mass_balance(gm, nw, num_discretizations, i, length_per_well_segment)
end

"Template: initial condition for reservoir density"
function constraint_initial_condition_reservoir(
    gm::AbstractGasModel,
    i::Int, 
    nw::Int = gm.cnw)
    
    initial_density = ref(gm, nw, :storage, i)["initial_density"]
    constraint_initial_condition_reservoir(gm, i, nw, initial_density)
end 
