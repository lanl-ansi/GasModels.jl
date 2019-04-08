# Define MIP implementations of Gas Models

export
    MIPGasModel, StandardMIPForm

""
abstract type AbstractMIPForm <: AbstractGasFormulation end

""
abstract type StandardMIPForm <: AbstractMIPForm end

const MIPGasModel = GenericGasModel{StandardMIPForm} # the standard MIP model

"default MIP constructor"
MIPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMIPForm)

" Weymouth equation for an undirected pipe "
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max) where T <: AbstractMIPForm
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)

    constraint_weymouth(gm, n, k, i, j, mf, w, pd_min, pd_max, yp, yn)
end

" Weymouth equation for a pipe "
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max, yp, yn) where T <: AbstractMIPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

    println("here")

#   add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, f >= pd_min*(yp - yn + 1)))
 #  add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, f <= pd_max*(yp - yn + 1)))
   add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, f >= pd_min))
   add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, f <= pd_max))

end

"Weymouth equation with a pipe with directed flow"
function constraint_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max, yp, yn) where T <: AbstractMIPForm
    constraint_weymouth(gm, n, k, i, j, mf, w, pd_min, pd_max, yp, yn)
end

"Weymouth equation for an undirected expansion pipe"
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max) where T <: AbstractMIPForm
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)

    constraint_weymouth_ne(gm,  n, k, i, j, w, mf, pd_min, pd_max, yp, yn)
end

"Weymouth equation for an expansion pipe"
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max, yp, yn) where T <: AbstractMIPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

    add_constraint(gm, n, :weymouth_ne1, k,  @constraint(gm.model, f >= pd_min*(yp - yn + 1)))
    add_constraint(gm, n, :weymouth_ne2, k,  @constraint(gm.model, f <= pd_max*(yp - yn + 1)))
end

"Weymouth equation for expansion pipes with undirected expansion pipes"
function constraint_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max, yp, yn) where T <:  AbstractMIPForm
    constraint_weymouth_ne(gm,  n, k, i, j, w, mf, pd_min, pd_max, yp, yn)
end
