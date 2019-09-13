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

"Weymouth equation with discrete direction variables "
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max) where T <: AbstractMINLPForm
    y = var(gm,n,:y,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

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

"Weymouth equation with one way direction"
function constraint_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, w, direction) where T <: AbstractMINLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

    if direction == 1
        add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, w*(pi - pj) >= f^2))
        add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, w*(pi - pj) <= f^2))
    else
        add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, w*(pj - pi) >= f^2))
        add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, w*(pj - pi) <= f^2))
    end
end

" Weymouth equation for an undirected expansion pipe "
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max) where T <: AbstractMINLPForm
    y = var(gm,n,:y_ne,k)

    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

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
function constraint_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, pd_min, pd_max, direction) where T <: AbstractMINLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

    if direction == 1
        add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, w*(pi - pj) >= f^2 + (1-zp) * w * pd_min))
        add_constraint(gm, n, :weymouth_ne2, k, @constraint(gm.model, w*(pi - pj) <= f^2 + (1-zp) * w * pd_max))
    else
        add_constraint(gm, n, :weymouth_ne3, k, @constraint(gm.model, w*(pj - pi) >= f^2 - (1-zp) * w * pd_max))
        add_constraint(gm, n, :weymouth_ne4, k, @constraint(gm.model, w*(pj - pi) <= f^2 - (1-zp) * w * pd_min))
    end
end
