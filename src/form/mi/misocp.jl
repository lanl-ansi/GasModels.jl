# Define MISOCP implementations of Gas Models

export
    MISOCPGasModel, StandardMISOCPForm

""
abstract type AbstractMISOCPForm <: AbstractGasFormulation end

""
abstract type StandardMISOCPForm <: AbstractMISOCPForm end

const MISOCPGasModel = GenericGasModel{StandardMISOCPForm} # the standard MISCOP model

"default MISOCP constructor"
MISOCPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMISOCPForm)

"Variables needed for modeling flow in MI models"
function variable_flow(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMISOCPForm
    variable_pressure_difference(gm,n;bounded=bounded)
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true,pipe=ref(gm,n,:undirected_pipe),compressor=ref(gm,n,:undirected_compressor),resistor=ref(gm,n,:undirected_resistor),short_pipe=ref(gm,n,:undirected_short_pipe),valve=ref(gm,n,:undirected_valve),control_valve=ref(gm,n,:undirected_control_valve)) where T <: AbstractMISOCPForm
    variable_pressure_difference(gm,n;bounded=bounded)
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n;pipe=pipe,compressor=compressor,resistor=resistor,short_pipe=short_pipe,valve=valve,control_valve=control_valve)
end

"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMISOCPForm
    variable_pressure_difference_ne(gm,n;bounded=bounded)
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_ne_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true,ne_pipe=ref(gm,n,:undirected_ne_pipe),ne_compressor=ref(gm,n,:undirected_ne_compressor)) where T <: AbstractMISOCPForm
    variable_pressure_difference_ne(gm,n;bounded=bounded)
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n;ne_pipe=ne_pipe,ne_compressor=ne_compressor)
end

""
function variable_pressure_difference(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMISOCPForm
    if bounded
        gm.var[:nw][n][:l_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_l_pipe", lower_bound=0.0, upper_bound=max(abs(ref(gm, n, :pipe_ref, i)[:pd_max]), abs(ref(gm, n, :pipe_ref, i)[:pd_max])), start = getstart(gm.ref[:nw][n][:pipe], i, "l_start", 0))
        gm.var[:nw][n][:l_resistor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_l_resistor", lower_bound=0.0, upper_bound=max(abs(ref(gm, n, :resistor_ref, i)[:pd_min]), abs(ref(gm, n, :resistor_ref, i)[:pd_max])), start = getstart(gm.ref[:nw][n][:resistor], i, "l_start", 0))
    else
        gm.var[:nw][n][:l_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:pipe])], base_name="$(n)_l_pipe", start = getstart(gm.ref[:nw][n][:pipe], i, "l_start", 0))
        gm.var[:nw][n][:l_resistor] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:resistor])], base_name="$(n)_l_resistor", start = getstart(gm.ref[:nw][n][:resistor], i, "l_start", 0))
    end
end

""
function variable_pressure_difference_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMISOCPForm
    max_flow = ref(gm,n,:max_mass_flow)
    if bounded
        gm.var[:nw][n][:l_ne_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_l_ne_pipe", lower_bound=0.0, upper_bound=max(abs(ref(gm, n, :ne_pipe_ref, i)[:pd_max]), abs(ref(gm, n, :ne_pipe_ref, i)[:pd_max]), 1/ref(gm,n,:ne_pipe_ref,i)[:w] * max_flow^2), start = getstart(gm.ref[:nw][n][:ne_pipe], i, "l_start", 0))
    else
        gm.var[:nw][n][:l_ne_pipe] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_l_ne_pipe", start = getstart(gm.ref[:nw][n][:ne_pipe], i, "l_start", 0))
    end
end

" Weymouth equation for an undirected pipe "
function constraint_pipe_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max) where T <: AbstractMISOCPForm
    y  = var(gm,n,:y_pipe,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    l  = var(gm,n,:l_pipe,k)
    f  = var(gm,n,:f_pipe,k)

   add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, l >= pj - pi + pd_min*(2*y)))
   add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, l >= pi - pj + pd_max*(2*y-2)))
   add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
   add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
   add_constraint(gm, n, :weymouth5, k, @constraint(gm.model, w*l >= f^2))

   add_constraint(gm, n, :weymouth6, k, @constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2)))
   add_constraint(gm, n, :weymouth7, k, @constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2)))
end

