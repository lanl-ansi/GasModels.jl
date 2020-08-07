######################################################################################
# Constraints associated witn cutting planes on the direction variables
######################################################################################

"Template: Constraints for ensuring that at least one direction is set to take flow away from a junction (typically used on source nodes)"
function constraint_source_flow(gm::AbstractMIModels, i; n::Int=gm.cnw)
    f_pipes          = ref(gm,n,:pipes_fr,i)
    t_pipes          = ref(gm,n,:pipes_to,i)
    f_compressors    = ref(gm,n,:compressors_fr,i)
    t_compressors    = ref(gm,n,:compressors_to,i)
    f_resistors      = ref(gm,n,:resistors_fr,i)
    t_resistors      = ref(gm,n,:resistors_to,i)
    f_loss_resistors = ref(gm,n,:loss_resistors_fr,i)
    t_loss_resistors = ref(gm,n,:loss_resistors_to,i)
    f_short_pipes    = ref(gm,n,:short_pipes_fr,i)
    t_short_pipes    = ref(gm,n,:short_pipes_to,i)
    f_valves         = ref(gm,n,:valves_fr,i)
    t_valves         = ref(gm,n,:valves_to,i)
    f_regulators     = ref(gm,n,:regulators_fr,i)
    t_regulators     = ref(gm,n,:regulators_to,i)

    constraint_source_flow(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators)
end


"Template: Constraints for ensuring that at least one direction is set to take flow away from a junction (typically used on source nodes)"
function constraint_source_flow_ne(gm::AbstractMIModels, i; n::Int=gm.cnw)
    f_pipes           = ref(gm,n,:pipes_fr,i)
    t_pipes           = ref(gm,n,:pipes_to,i)
    f_compressors     = ref(gm,n,:compressors_fr,i)
    t_compressors     = ref(gm,n,:compressors_to,i)
    f_resistors       = ref(gm,n,:resistors_fr,i)
    t_resistors       = ref(gm,n,:resistors_to,i)
    f_loss_resistors  = ref(gm,n,:loss_resistors_fr,i)
    t_loss_resistors  = ref(gm,n,:loss_resistors_to,i)
    f_short_pipes     = ref(gm,n,:short_pipes_fr,i)
    t_short_pipes     = ref(gm,n,:short_pipes_to,i)
    f_valves          = ref(gm,n,:valves_fr,i)
    t_valves          = ref(gm,n,:valves_to,i)
    f_regulators      = ref(gm,n,:regulators_fr,i)
    t_regulators      = ref(gm,n,:regulators_to,i)
    ne_pipes_fr       = ref(gm,n,:ne_pipes_fr,i)
    ne_pipes_to       = ref(gm,n,:ne_pipes_to,i)
    ne_compressors_fr = ref(gm,n,:ne_compressors_fr,i)
    ne_compressors_to = ref(gm,n,:ne_compressors_to,i)

    constraint_source_flow_ne(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, ne_pipes_fr, ne_pipes_to, ne_compressors_fr, ne_compressors_to)
end


"Template: Constraints for ensuring that at least one direction is set to take flow away from a junction (typically used on sink nodes)"
function constraint_sink_flow(gm::AbstractMIModels, i; n::Int=gm.cnw)
    f_pipes          = ref(gm,n,:pipes_fr,i)
    t_pipes          = ref(gm,n,:pipes_to,i)
    f_compressors    = ref(gm,n,:compressors_fr,i)
    t_compressors    = ref(gm,n,:compressors_to,i)
    f_resistors      = ref(gm,n,:resistors_fr,i)
    t_resistors      = ref(gm,n,:resistors_to,i)
    f_loss_resistors = ref(gm,n,:loss_resistors_fr,i)
    t_loss_resistors = ref(gm,n,:loss_resistors_to,i)
    f_short_pipes    = ref(gm,n,:short_pipes_fr,i)
    t_short_pipes    = ref(gm,n,:short_pipes_to,i)
    f_valves         = ref(gm,n,:valves_fr,i)
    t_valves         = ref(gm,n,:valves_to,i)
    f_regulators     = ref(gm,n,:regulators_fr,i)
    t_regulators     = ref(gm,n,:regulators_to,i)

    constraint_sink_flow(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators)
end


