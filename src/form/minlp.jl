# Define MINLP implementations of Gas Models

export 
    MINLPGasModel, StandardMINLPForm

""
abstract type AbstractMINLPForm <: AbstractUndirectedGasFormulation end

""
abstract type StandardMINLPForm <: AbstractMINLPForm end

""
abstract type AbstractMINLPDirectedForm <: AbstractDirectedGasFormulation end

""
abstract type StandardMINLPDirectedForm <: AbstractMINLPDirectedForm end

""
AbstractMINLPForms = Union{AbstractMINLPDirectedForm, AbstractMINLPForm}

const MINLPGasModel = GenericGasModel{StandardMINLPForm}
const MINLPGasDirectedModel = GenericGasModel{StandardMINLPDirectedForm}

"default MINLP constructor"
MINLPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMINLPForm)
MINLPGasDirectedModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMINLPDirectedForm)

"Weymouth equation with discrete direction variables "
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max; kwargs...) where T <: AbstractMINLPForm
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k] 
    f  = gm.var[:nw][n][:f][k] 
        
    if !haskey(gm.con[:nw][n], :weymouth1)
        gm.con[:nw][n][:weymouth1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth4] = Dict{Int,ConstraintRef}()          
    end
    
    gm.con[:nw][n][:weymouth1][k] = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*mf^2)              
    gm.con[:nw][n][:weymouth2][k] = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*mf^2)
    gm.con[:nw][n][:weymouth3][k] = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*mf^2)              
    gm.con[:nw][n][:weymouth4][k] = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*mf^2)                               
end

"Weymouth equation with fixed direction variables"
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, ii, j, mfw, w, pd_min, pd_max; kwargs...) where T <: AbstractMINLPDirectedForm
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    f  = gm.var[:nw][n][:f][k]
    yp = kwargs[:yp]   
    yn = kwargs[:yn]   
                 
    if !haskey(gm.con[:nw][n], :weymouth1)
        gm.con[:nw][n][:weymouth1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:weymouth1][k] = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (1-yp)*mf^2)              
    gm.con[:nw][n][:weymouth2][k] = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (1-yp)*mf^2)
    gm.con[:nw][n][:weymouth3][k] = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (1-yn)*mf^2)              
    gm.con[:nw][n][:weymouth4][k] = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (1-yn)*mf^2)                               
end

" Weymouth equation with discrete direction variables for MINLP "
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max; kwargs...) where T <: AbstractMINLPForm
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp_ne][k] 
    zp = gm.var[:nw][n][:zp][k] 
    yn = gm.var[:nw][n][:yn_ne][k] 
    f  = gm.var[:nw][n][:f_ne][k] 
          
    if !haskey(gm.con[:nw][n], :weymouth_ne1)
        gm.con[:nw][n][:weymouth_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:weymouth_ne1][k] = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*mf^2)              
    gm.con[:nw][n][:weymouth_ne2][k] = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*mf^2)
    gm.con[:nw][n][:weymouth_ne3][k] = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*mf^2)              
    gm.con[:nw][n][:weymouth_ne4][k] = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*mf^2)                               
end

"Weymouth equation with fixed directions for MINLP"
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max; kwargs...) where T <: AbstractMINLPDirectedForm
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    zp = gm.var[:nw][n][:zp][k] 
    f  = gm.var[:nw][n][:f_ne][k]
    yp = kwargs[:yp]   
    yn = kwargs[:yn] 
        
    if !haskey(gm.con[:nw][n], :weymouth_ne1)
        gm.con[:nw][n][:weymouth_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne4] = Dict{Int,ConstraintRef}()          
    end    
    gm.con[:nw][n][:weymouth_ne1][k] = @NLconstraint(gm.model, w*(pi - pj) >= f^2 - (2-yp-zp)*mf^2)              
    gm.con[:nw][n][:weymouth_ne2][k] = @NLconstraint(gm.model, w*(pi - pj) <= f^2 + (2-yp-zp)*mf^2)
    gm.con[:nw][n][:weymouth_ne3][k] = @NLconstraint(gm.model, w*(pj - pi) >= f^2 - (2-yn-zp)*mf^2)              
    gm.con[:nw][n][:weymouth_ne4][k] = @NLconstraint(gm.model, w*(pj - pi) <= f^2 + (2-yn-zp)*mf^2)                               
end
