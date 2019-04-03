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
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max) where T <: AbstractMINLPForm
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k) 

    constraint_weymouth(gm, n, k, i, j, mf, w, pd_min, pd_max, yp, yn)
end

"Weymouth equation with discrete direction variables "
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max, yp, yn) where T <: AbstractMINLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

    add_constraint(gm, n, :weymouth1, k, @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*mf^2))
    add_constraint(gm, n, :weymouth2, k, @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*mf^2))
    add_constraint(gm, n, :weymouth3, k, @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*mf^2))
    add_constraint(gm, n, :weymouth4, k, @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*mf^2))
end

"Weymouth equation with fixed direction"
function constraint_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, ii, j, mfw, w, pd_min, pd_max, yp, yn) where T <: AbstractMINLPForm
    constraint_weymouth(gm, n, k, i, j, mf, w, pd_min, pd_max, yp, yn)
end

" Weymouth equation for an undirected expansion pipe "
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max) where T <: AbstractMINLPForm
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)
    constraint_weymouth_ne(gm, n, k, i, j, w, mf, pd_min, pd_max, yp, yn)
end

" Weymouth equation for an uexpansion pipe "
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max, yp, yn) where T <: AbstractMINLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

    add_constraint(gm, n, :weymouth_ne1, k, @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*mf^2))
    add_constraint(gm, n, :weymouth_ne2, k, @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*mf^2))
    add_constraint(gm, n, :weymouth_ne3, k, @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*mf^2))
    add_constraint(gm, n, :weymouth_ne4, k, @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*mf^2))
end

"Weymouth equation for directed expansion pipes"
function constraint_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max, yp, yn) where T <: AbstractMINLPForm
    constraint_weymouth_ne(gm, n, k, i, j, w, mf, pd_min, pd_max, yp, yn)
end
