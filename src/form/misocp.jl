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
function variable_flux{T <: AbstractMISOCPForm}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow] 
    gm.var[:l] = @variable(gm.model, [i in [collect(keys(gm.ref[:pipe])); collect(keys(gm.ref[:resistor])) ]], basename="l", lowerbound=0.0, upperbound=1/gm.ref[:connection][i]["resistance"] * max_flow^2, start = getstart(gm.ref[:connection], i, "l_start", 0))  
    gm.var[:f] = @variable(gm.model, [i in keys(gm.ref[:connection])], basename="f", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:connection], i, "f_start", 0))                        
end

""
function variable_flux_ne{T <: AbstractMISOCPForm}(gm::GenericGasModel{T})
    max_flow = gm.ref[:max_flow] 
    gm.var[:l_ne] = @variable(gm.model, [i in keys(gm.ref[:ne_pipe])], basename="l_ne", lowerbound=0.0, upperbound=1/gm.ref[:ne_connection][i]["resistance"] * max_flow^2, start = getstart(gm.ref[:ne_connection], i, "l_start", 0))      
    gm.var[:f_ne] = @variable(gm.model, [i in keys(gm.ref[:ne_connection])], basename="f_ne", lowerbound=-max_flow, upperbound=max_flow, start = getstart(gm.ref[:ne_connection], i, "f_start", 0))                        
end

" Weymouth equation with discrete direction variables "
function constraint_weymouth{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe_idx)  
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = gm.var[:yp][pipe_idx] 
    yn = gm.var[:yn][pipe_idx]     
    l  = gm.var[:l][pipe_idx] 
    f  = gm.var[:f][pipe_idx]
            
    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]     
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, pipe["resistance"]*l >= f^2)
      
    if !haskey(gm.constraint, :weymouth1)
        gm.constraint[:weymouth1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth4] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.constraint[:weymouth1][pipe_idx] = c1              
    gm.constraint[:weymouth2][pipe_idx] = c2
    gm.constraint[:weymouth3][pipe_idx] = c3              
    gm.constraint[:weymouth4][pipe_idx] = c4                              
    gm.constraint[:weymouth5][pipe_idx] = c5                                    
end

"Weymouth equation with fixed direction"
function constraint_weymouth_fixed_direction{T <: AbstractMISOCPForm}(gm::GenericGasModel{T}, pipe_idx)  
    pipe = gm.ref[:connection][pipe_idx]
    i_junction_idx = pipe["f_junction"]
    j_junction_idx = pipe["t_junction"]
  
    pi = gm.var[:p][i_junction_idx] 
    pj = gm.var[:p][j_junction_idx] 
    yp = pipe["yp"]
    yn = pipe["yn"]    
    l  = gm.var[:l][pipe_idx] 
    f  = gm.var[:f][pipe_idx] 
            
    pd_max = pipe["pd_max"] 
    pd_min = pipe["pd_min"]     
    max_flow = gm.ref[:max_flow]

    c1 = @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1))
    c2 = @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1))
    c3 = @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1))
    c4 = @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1))
    c5 = @constraint(gm.model, pipe["resistance"]*l >= f^2)
      
    if !haskey(gm.constraint, :weymouth_fixed_direction1)
        gm.constraint[:weymouth_fixed_direction1] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_fixed_direction2] = Dict{Int,ConstraintRef}()          
        gm.constraint[:weymouth_fixed_direction3] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_fixed_direction4] = Dict{Int,ConstraintRef}()
        gm.constraint[:weymouth_fixed_direction5] = Dict{Int,ConstraintRef}()                              
    end    
    gm.constraint[:weymouth_fixed_direction1][pipe_idx] = c1              
    gm.constraint[:weymouth_fixed_direction2][pipe_idx] = c2
    gm.constraint[:weymouth_fixed_direction3][pipe_idx] = c3              
    gm.constraint[:weymouth_fixed_direction4][pipe_idx] = c4                              
    gm.constraint[:weymouth_fixed_direction5][pipe_idx] = c5                                    
end


