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

function variable_connection_direction(gm::GenericGasModel{T}, n::Int=gm.cnw; connection=gm.ref[:nw][n][:connection]) where T <: AbstractMIPForm
    "dummy integer variable in case we need it"
    gm.var[:nw][n][:yp] = @variable(gm.model, [l in [0]], category = :Bin, basename="$(n)_yp", lowerbound=0, upperbound=1)
end

function variable_connection_direction_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; ne_connection=gm.ref[:nw][n][:ne_connection]) where T <: AbstractMIPForm
end

function variable_pressure_sqr(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMIPForm
end

function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max) where T <: AbstractMIPForm
end

function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max, yp, yn) where T <: AbstractMIPForm
end

function constraint_weymouth_directed(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max, yp, yn) where T <: AbstractMIPForm
end

function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max) where T <: AbstractMIPForm
end

function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max, yp, yn) where T <: AbstractMIPForm
end

function constraint_weymouth_ne_directed(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max, yp, yn) where T <:  AbstractMIPForm
end

function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIPForm
end

function constraint_on_off_pipe_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w) where T <: AbstractMIPForm
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_pipe_flow1, k, @constraint(gm.model, -min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f))
    add_constraint(gm, n, :on_off_pipe_flow2, k, @constraint(gm.model, f <= min(mf, sqrt(w*max(pd_max, abs(pd_min))))))
end

function constraint_flow_direction_choice(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
end

function constraint_flow_direction_choice_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIPForm
end

function constraint_source_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIPForm
end

function constraint_source_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIPForm
end

function constraint_sink_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIPForm
end

function constraint_sink_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIPForm
end

function constraint_conserve_flow(gm::GenericGasModel{T}, n::Int, i, yp_first, yn_first, yp_last, yn_last) where T <: AbstractMIPForm
end

function constraint_conserve_flow_ne(gm::GenericGasModel{T}, n::Int, idx, yp_first, yn_first, yp_last, yn_last) where T <: AbstractMIPForm
end

function constraint_parallel_flow(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections) where T <: AbstractMIPForm
end

function constraint_parallel_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne) where T <: AbstractMIPForm
end

function constraint_on_off_compressor_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIPForm
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction1, k, @constraint(gm.model, -mf <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction2, k, @constraint(gm.model, f <= mf))
end

function constraint_on_off_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin) where T <: AbstractMIPForm
end
