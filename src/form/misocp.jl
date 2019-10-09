# Define MISOCP implementations of Gas Models

"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractMISOCPModel, n::Int=gm.cnw; bounded::Bool=true)
    variable_pressure_difference(gm, n; bounded=bounded)
    variable_mass_flow(gm, n; bounded=bounded)
    variable_connection_direction(gm, n)
end


"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_directed(gm::AbstractMISOCPModel, n::Int=gm.cnw; bounded::Bool=true, pipe=ref(gm, n, :undirected_pipe), compressor=ref(gm, n, :undirected_compressor), resistor=ref(gm, n, :undirected_resistor), short_pipe=ref(gm, n, :undirected_short_pipe), valve=ref(gm, n, :undirected_valve), control_valve=ref(gm, n, :undirected_control_valve))
    variable_pressure_difference(gm, n; bounded=bounded)
    variable_mass_flow(gm, n; bounded=bounded)
    variable_connection_direction(gm, n; pipe=pipe, compressor=compressor, resistor=resistor, short_pipe=short_pipe, valve=valve, control_valve=control_valve)
end


"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::AbstractMISOCPModel, n::Int=gm.cnw; bounded::Bool=true)
    variable_pressure_difference_ne(gm, n; bounded=bounded)
    variable_mass_flow_ne(gm, n; bounded=bounded)
    variable_connection_direction_ne(gm, n)
end


"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_ne_directed(gm::AbstractMISOCPModel, n::Int=gm.cnw; bounded::Bool=true, ne_pipe=ref(gm, n, :undirected_ne_pipe), ne_compressor=ref(gm, n, :undirected_ne_compressor))
    variable_pressure_difference_ne(gm, n; bounded=bounded)
    variable_mass_flow_ne(gm, n; bounded=bounded)
    variable_connection_direction_ne(gm, n; ne_pipe=ne_pipe, ne_compressor=ne_compressor)
end


""
function variable_pressure_difference(gm::AbstractMISOCPModel, n::Int=gm.cnw; bounded::Bool=true)
    if bounded
        gm.var[:nw][n][:l_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_l_pipe", lower_bound=0.0, upper_bound=max(abs(ref(gm, n, :pipe_ref, i)[:pd_max]), abs(ref(gm, n, :pipe_ref, i)[:pd_max])), start=comp_start_value(gm.ref[:nw][n][:pipe], i, "l_start", 0))
        gm.var[:nw][n][:l_resistor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_l_resistor", lower_bound=0.0, upper_bound=max(abs(ref(gm, n, :resistor_ref, i)[:pd_min]), abs(ref(gm, n, :resistor_ref, i)[:pd_max])), start=comp_start_value(gm.ref[:nw][n][:resistor], i, "l_start", 0))
    else
        gm.var[:nw][n][:l_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_l_pipe", start=comp_start_value(gm.ref[:nw][n][:pipe], i, "l_start", 0))
        gm.var[:nw][n][:l_resistor] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_l_resistor", start=comp_start_value(gm.ref[:nw][n][:resistor], i, "l_start", 0))
    end
end


""
function variable_pressure_difference_ne(gm::AbstractMISOCPModel, n::Int=gm.cnw; bounded::Bool=true)
    max_flow = ref(gm, n, :max_mass_flow)
    if bounded
        gm.var[:nw][n][:l_ne_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_l_ne_pipe", lower_bound=0.0, upper_bound=max(abs(ref(gm, n, :ne_pipe_ref, i)[:pd_max]), abs(ref(gm, n, :ne_pipe_ref, i)[:pd_max]), 1 / ref(gm, n, :ne_pipe_ref, i)[:w] * max_flow^2), start=comp_start_value(gm.ref[:nw][n][:ne_pipe], i, "l_start", 0))
    else
        gm.var[:nw][n][:l_ne_pipe] = JuMP.@variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_l_ne_pipe", start=comp_start_value(gm.ref[:nw][n][:ne_pipe], i, "l_start", 0))
    end
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


"Constraint: constrains the ratio to be p_i * ratio = p_j"
function constraint_compressor_ratio_value(gm::AbstractMISOCPModel, n::Int, k, i, j)
    pi    = var(gm, n, :p, i)
    pj    = var(gm, n, :p, j)
    r     = var(gm, n, :r, k)

    InfrastructureModels.relaxation_product(gm.model, pi, r, pj)
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractMISOCPModel, n::Int, k, power_max, work)
end