"Template: Constraints for ensuring that at least one direction is set to take flow away from a junction (typically used on sink nodes)"
function constraint_sink_flow_ne(gm::AbstractMIModels, i; n::Int=gm.cnw)
    f_pipes           = ref(gm,n,:pipes_fr,i)
    t_pipes           = ref(gm,n,:pipes_to,i)
    f_compressors     = ref(gm,n,:compressors_fr,i)
    t_compressors     = ref(gm,n,:compressors_to,i)
    f_resistors       = ref(gm,n,:resistors_fr,i)
    t_resistors       = ref(gm,n,:resistors_to,i)
    f_loss_resistors  = ref(gm,n,:loss_resistors_fr,i)
    t_loss_resistors  = ref(gm,n,:loss_resistors_to,i)
    f_short_pipes     = ref(gm,n,:short_pipes_fr,i)
    t_short_pipes     = ref(gm,n,:short_pipes_to,i)
    f_valves          = ref(gm,n,:valves_fr,i)
    t_valves          = ref(gm,n,:valves_to,i)
    f_regulators      = ref(gm,n,:regulators_fr,i)
    t_regulators      = ref(gm,n,:regulators_to,i)
    ne_pipes_fr       = ref(gm,n,:ne_pipes_fr,i)
    ne_pipes_to       = ref(gm,n,:ne_pipes_to,i)
    ne_compressors_fr = ref(gm,n,:ne_compressors_fr,i)
    ne_compressors_to = ref(gm,n,:ne_compressors_to,i)

    constraint_sink_flow_ne(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, ne_pipes_fr, ne_pipes_to, ne_compressors_fr, ne_compressors_to)
end


" Template: Constraints to ensure that flow is the same direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    f_pipes          = Dict(i => ref(gm,n,:pipe,i)["to_junction"] for i in ref(gm,n,:pipes_fr,idx))
    t_pipes          = Dict(i => ref(gm,n,:pipe,i)["fr_junction"] for i in ref(gm,n,:pipes_to,idx))
    f_compressors    = Dict(i => ref(gm,n,:compressor,i)["to_junction"] for i in ref(gm,n,:compressors_fr,idx))
    t_compressors    = Dict(i => ref(gm,n,:compressor,i)["fr_junction"] for i in ref(gm,n,:compressors_to,idx))
    f_resistors      = Dict(i => ref(gm,n,:resistor,i)["to_junction"] for i in ref(gm,n,:resistors_fr,idx))
    t_resistors      = Dict(i => ref(gm,n,:resistor,i)["fr_junction"] for i in ref(gm,n,:resistors_to,idx))
    f_loss_resistors = Dict(i => ref(gm,n,:loss_resistor,i)["to_junction"] for i in ref(gm,n,:loss_resistors_fr,idx))
    t_loss_resistors = Dict(i => ref(gm,n,:loss_resistor,i)["fr_junction"] for i in ref(gm,n,:loss_resistors_to,idx))
    f_short_pipes    = Dict(i => ref(gm,n,:short_pipe,i)["to_junction"] for i in ref(gm,n,:short_pipes_fr,idx))
    t_short_pipes    = Dict(i => ref(gm,n,:short_pipe,i)["fr_junction"] for i in ref(gm,n,:short_pipes_to,idx))
    f_valves         = Dict(i => ref(gm,n,:valve,i)["to_junction"] for i in ref(gm,n,:valves_fr,idx))
    t_valves         = Dict(i => ref(gm,n,:valve,i)["fr_junction"] for i in ref(gm,n,:valves_to,idx))
    f_regulators     = Dict(i => ref(gm,n,:regulator,i)["to_junction"] for i in ref(gm,n,:regulators_fr,idx))
    t_regulators     = Dict(i => ref(gm,n,:regulator,i)["fr_junction"] for i in ref(gm,n,:regulators_to,idx))

    constraint_conserve_flow(gm, n, idx, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators)
end