" Weymouth equation for an undirected pipe "
function constraint_resistor_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max) where T <: AbstractMISOCPForm
    y = var(gm,n,:y_resistor,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    l  = var(gm,n,:l_resistor,k)
    f  = var(gm,n,:f_resistor,k)

   add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, l >= pj - pi + pd_min*(2*y)))
   add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, l >= pi - pj + pd_max*(2*y-2)))
   add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
   add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
   add_constraint(gm, n, :weymouth5, k, @constraint(gm.model, l >= f^2/w))

   add_constraint(gm, n, :weymouth6, k, @constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2)))
   add_constraint(gm, n, :weymouth7, k, @constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2)))
end

"Weymouth equation with a pipe with one way flow"
function constraint_pipe_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, f_min, f_max, direction) where T <: AbstractMISOCPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    l  = var(gm,n,:l_pipe,k)
    f  = var(gm,n,:f_pipe,k)

    add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, l == direction * (pi - pj)))
    add_constraint(gm, n, :weymouth5, k, @constraint(gm.model, w*l >= f^2))
    if (direction == 1)
        add_constraint(gm, n, :weymouth6, k, @constraint(gm.model, w*l <= f_max * f))
    else
        add_constraint(gm, n, :weymouth7, k, @constraint(gm.model, w*l <= f_min * f))
    end
end

"Weymouth equation with a resistor with one way flow"
function constraint_resistor_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, f_min, f_max, direction) where T <: AbstractMISOCPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    l  = var(gm,n,:l_resistor,k)
    f  = var(gm,n,:f_resistor,k)

    add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, l == direction * (pi - pj)))
    add_constraint(gm, n, :weymouth5, k, @constraint(gm.model, w*l >= f^2))
    if (direction == 1)
        add_constraint(gm, n, :weymouth6, k, @constraint(gm.model, w*l <= f_max * f))
    else
        add_constraint(gm, n, :weymouth7, k, @constraint(gm.model, w*l <= f_min * f))
    end
end

"Weymouth equation for an undirected expansion pipe"
function constraint_pipe_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max) where T <: AbstractMISOCPForm
    y = var(gm,n,:y_ne_pipe,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    l  = var(gm,n,:l_ne_pipe,k)
    f  = var(gm,n,:f_ne_pipe,k)

    add_constraint(gm, n, :weymouth_ne1, k,  @constraint(gm.model, l >= pj - pi + pd_min*(2*y)))
    add_constraint(gm, n, :weymouth_ne2, k,  @constraint(gm.model, l >= pi - pj + pd_max*(2*y-2)))
    add_constraint(gm, n, :weymouth_ne3, k,  @constraint(gm.model, l <= pj - pi + pd_max*(2*y)))
    add_constraint(gm, n, :weymouth_ne4, k,  @constraint(gm.model, l <= pi - pj + pd_min*(2*y-2)))
    add_constraint(gm, n, :weymouth_ne5, k,  @constraint(gm.model, zp*w*l >= f^2))

    add_constraint(gm, n, :weymouth_ne6, k, @constraint(gm.model, w*l <= f_max * f + (1-y) * (abs(f_min*f_max) + f_min^2) + (1-zp) * (abs(f_min*f_max) + f_min^2)))
    add_constraint(gm, n, :weymouth_ne7, k, @constraint(gm.model, w*l <= f_min * f + y     * (abs(f_min*f_max) + f_max^2) + (1-zp) * (abs(f_min*f_max) + f_max^2)))
end

"Weymouth equation for expansion pipes with undirected expansion pipes"
function constraint_pipe_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, pd_min, pd_max, f_min, f_max, direction) where T <:  AbstractMISOCPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    l  = var(gm,n,:l_ne_pipe,k)
    f  = var(gm,n,:f_ne_pipe,k)

    add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, l == direction * (pi - pj)))
    add_constraint(gm, n, :weymouth_ne5, k, @constraint(gm.model, zp*w*l >= f^2))
    if (direction == 1)
        add_constraint(gm, n, :weymouth_ne6, k, @constraint(gm.model, w*l <= f_max * f + (1-zp) * (abs(f_min*f_max) + f_min^2)))
    else
        add_constraint(gm, n, :weymouth_ne7, k, @constraint(gm.model, w*l <= f_min * f + (1-zp) * (abs(f_min*f_max) + f_max^2)))
    end
end

"Constraint: constrains the ratio to be p_i * ratio = p_j"
function constraint_compressor_ratio_value(gm::GenericGasModel{T}, n::Int, k, i, j) where T <: AbstractMISOCPForm
    pi    = var(gm,n,:p,i)
    pj    = var(gm,n,:p,j)
    r     = var(gm,n,:r,k)

    InfrastructureModels.relaxation_product(gm.model, pi, r, pj)
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::GenericGasModel{T}, n::Int, k, power_max) where T <: AbstractMISOCPForm
end
