# Define MISOCP implementations of Gas Models

export 
    MISOCPGasModel, StandardMISOCPForm, MISOCPDirectedGasModel, StandardMISOCPDirectedForm

""
@compat abstract type AbstractMISOCPDirectedForm <: AbstractDirectedGasFormulation end

""
@compat abstract type StandardMISOCPDirectedForm <: AbstractMISOCPDirectedForm end

""
@compat abstract type AbstractMISOCPForm <: AbstractUndirectedGasFormulation end

""
@compat abstract type StandardMISOCPForm <: AbstractMISOCPForm end

""
AbstractMISOCPForms = Union{AbstractMISOCPDirectedForm, AbstractMISOCPForm}


const MISOCPDirectedGasModel = GenericGasModel{StandardMISOCPDirectedForm}
const MISOCPGasModel = GenericGasModel{StandardMISOCPForm} # the standard MISCOP model


"default MISOCP constructor"
MISOCPDirectedGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMISOCPDirectedForm)
MISOCPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMISOCPForm)


""
function variable_flux{T <: AbstractMISOCPForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_flow] 
    resistance = Dict{Int, Float64}()
    for i in [collect(keys(gm.ref[:nw][n][:pipe])); collect(keys(gm.ref[:nw][n][:resistor]))]
        #resistance[i] = gm.ref[:nw][n][:connection][i]["resistance"]
        pipe = gm.ref[:nw][n][:connection][i]
        resistance[i] = calc_pipe_resistance(gm.data, pipe)    
    end    
            
    if bounded  
        gm.var[:nw][n][:l] = @variable(gm.model, [i in [collect(keys(gm.ref[:nw][n][:pipe])); collect(keys(gm.ref[:nw][n][:resistor])) ]], basename="l", lowerbound=0.0, upperbound=1/resistance[i] * max_flow^2, start = getstart(gm.ref[:nw][n][:connection], i, "l_start", 0))  
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="f", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))                        
    else
        gm.var[:nw][n][:l] = @variable(gm.model, [i in [collect(keys(gm.ref[:nw][n][:pipe])); collect(keys(gm.ref[:nw][n][:resistor])) ]], basename="l", start = getstart(gm.ref[:nw][n][:connection], i, "l_start", 0))  
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="f", start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))                             
    end
end

""
function variable_flux_ne{T <: AbstractMISOCPForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_flow]
    resistance = Dict{Int, Float64}()
    for i in  keys(gm.ref[:nw][n][:ne_pipe])
#        resistance[i] = gm.ref[:nw][n][:ne_connection][i]["resistance"]
        pipe =  gm.ref[:nw][n][:ne_connection][i]
        resistance[i] = calc_pipe_resistance(gm.data, pipe)  
    end    
            
    if bounded   
        gm.var[:nw][n][:l_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], basename="l_ne", lowerbound=0.0, upperbound=1/resistance[i] * max_flow^2, start = getstart(gm.ref[:nw][n][:ne_connection], i, "l_start", 0))      
        gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="f_ne", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))                        
    else
        gm.var[:nw][n][:l_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], basename="l_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "l_start", 0))      
        gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="f_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))                              
    end
end

""
function variable_flow{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_flux(gm,n; bounded=bounded)
    variable_connection_direction(gm,n)  
end

" Weymouth equation with discrete direction variables "
function constraint_weymouth{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max; kwargs...)  
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp][k] 
    yn = gm.var[:nw][n][:yn][k]     
    l  = gm.var[:nw][n][:l][k] 
    f  = gm.var[:nw][n][:f][k]
            
    if !haskey(gm.con[:nw][n], :weymouth1)
        gm.con[:nw][n][:weymouth1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth4] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.con[:nw][n][:weymouth1][k] = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))             
    gm.con[:nw][n][:weymouth2][k] = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    gm.con[:nw][n][:weymouth3][k] = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))             
    gm.con[:nw][n][:weymouth4][k] = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))                              
    gm.con[:nw][n][:weymouth5][k] = @constraint(gm.model, w*l >= f^2)                                    
end

"Weymouth equation with directed flow"
function constraint_weymouth{T <: AbstractMISOCPDirectedForm}(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max; kwargs...)  
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    l  = gm.var[:nw][n][:l][k] 
    f  = gm.var[:nw][n][:f][k]
    yp = kwargs[:yp]   
    yn = kwargs[:yn]   
            
    if !haskey(gm.con[:nw][n], :weymouth_fixed_direction1)
        gm.con[:nw][n][:weymouth1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth4] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.con[:nw][n][:weymouth1][k] = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))              
    gm.con[:nw][n][:weymouth2][k] = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    gm.con[:nw][n][:weymouth3][k] = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))              
    gm.con[:nw][n][:weymouth4][k] = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))                              
    gm.con[:nw][n][:weymouth5][k] = @constraint(gm.model, w*l >= f^2)                                    
end

"Weymouth equation with discrete direction variables for MINLP"
function constraint_weymouth_ne{T <: AbstractMISOCPForm}(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max; kwargs...)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    yp = gm.var[:nw][n][:yp_ne][k] 
    yn = gm.var[:nw][n][:yn_ne][k] 
    zp = gm.var[:nw][n][:zp][k]        
    l  = gm.var[:nw][n][:l_ne][k] 
    f  = gm.var[:nw][n][:f_ne][k] 
    
    if !haskey(gm.con[:nw][n], :weymouth_ne1)
        gm.con[:nw][n][:weymouth_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne4] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.con[:nw][n][:weymouth_ne1][k] = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))              
    gm.con[:nw][n][:weymouth_ne2][k] = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    gm.con[:nw][n][:weymouth_ne3][k] = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))              
    gm.con[:nw][n][:weymouth_ne4][k] = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))                              
    gm.con[:nw][n][:weymouth_ne5][k] = @constraint(gm.model, zp*w*l >= f^2)                                    
end

"Weymouth equation with fixed direction"
function constraint_weymouth_ne{T <: AbstractMISOCPDirectedForm}(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max; kwargs...)
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i] 
    pj = gm.var[:nw][n][:p][j] 
    zp = gm.var[:nw][n][:zp][k]        
    l  = gm.var[:nw][n][:l_ne][k] 
    f  = gm.var[:nw][n][:f_ne][k]
    yp = kwargs[:yp]   
    yn = kwargs[:yn]     
    
    if !haskey(gm.con[:nw][n], :weymouth_ne_fixed_direction1)
        gm.con[:nw][n][:weymouth_ne1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_ne3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne4] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_ne5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.con[:nw][n][:weymouth_ne1][k] = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))              
    gm.con[:nw][n][:weymouth_ne2][k] = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    gm.con[:nw][n][:weymouth_ne3][k] = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))              
    gm.con[:nw][n][:weymouth_ne4][k] = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))                              
    gm.con[:nw][n][:weymouth_ne5][k] = @constraint(gm.model, zp*w*l >= f^2)                                    
end