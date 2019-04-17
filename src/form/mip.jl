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


#################################################################################################
### Variables
#################################################################################################


function variable_connection_direction(gm::GenericGasModel{T}, n::Int=gm.cnw; connection=gm.ref[:nw][n][:connection]) where T <: AbstractMIPForm
    "dummy integer variable in case we need it"
    gm.var[:nw][n][:yp] = @variable(gm.model, [l in [0]], category = :Bin, basename="$(n)_yp", lowerbound=0, upperbound=1)
end

function variable_connection_direction_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; ne_connection=gm.ref[:nw][n][:ne_connection]) where T <: AbstractMIPForm
end

function variable_pressure_sqr(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMIPForm
end

######################################################################################################
## Constraints
######################################################################################################
function constraint_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_pipe_flow(gm, i)
end

function constraint_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_pipe_flow(gm, i)
end

function constraint_new_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_pipe_ne(gm, i)
end

function constraint_on_off_pipe_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w) where T <: AbstractMIPForm
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_pipe_flow1, k, @constraint(gm.model, -min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f))
    add_constraint(gm, n, :on_off_pipe_flow2, k, @constraint(gm.model, f <= min(mf, sqrt(w*max(pd_max, abs(pd_min))))))
end

function constraint_compressor_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_compressor_flow(gm, i)
end

function constraint_on_off_compressor_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIPForm
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction1, k, @constraint(gm.model, -mf <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction2, k, @constraint(gm.model, f <= mf))
end

function constraint_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_valve_flow(gm, i)
end

function constraint_on_off_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIPForm
    add_constraint(gm, n,:on_off_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end

function constraint_short_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_short_pipe_flow(gm, i)
end

function constraint_on_off_short_pipe_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIPForm
    f = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_short_pipe_flow1, k, @constraint(gm.model, -mf <= f))
    add_constraint(gm, n, :on_off_short_pipe_flow2, k, @constraint(gm.model, f <= mf))
end

function constraint_control_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_control_valve_flow(gm, i)
end

function constraint_on_off_control_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIPForm
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n, :on_off_control_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f ))
    add_constraint(gm, n, :on_off_control_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end

function constraint_junction_mass_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_junction_mass_flow_balance(gm, n, i)
end

function constraint_junction_mass_flow_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_junction_mass_flow_balance_ls(gm, n, i)
end

function constraint_junction_mass_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_junction_mass_flow_balance_ne(gm, n, i)
end

function constraint_junction_mass_flow_ne_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
end










function constraint_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_pipe_flow_directed(gm, i)
end

function constraint_new_pipe_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_pipe_flow_ne_directed(gm, i)
end

function constraint_short_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_short_pipe_flow_directed(gm, i)
end

function constraint_compressor_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_compressor_flow_directed(gm, i)
end

function constraint_new_compressor_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_compressor_flow_ne_directed(gm, i)
end

function constraint_compressor_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_compressor_flow_directed(gm, i)
end

function constraint_valve_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_valve_flow_directed(gm, i)
end

function constraint_control_valve_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_control_valve_flow_directed(gm, i)
end

function constraint_control_valve_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
    constraint_on_off_control_valve_flow_directed(gm, i)
end
