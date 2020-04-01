function constraint_slack_node_density(gm::AbstractGasModel, i::Int, nw::Int = gm.cnw)
    if !haskey(gm.con[:nw][nw], :slack_density)
        con(gm, nw)[:slack_density] = Dict{Any,JuMP.ConstraintRef}()
    end
    fixed_density = ref(gm, nw, :slack_junctions, i)["p_nominal"]
    constraint_slack_node_density(gm, nw, i, fixed_density)
end
