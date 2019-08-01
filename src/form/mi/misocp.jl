# Define MISOCP implementations of Gas Models

export
    MISOCPGasModel, StandardMISOCPForm

""
abstract type AbstractMISOCPForm <: AbstractGasFormulation end

""
abstract type StandardMISOCPForm <: AbstractMISOCPForm end

const MISOCPGasModel = GenericGasModel{StandardMISOCPForm} # the standard MISCOP model

"default MISOCP constructor"
MISOCPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardMISOCPForm)

""
function variable_mass_flow(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true, pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple) where T <: AbstractMISOCPForm
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    resistance = Dict{Int, Float64}()

    for (i,pipe) in gm.ref[:nw][n][:pipe]
        resistance[i] = pipe_resistance(gm.data, pipe)
    end

    for (i,pipe) in gm.ref[:nw][n][:resistor]
        resistance[i] = resistor_resistance(gm.data, pipe)
    end

    if bounded
        gm.var[:nw][n][:l] = @variable(gm.model, [i in [collect(keys(gm.ref[:nw][n][:pipe])); collect(keys(gm.ref[:nw][n][:resistor])) ]], base_name="$(n)_l", lower_bound=0.0, upper_bound=1/resistance[i] * max_flow^2, start = getstart(gm.ref[:nw][n][:connection], i, "l_start", 0))
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], base_name="$(n)_f", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))
    else
        gm.var[:nw][n][:l] = @variable(gm.model, [i in [collect(keys(gm.ref[:nw][n][:pipe])); collect(keys(gm.ref[:nw][n][:resistor])) ]], base_name="$(n)_l", start = getstart(gm.ref[:nw][n][:connection], i, "l_start", 0))
        gm.var[:nw][n][:f] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:connection])], base_name="$(n)_f", start = getstart(gm.ref[:nw][n][:connection], i, "f_start", 0))
    end
end

""
function variable_mass_flow_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true, pipe_resistance=calc_pipe_resistance_thorley, resistor_resistance=calc_resistor_resistance_simple) where T <: AbstractMISOCPForm
    max_flow = gm.ref[:nw][n][:max_mass_flow]
    resistance = Dict{Int, Float64}()
    for i in  keys(gm.ref[:nw][n][:ne_pipe])
        pipe =  gm.ref[:nw][n][:ne_pipe][i]
        resistance[i] = pipe_resistance(gm.data, pipe)
    end

    if bounded
        gm.var[:nw][n][:l_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_l_ne", lower_bound=0.0, upper_bound=1/resistance[i] * max_flow^2, start = getstart(gm.ref[:nw][n][:ne_connection], i, "l_start", 0))
        gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], base_name="$(n)_f_ne", lower_bound=-max_flow, upper_bound=max_flow, start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))
    else
        gm.var[:nw][n][:l_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_pipe])], base_name="$(n)_l_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "l_start", 0))
        gm.var[:nw][n][:f_ne] = @variable(gm.model, [i in keys(gm.ref[:nw][n][:ne_connection])], base_name="$(n)_f_ne", start = getstart(gm.ref[:nw][n][:ne_connection], i, "f_start", 0))
    end
end

" Weymouth equation for an undirected pipe "
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max) where T <: AbstractMISOCPForm
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)

    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    l  = var(gm,n,:l,k)
    f  = var(gm,n,:f,k)

   add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1)))
   add_constraint(gm, n, :weymouth2, k, @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1)))
   add_constraint(gm, n, :weymouth3, k, @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1)))
   add_constraint(gm, n, :weymouth4, k, @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1)))
   add_constraint(gm, n, :weymouth5, k, @constraint(gm.model, w*l >= f^2))
end

"Weymouth equation with a pipe with one way flow"
function constraint_weymouth_one_way(gm::GenericGasModel{T}, n::Int, k, i, j, w, yp, yn) where T <: AbstractMISOCPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    l  = var(gm,n,:l,k)
    f  = var(gm,n,:f,k)

    add_constraint(gm, n, :weymouth1, k, @constraint(gm.model, l == (yp-yn) * (pi - pj)))
    add_constraint(gm, n, :weymouth5, k, @constraint(gm.model, w*l >= f^2))
end

"Weymouth equation for an undirected expansion pipe"
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max) where T <: AbstractMISOCPForm
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)

    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    l  = var(gm,n,:l_ne,k)
    f  = var(gm,n,:f_ne,k)

    add_constraint(gm, n, :weymouth_ne1, k,  @constraint(gm.model, l >= pj - pi + pd_min*(yp - yn + 1)))
    add_constraint(gm, n, :weymouth_ne2, k,  @constraint(gm.model, l >= pi - pj + pd_max*(yp - yn - 1)))
    add_constraint(gm, n, :weymouth_ne3, k,  @constraint(gm.model, l <= pj - pi + pd_max*(yp - yn + 1)))
    add_constraint(gm, n, :weymouth_ne4, k,  @constraint(gm.model, l <= pi - pj + pd_min*(yp - yn - 1)))
    add_constraint(gm, n, :weymouth_ne5, k,  @constraint(gm.model, zp*w*l >= f^2))
end

"Weymouth equation for expansion pipes with undirected expansion pipes"
function constraint_weymouth_ne_one_way(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, yp, yn) where T <:  AbstractMISOCPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    l  = var(gm,n,:l_ne,k)
    f  = var(gm,n,:f_ne,k)

    add_constraint(gm, n, :weymouth_ne1, k, @constraint(gm.model, l == (yp-yn) * (pi - pj)))
    add_constraint(gm, n, :weymouth_ne5, k,  @constraint(gm.model, zp*w*l >= f^2))
end
