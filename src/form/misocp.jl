# Define MISOCP implementations of Gas Models

"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_pressure_difference(gm, nw; bounded=bounded, report=report)
    variable_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_connection_direction(gm, nw; report=report)
end


"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_directed(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true, pipe=ref(gm, nw, :undirected_pipe), compressor=ref(gm, nw, :default_compressor), resistor=ref(gm, nw, :undirected_resistor), short_pipe=ref(gm, nw, :undirected_short_pipe), valve=ref(gm, nw, :valve), regulator=ref(gm, nw, :undirected_regulator))
    variable_pressure_difference(gm, nw; bounded=bounded, report=report)
    variable_mass_flow(gm, nw; bounded=bounded, report=report)
    variable_connection_direction(gm, nw; pipe=pipe, compressor=compressor, resistor=resistor, short_pipe=short_pipe, valve=valve, regulator=regulator, report=report)
end


"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_pressure_difference_ne(gm, nw; bounded=bounded, report=report)
    variable_mass_flow_ne(gm, nw; bounded=bounded, report=report)
    variable_connection_direction_ne(gm, nw; report=report)
end


"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_ne_directed(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true, ne_pipe=ref(gm, nw, :undirected_ne_pipe), ne_compressor=ref(gm, nw, :default_compressor))
    variable_pressure_difference_ne(gm, nw; bounded=bounded, report=report)
    variable_mass_flow_ne(gm, nw; bounded=bounded, report=report)
    variable_connection_direction_ne(gm, nw; ne_pipe=ne_pipe, ne_compressor=ne_compressor, report=report)
end


""
function variable_pressure_difference(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    l_pipe = gm.var[:nw][nw][:l_pipe] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:pipe])],
        base_name="$(nw)_l_pipe",
        start=comp_start_value(gm.ref[:nw][nw][:pipe], i, "l_start", 0)
    )

    l_resistor = gm.var[:nw][nw][:l_resistor] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:resistor])],
        base_name="$(nw)_l_resistor",
        start=comp_start_value(gm.ref[:nw][nw][:resistor], i, "l_start", 0)
    )

    if bounded
        for (i, pipe) in ref(gm, nw, :pipe)
            JuMP.set_lower_bound(l_pipe[i], 0.0)
            JuMP.set_upper_bound(l_pipe[i], max(abs(ref(gm, nw, :pipe, i)["pd_min"]), abs(ref(gm, nw, :pipe, i)["pd_max"])))
    end

        for (i, resistor) in ref(gm, nw, :resistor)
            JuMP.set_lower_bound(l_resistor[i], 0.0)
            JuMP.set_upper_bound(l_resistor[i], max(abs(ref(gm, nw, :resistor, i)["pd_min"]), abs(ref(gm, nw, :resistor, i)["pd_max"])))
end
    end

    report && _IM.sol_component_value(gm, nw, :pipe, :l, ids(gm, nw, :pipe), l_pipe)
    report && _IM.sol_component_value(gm, nw, :resistor, :l, ids(gm, nw, :resistor), l_resistor)
end


""
function variable_pressure_difference_ne(gm::AbstractMISOCPModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    max_flow = ref(gm, nw, :max_mass_flow)

    l_ne_pipe = gm.var[:nw][nw][:l_ne_pipe] = JuMP.@variable(gm.model,
        [i in keys(gm.ref[:nw][nw][:ne_pipe])],
        base_name="$(nw)_l_ne_pipe",
        start=comp_start_value(gm.ref[:nw][nw][:ne_pipe], i, "l_start", 0)
    )

    if bounded
        for (i, ne_pipe) in ref(gm, nw, :ne_pipe)
            JuMP.set_lower_bound(l_ne_pipe[i], 0.0)
            JuMP.set_upper_bound(l_ne_pipe[i], max(abs(ref(gm, nw, :ne_pipe, i)["pd_max"]), abs(ref(gm, nw, :ne_pipe, i)["pd_max"]), 1 / ref(gm, nw, :ne_pipe, i)["resistance"] * max_flow^2))
    end
end

    report && _IM.sol_component_value(gm, nw, :ne_pipe, :l, ids(gm, nw, :ne_pipe), l_ne_pipe)
end


"Weymouth equation for an undirected pipe"
function constraint_pipe_weymouth(gm::AbstractMISOCPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y  = var(gm, n, :y_pipe, k)
    pi = var(gm, n, :p, i)
    pj = var(gm, n, :p, j)
    l  = var(gm, n, :l_pipe, k)
    f  = var(gm, n, :f_pipe, k)

   _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, l >= pj - pi + pd_min*(2*y)))
   _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, l >= pi - pj + pd_max*(2*y-2)))
   _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
   _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
   _add_constraint!(gm, n, :weymouth5, k, JuMP.@constraint(gm.model, w*l >= f^2))

   _add_constraint!(gm, n, :weymouth6, k, JuMP.@constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2)))
   _add_constraint!(gm, n, :weymouth7, k, JuMP.@constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2)))
end


