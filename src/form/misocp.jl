# Define MISOCP implementations of Gas Models

export 
    MISOCPGasModel, StandardMISOCPForm

""
@compat abstract type AbstractMISOCPForm <: AbstractGasFormulation end

""
@compat abstract type StandardMISOCPForm <: AbstractMISOCPForm end

const MISOCPGasModel = GenericGasModel{StandardMISOCPForm}

"default MISOCP constructor"
MISOCPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMISOCPForm; kwargs...)

""
function variable_flux{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_flow] 
    if bounded  
        gm.var[:nw][n][:l] = @variable(gm.model, [i in [collect(keys(gm.ref[:nw][n][:pipe])); collect(keys(gm.ref[:nw][n][:resistor])) ]], basename="l", lowerbound=0.0, upperbound=1/gm.ref[:nw][n][:connection][i]["resistance"] * max_flow^2, start = getstart(gm.ref[:nw][n][:connection], i, "l_start", 0))  
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="f", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))                        
    else
        gm.var[:nw][n][:l] = @variable(gm.model, [i in [collect(keys(gm.ref[:nw][n][:pipe])); collect(keys(gm.ref[:nw][n][:resistor])) ]], basename="l", start = getstart(gm.ref[:nw][n][:connection], i, "l_start", 0))  
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], basename="f", start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))                             
    end
end

""
function variable_flux_ne{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    max_flow = gm.ref[:nw][n][:max_flow]
    if bounded   
        gm.var[:nw][n][:l_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], basename="l_ne", lowerbound=0.0, upperbound=1/gm.ref[:nw][n][:ne_connection][i]["resistance"] * max_flow^2, start = getstart(gm.ref[:nw][n][:ne_connection], i, "l_start", 0))      
        gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="f_ne", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))                        
    else
        gm.var[:nw][n][:l_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], basename="l_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "l_start", 0))      
        gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], basename="f_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))                              
    end
end

" Weymouth equation with discrete direction variables "
function constraint_weymouth{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, n::Int, pipe_idx, i_junction_idx, j_junction_idx, max_flow, w, pd_min, pd_max)  
    pi = gm.var[:nw][n][:p][i_junction_idx] 
    pj = gm.var[:nw][n][:p][j_junction_idx] 
    yp = gm.var[:nw][n][:yp][pipe_idx] 
    yn = gm.var[:nw][n][:yn][pipe_idx]     
    l  = gm.var[:nw][n][:l][pipe_idx] 
    f  = gm.var[:nw][n][:f][pipe_idx]
            
    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, w*l >= f^2)
      
    if !haskey(gm.con[:nw][n], :weymouth1)
        gm.con[:nw][n][:weymouth1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth4] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.con[:nw][n][:weymouth1][pipe_idx] = c1              
    gm.con[:nw][n][:weymouth2][pipe_idx] = c2
    gm.con[:nw][n][:weymouth3][pipe_idx] = c3              
    gm.con[:nw][n][:weymouth4][pipe_idx] = c4                              
    gm.con[:nw][n][:weymouth5][pipe_idx] = c5                                    
end

"Weymouth equation with fixed direction"
function constraint_weymouth_fixed_direction{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, n::Int, pipe_idx,i_junction_idx, j_junction_idx, max_flow, w, pd_min, pd_max, yp, yn)  
    pi = gm.var[:nw][n][:p][i_junction_idx] 
    pj = gm.var[:nw][n][:p][j_junction_idx] 
    l  = gm.var[:nw][n][:l][pipe_idx] 
    f  = gm.var[:nw][n][:f][pipe_idx] 
            
    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, w*l >= f^2)
      
    if !haskey(gm.con[:nw][n], :weymouth_fixed_direction1)
        gm.con[:nw][n][:weymouth_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.con[:nw][n][:weymouth_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_fixed_direction4] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:weymouth_fixed_direction5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.con[:nw][n][:weymouth_fixed_direction1][pipe_idx] = c1              
    gm.con[:nw][n][:weymouth_fixed_direction2][pipe_idx] = c2
    gm.con[:nw][n][:weymouth_fixed_direction3][pipe_idx] = c3              
    gm.con[:nw][n][:weymouth_fixed_direction4][pipe_idx] = c4                              
    gm.con[:nw][n][:weymouth_fixed_direction5][pipe_idx] = c5                                    
end


