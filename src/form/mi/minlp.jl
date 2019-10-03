# Define MINLP implementations of Gas Models

export
    MINLPGasModel, StandardMINLPForm

""
abstract type AbstractMINLPForm <: AbstractGasFormulation end

""
abstract type StandardMINLPForm <: AbstractMINLPForm end

const MINLPGasModel = GenericGasModel{StandardMINLPForm}

"default MINLP constructor"
MINLPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMINLPForm)

"Variables needed for modeling flow in MI models"
function variable_flow(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMINLPForm
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true,pipe=ref(gm,n,:undirected_pipe),compressor=ref(gm,n,:undirected_compressor),resistor=ref(gm,n,:undirected_resistor),short_pipe=ref(gm,n,:undirected_short_pipe),valve=ref(gm,n,:undirected_valve),control_valve=ref(gm,n,:undirected_control_valve)) where T <: AbstractMINLPForm
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n;pipe=pipe,compressor=compressor,resistor=resistor,short_pipe=short_pipe,valve=valve,control_valve=control_valve)
end

"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMINLPForm
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_ne_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true,ne_pipe=ref(gm,n,:undirected_ne_pipe),ne_compressor=ref(gm,n,:undirected_ne_compressor)) where T <: AbstractMINLPForm
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n;ne_pipe=ne_pipe,ne_compressor=ne_compressor)
end


"Weymouth equation with discrete direction variables "
function constraint_pipe_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max) where T <: AbstractMINLPForm
    y = var(gm,n,:y_pipe,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_pipe,k)

    # when y = 1, the first two equations say w*(pi - pj) == f^2.
    # This implies the third equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from i -> j, the largest value is f_max^2. Thus 2*f_max^2 is sufficient to subtract enough from f^2 to get a value < -f^2.
    # The fourth equation staets -f^2 <= f^2 which is always true.

    # when y = 0, the last two equations say w*(pj - pi) == f^2.
    # This implies the first equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from j -> i, the largest value is f_min^2. Thus 2*f_min^2 is sufficient to subtract enough from f^2 to get a value < -f^2.
    # The second equation staets -f^2 <= f^2 which is always true.

    add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, w*(pi - pj) >= f^2 - (1-y)*2*f_min^2))
    add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, w*(pi - pj) <= f^2))
    add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, w*(pj - pi) >= f^2 - y*2*f_max^2))
    add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, w*(pj - pi) <= f^2))
end

"Weymouth equation with discrete direction variables "
function constraint_resistor_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max) where T <: AbstractMINLPForm
    y = var(gm,n,:y_resistor,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_resistor,k)

    add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, w*(pi - pj) >= f^2 - (1-y)*2*f_min^2))
    add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, w*(pi - pj) <= f^2))
    add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, w*(pj - pi) >= f^2 - y*2*f_max^2))
    add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, w*(pj - pi) <= f^2))
end

"Weymouth equation with one way direction"
function constraint_pipe_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, f_min, f_max, direction) where T <: AbstractMINLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_pipe,k)

    if direction == 1
        add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, w*(pi - pj) >= f^2))
        add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, w*(pi - pj) <= f^2))
    else
        add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, w*(pj - pi) >= f^2))
        add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, w*(pj - pi) <= f^2))
    end
end

"Weymouth equation with one way direction"
function constraint_resistor_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, f_min, f_max, direction) where T <: AbstractMINLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f_resistor,k)

    if direction == 1
        add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, w*(pi - pj) >= f^2))
        add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, w*(pi - pj) <= f^2))
    else
        add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, w*(pj - pi) >= f^2))
        add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, w*(pj - pi) <= f^2))
    end
end

" Weymouth equation for an undirected expansion pipe "
function constraint_pipe_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max) where T <: AbstractMINLPForm
    y = var(gm,n,:y_ne_pipe,k)

    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne_pipe,k)

    # when zp = 0, then f = 0 and pd_min and pd_max provide sufficiently large bounds
    # when zp = 1, then we have two euqations of the form w*(pi - pj) = +/- f^2 and w*(pj - pj) = -f^2

    # when y = 1, the first two equations say w*(pi - pj) == f^2.
    # This implies the third equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from i -> j, the largest value is f_max^2. Thus 2*f_max^2 is sufficient to subtract enough from f^2 to get a value < -f^2.
    # The fourth equation staets -f^2 <= f^2 which is always true.

    # when y = 0, the last two equations say w*(pj - pi) == f^2.
    # This implies the first equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from j -> i, the largest value is f_min^2. Thus 2*f_min^2 is sufficient to subtract enough from f^2 to get a value < -f^2.
    # The second equation staets -f^2 <= f^2 which is always true.


    add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, w*(pi - pj) >= f^2 + (1-zp)*w*pd_min - (1-y)*2*f_min^2))
    add_constraint(gm, n, :weymouth_ne2, k, @constraint(gm.model, w*(pi - pj) <= f^2 + (1-zp)*w*pd_max) )
    add_constraint(gm, n, :weymouth_ne3, k, @constraint(gm.model, w*(pj - pi) >= f^2 - (1-zp)*w*pd_max - y*2*f_max^2))
    add_constraint(gm, n, :weymouth_ne4, k, @constraint(gm.model, w*(pj - pi) <= f^2 - (1-zp)*w*pd_min) )
end

"Weymouth equation for directed expansion pipes"
function constraint_pipe_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, pd_min, pd_max, f_min, f_max, direction) where T <: AbstractMINLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne_pipe,k)

    if direction == 1
        add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, w*(pi - pj) >= f^2 + (1-zp) * w * pd_min))
        add_constraint(gm, n, :weymouth_ne2, k, @constraint(gm.model, w*(pi - pj) <= f^2 + (1-zp) * w * pd_max))
    else
        add_constraint(gm, n, :weymouth_ne3, k, @constraint(gm.model, w*(pj - pi) >= f^2 - (1-zp) * w * pd_max))
        add_constraint(gm, n, :weymouth_ne4, k, @constraint(gm.model, w*(pj - pi) <= f^2 - (1-zp) * w * pd_min))
    end
end

"Constraint: constrains the ratio to be p_i * ratio = p_j"
function constraint_compressor_ratio_value(gm::GenericGasModel{T}, n::Int, k, i, j) where T <: AbstractMINLPForm
    pi    = var(gm,n,:p,i)
    pj    = var(gm,n,:p,j)
    r = var(gm,n,:r,k)
    add_constraint(gm, n, :compressor_ratio_value1, k, @constraint(gm.model, r * pi <= pj))
    add_constraint(gm, n, :compressor_ratio_value2, k, @constraint(gm.model, r * pi >= pj))
end

"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::GenericGasModel{T}, n::Int, k, power_max) where T <: AbstractMINLPForm
end