"Weymouth equation for an undirected pipe"
function constraint_resistor_weymouth(gm::AbstractMISOCPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_resistor, k)
    pi = var(gm, n, :p, i)
    pj = var(gm, n, :p, j)
    l  = var(gm, n, :l_resistor, k)
    f  = var(gm, n, :f_resistor, k)

   _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, l >= pj - pi + pd_min*(2*y)))
   _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, l >= pi - pj + pd_max*(2*y-2)))
   _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
   _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
   _add_constraint!(gm, n, :weymouth5, k, JuMP.@constraint(gm.model, l >= f^2/w))

   _add_constraint!(gm, n, :weymouth6, k, JuMP.@constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2)))
   _add_constraint!(gm, n, :weymouth7, k, JuMP.@constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2)))
end


"Weymouth equation with a pipe with one way flow"
function constraint_pipe_weymouth_directed(gm::AbstractMISOCPModel, n::Int, k, i, j, w, f_min, f_max, direction)
    pi = var(gm, n, :p, i)
    pj = var(gm, n, :p, j)
    l  = var(gm, n, :l_pipe, k)
    f  = var(gm, n, :f_pipe, k)

    _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, l == direction * (pi - pj)))
    _add_constraint!(gm, n, :weymouth5, k, JuMP.@constraint(gm.model, w*l >= f^2))
    if (direction == 1)
        _add_constraint!(gm, n, :weymouth6, k, JuMP.@constraint(gm.model, w*l <= f_max * f))
    else
        _add_constraint!(gm, n, :weymouth7, k, JuMP.@constraint(gm.model, w*l <= f_min * f))
    end
end


"Weymouth equation with a resistor with one way flow"
function constraint_resistor_weymouth_directed(gm::AbstractMISOCPModel, n::Int, k, i, j, w, f_min, f_max, direction)
    pi = var(gm, n, :p, i)
    pj = var(gm, n, :p, j)
    l  = var(gm, n, :l_resistor, k)
    f  = var(gm, n, :f_resistor, k)

    _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, l == direction * (pi - pj)))
    _add_constraint!(gm, n, :weymouth5, k, JuMP.@constraint(gm.model, w*l >= f^2))
    if (direction == 1)
        _add_constraint!(gm, n, :weymouth6, k, JuMP.@constraint(gm.model, w*l <= f_max * f))
    else
        _add_constraint!(gm, n, :weymouth7, k, JuMP.@constraint(gm.model, w*l <= f_min * f))
    end
end


"Weymouth equation for an undirected expansion pipe"
function constraint_pipe_weymouth_ne(gm::AbstractMISOCPModel, n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    y = var(gm, n, :y_ne_pipe, k)
    pi = var(gm, n, :p, i)
    pj = var(gm, n, :p, j)
    zp = var(gm, n, :zp, k)
    l  = var(gm, n, :l_ne_pipe, k)
    f  = var(gm, n, :f_ne_pipe, k)

    _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, l >= pj - pi + pd_min*(2*y)))
    _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@constraint(gm.model, l >= pi - pj + pd_max*(2*y-2)))
    _add_constraint!(gm, n, :weymouth_ne3, k, JuMP.@constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
    _add_constraint!(gm, n, :weymouth_ne4, k, JuMP.@constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
    _add_constraint!(gm, n, :weymouth_ne5, k, JuMP.@constraint(gm.model, zp*w*l >= f^2))

    _add_constraint!(gm, n, :weymouth_ne6, k, JuMP.@constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2) + (1-zp) * (abs(f_min*f_max) + f_min^2)))
    _add_constraint!(gm, n, :weymouth_ne7, k, JuMP.@constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2) + (1-zp) * (abs(f_min*f_max) + f_max^2)))
end


"Weymouth equation for expansion pipes with undirected expansion pipes"
function constraint_pipe_weymouth_ne_directed(gm::AbstractMISOCPModel, n::Int, k, i, j, w, pd_min, pd_max, f_min, f_max, direction)
    pi = var(gm, n, :p, i)
    pj = var(gm, n, :p, j)
    zp = var(gm, n, :zp, k)
    l  = var(gm, n, :l_ne_pipe, k)
    f  = var(gm, n, :f_ne_pipe, k)

    _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, l == direction * (pi - pj)))
    _add_constraint!(gm, n, :weymouth_ne5, k, JuMP.@constraint(gm.model, zp*w*l >= f^2))
    if (direction == 1)
        _add_constraint!(gm, n, :weymouth_ne6, k, JuMP.@constraint(gm.model, w*l <= f_max * f + (1-zp) * (abs(f_min*f_max) + f_min^2)))
    else
        _add_constraint!(gm, n, :weymouth_ne7, k, JuMP.@constraint(gm.model, w*l <= f_min * f + (1-zp) * (abs(f_min*f_max) + f_max^2)))
    end
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractMISOCPModel, n::Int, k, i, j)
    pi    = var(gm, n, :p, i)
    pj    = var(gm, n, :p, j)
    r     = var(gm, n, :r, k)

    _IM.relaxation_product(gm.model, pi, r, pj)
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractMISOCPModel, n::Int, k, power_max, work)
end