"Template: Constraints to ensure that flow is the same direction through a node with degree 2 and no production or consumption"
function constraint_conserve_flow_ne(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    f_pipes           = Dict(i => ref(gm,n,:pipe,i)["to_junction"] for i in ref(gm,n,:pipes_fr,idx))
    t_pipes           = Dict(i => ref(gm,n,:pipe,i)["fr_junction"] for i in ref(gm,n,:pipes_to,idx))
    f_compressors     = Dict(i => ref(gm,n,:compressor,i)["to_junction"] for i in ref(gm,n,:compressors_fr,idx))
    t_compressors     = Dict(i => ref(gm,n,:compressor,i)["fr_junction"] for i in ref(gm,n,:compressors_to,idx))
    f_resistors       = Dict(i => ref(gm,n,:resistor,i)["to_junction"] for i in ref(gm,n,:resistors_fr,idx))
    t_resistors       = Dict(i => ref(gm,n,:resistor,i)["fr_junction"] for i in ref(gm,n,:resistors_to,idx))
    f_loss_resistors  = Dict(i => ref(gm,n,:loss_resistor,i)["to_junction"] for i in ref(gm,n,:loss_resistors_fr,idx))
    t_loss_resistors  = Dict(i => ref(gm,n,:loss_resistor,i)["fr_junction"] for i in ref(gm,n,:loss_resistors_to,idx))
    f_short_pipes     = Dict(i => ref(gm,n,:short_pipe,i)["to_junction"] for i in ref(gm,n,:short_pipes_fr,idx))
    t_short_pipes     = Dict(i => ref(gm,n,:short_pipe,i)["fr_junction"] for i in ref(gm,n,:short_pipes_to,idx))
    f_valves          = Dict(i => ref(gm,n,:valve,i)["to_junction"] for i in ref(gm,n,:valves_fr,idx))
    t_valves          = Dict(i => ref(gm,n,:valve,i)["fr_junction"] for i in ref(gm,n,:valves_to,idx))
    f_regulators      = Dict(i => ref(gm,n,:regulator,i)["to_junction"] for i in ref(gm,n,:regulators_fr,idx))
    t_regulators      = Dict(i => ref(gm,n,:regulator,i)["fr_junction"] for i in ref(gm,n,:regulators_to,idx))
    ne_pipes_fr       = Dict(i => ref(gm,n,:ne_pipe,i)["to_junction"] for i in ref(gm,n,:ne_pipes_fr,idx))
    ne_pipes_to       = Dict(i => ref(gm,n,:ne_pipe,i)["fr_junction"] for i in ref(gm,n,:ne_pipes_to,idx))
    ne_compressors_fr = Dict(i => ref(gm,n,:ne_compressor,i)["to_junction"] for i in ref(gm,n,:ne_compressors_fr,idx))
    ne_compressors_to = Dict(i => ref(gm,n,:ne_compressor,i)["fr_junction"] for i in ref(gm,n,:ne_compressors_to,idx))

    constraint_conserve_flow_ne(gm, n, idx, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors,
                                    t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators,
                                    t_regulators, ne_pipes_fr, ne_pipes_to, ne_compressors_fr, ne_compressors_to)

end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for ne_pipe"
function constraint_ne_pipe_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    pipe = ref(gm,n,:ne_pipe, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators, aligned_ne_pipes, opposite_ne_pipes, aligned_ne_compressors, opposite_ne_compressors =
           _calc_parallel_ne_connections(gm, n, pipe)

    if num_connections <= 1
        return nothing
    end

    constraint_ne_pipe_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators, aligned_ne_pipes, opposite_ne_pipes,
                                     aligned_ne_compressors, opposite_ne_compressors)
end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for ne_compressor"
function constraint_ne_compressor_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    compressor = ref(gm,n,:ne_compressor, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators, aligned_ne_pipes, opposite_ne_pipes, aligned_ne_compressors, opposite_ne_compressors =
           _calc_parallel_ne_connections(gm, n, compressor)

    if num_connections <= 1
        return nothing
    end

    constraint_ne_compressor_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes,
                                     aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators, aligned_ne_pipes, opposite_ne_pipes, aligned_ne_compressors, opposite_ne_compressors)
end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for pipe"
function constraint_pipe_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    pipe = ref(gm,n,:pipe, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators =
           _calc_parallel_connections(gm, n, pipe)

    if num_connections <= 1
        return nothing
    end

    constraint_pipe_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators)
end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for compressor"
function constraint_compressor_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    compressor = ref(gm,n,:compressor, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators =
           _calc_parallel_connections(gm, n, compressor)

    if num_connections <= 1
        return nothing
    end

    constraint_compressor_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators)
end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for short pipe"
function constraint_short_pipe_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    pipe = ref(gm,n,:short_pipe, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators =
           _calc_parallel_connections(gm, n, pipe)

    if num_connections <= 1
        return nothing
    end

    constraint_short_pipe_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators)
end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for resistor"
function constraint_resistor_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    resistor = ref(gm,n,:resistor, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators =
           _calc_parallel_connections(gm, n, resistor)

    if num_connections <= 1
        return nothing
    end

    constraint_resistor_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators)
end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for valve"
function constraint_valve_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    valve = ref(gm,n,:valve, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators =
           _calc_parallel_connections(gm, n, valve)

    if num_connections <= 1
        return nothing
    end

    constraint_valve_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators)
end


"Template: Constraints which ensure that parallel lines have flow in the same direction - customized for control valve"
function constraint_regulator_parallel_flow(gm::AbstractMIModels, idx; n::Int=gm.cnw)
    valve = ref(gm,n,:regulator, idx)
    num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
           aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
           aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
           aligned_regulators, opposite_regulators =
           _calc_parallel_connections(gm, n, valve)

    if num_connections <= 1
        return nothing
    end

    constraint_regulator_parallel_flow(gm, n, idx, num_connections, aligned_pipes, opposite_pipes, aligned_compressors, opposite_compressors,
                                     aligned_resistors, opposite_resistors, aligned_loss_resistors, opposite_loss_resistors,
                                     aligned_short_pipes, opposite_short_pipes, aligned_valves, opposite_valves,
                                     aligned_regulators, opposite_regulators)
end
