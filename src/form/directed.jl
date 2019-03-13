################
# Constraints
################















" constraints on flow across valves when directions are constants "
function constraint_on_off_valve_flow_direction(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...) where T <: AbstractDirectedGasFormulation
    kwargs = Dict(kwargs)
    f = gm.var[:nw][n][:f][k]
    v = gm.var[:nw][n][:v][k]
    yp = kwargs[:yp]
    yn = kwargs[:yn]

    if !haskey(gm.con[:nw][n], :on_off_valve_flow_direction1)
        gm.con[:nw][n][:on_off_valve_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_valve_flow_direction2] = Dict{Int,ConstraintRef}()
    end
    gm.con[:nw][n][:on_off_valve_flow_direction1][k] = @constraint(gm.model, -mf*(1-yp) <= f <= mf*(1-yn))
    gm.con[:nw][n][:on_off_valve_flow_direction2][k] = @constraint(gm.model, -mf*v <= f <= mf*v)
end

" constraints on flow across control valves when directions are constants "
function constraint_on_off_control_valve_flow_direction(gm::GenericGasModel{T}, n::Int, k, i, j, mf; kwargs...) where T <: AbstractDirectedGasFormulation
    kwargs = Dict(kwargs)
    f = gm.var[:nw][n][:f][k]
    v = gm.var[:nw][n][:v][k]
    yp = kwargs[:yp]
    yn = kwargs[:yn]

    if !haskey(gm.con[:nw][n], :on_off_control_valve_flow_direction1)
        gm.con[:nw][n][:on_off_control_valve_flow_direction1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_flow_direction2] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_flow_direction3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_flow_direction4] = Dict{Int,ConstraintRef}()
    end
    gm.con[:nw][n][:on_off_control_valve_flow_direction1][k] = @constraint(gm.model, -mf*(1-yp) <= f)
    gm.con[:nw][n][:on_off_control_valve_flow_direction2][k] = @constraint(gm.model, f <= mf*(1-yn))
    gm.con[:nw][n][:on_off_control_valve_flow_direction3][k] = @constraint(gm.model, -mf*v <= f )
    gm.con[:nw][n][:on_off_control_valve_flow_direction4][k] = @constraint(gm.model, f <= mf*v)
end

" constraints on pressure drop across control valves when directions are constants "
function constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax; kwargs...) where T <: AbstractDirectedGasFormulation
    kwargs = Dict(kwargs)
    pi = gm.var[:nw][n][:p][i]
    pj = gm.var[:nw][n][:p][j]
    v = gm.var[:nw][n][:v][k]
    yp = kwargs[:yp]
    yn = kwargs[:yn]

    if !haskey(gm.con[:nw][n], :on_off_control_valve_pressure_drop1)
        gm.con[:nw][n][:on_off_control_valve_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_pressure_drop2] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_pressure_drop3] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_control_valve_pressure_drop4] = Dict{Int,ConstraintRef}()
    end

    gm.con[:nw][n][:on_off_control_valve_pressure_drop1][k] = @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-yp-v)*j_pmax^2)
    gm.con[:nw][n][:on_off_control_valve_pressure_drop2][k] = @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-yp-v)*(i_pmax^2) )
    gm.con[:nw][n][:on_off_control_valve_pressure_drop3][k] = @constraint(gm.model,  pj - pi <= (2-yn-v)*j_pmax^2)
    gm.con[:nw][n][:on_off_control_valve_pressure_drop4][k] = @constraint(gm.model,  pi - pj <= (2-yn-v)*(i_pmax^2))
end
