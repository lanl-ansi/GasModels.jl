"""
Topology and index mapping utilities for Inner Approximation.

This module handles the mapping between network components and matrix indices
for assembling the linearized system J⋆Δx = R⋆Δu + r(Δx, Δu).
"""


"""
    build_ia_state_map(gm, n)

Build mapping from state variables to matrix row/column indices.
State vector: [pipe flows, compressor flows, non-slack junction pressures]

**Important**: Indices must be sorted consistently to match constraint ordering.

Returns Dict with structure:
    :pipe_flow => Dict(pipe_id => state_index)
    :compressor_flow => Dict(comp_id => state_index)
    :junction_psqr => Dict(junction_id => state_index)
    :dim => total_state_dimension
"""
function build_ia_state_map(gm::AbstractGasModel, n::Int=nw_id_default)
    state_map = Dict{Symbol, Any}()
    idx = 1

    # Pipe flows (sorted by ID for consistency)
    state_map[:pipe_flow] = Dict{Int,Int}()
    for k in sort(collect(keys(ref(gm, n, :pipe))))
        state_map[:pipe_flow][k] = idx
        idx += 1
    end

    # Compressor flows (sorted by ID)
    state_map[:compressor_flow] = Dict{Int,Int}()
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        state_map[:compressor_flow][k] = idx
        idx += 1
    end

    # Non-slack junction squared pressures (sorted by ID)
    state_map[:junction_psqr] = Dict{Int,Int}()
    junctions = ref(gm, n, :junction)
    for k in sort(collect(keys(junctions)))
        junction = junctions[k]
        if junction["junction_type"] != 1  # Not slack
            state_map[:junction_psqr][k] = idx
            idx += 1
        end
    end

    state_map[:dim] = idx - 1
    return state_map
end


"""
    build_ia_input_map(gm, n)

Build mapping from input variables to matrix column indices.
Input vector: [compressor ratios, receipts, deliveries, transfers, storage]

Returns Dict with structure:
    :compressor_ratio => Dict(comp_id => input_index)
    :receipt => Dict(receipt_id => input_index)
    :delivery => Dict(delivery_id => input_index)
    :transfer => Dict(transfer_id => input_index)
    :storage => Dict(storage_id => input_index)
    :dim => total_input_dimension
"""
function build_ia_input_map(gm::AbstractGasModel, n::Int=nw_id_default)
    input_map = Dict{Symbol, Any}()
    idx = 1

    # Compressor ratios (sorted by ID)
    input_map[:compressor_ratio] = Dict{Int,Int}()
    for k in sort(collect(keys(ref(gm, n, :compressor))))
        input_map[:compressor_ratio][k] = idx
        idx += 1
    end

    # Dispatchable receipts (sorted by ID)
    input_map[:receipt] = Dict{Int,Int}()
    for k in sort(collect(ids(gm, n, :dispatchable_receipt)))
        input_map[:receipt][k] = idx
        idx += 1
    end

    # Dispatchable deliveries (sorted by ID)
    input_map[:delivery] = Dict{Int,Int}()
    for k in sort(collect(ids(gm, n, :dispatchable_delivery)))
        input_map[:delivery][k] = idx
        idx += 1
    end

    # Dispatchable transfers (sorted by ID)
    input_map[:transfer] = Dict{Int,Int}()
    for k in sort(collect(ids(gm, n, :dispatchable_transfer)))
        input_map[:transfer][k] = idx
        idx += 1
    end

    # Storage (sorted by ID)
    input_map[:storage] = Dict{Int,Int}()
    for k in sort(collect(ids(gm, n, :storage)))
        input_map[:storage][k] = idx
        idx += 1
    end

    input_map[:dim] = idx - 1
    return input_map
end


"""
    get_state_index(state_map, component_type, component_id)

Helper to retrieve state index for a component.
Returns nothing if component is not in state vector (e.g., slack junction).

Example:
    pi_idx = get_state_index(state_map, :junction_psqr, 2)
"""
function get_state_index(state_map::Dict, component_type::Symbol, component_id::Int)
    return get(get(state_map, component_type, Dict()), component_id, nothing)
end


"""
    get_input_index(input_map, component_type, component_id)

Helper to retrieve input index for a component.
Returns nothing if component is not in input vector.

Example:
    d_idx = get_input_index(input_map, :delivery, 3)
"""
function get_input_index(input_map::Dict, component_type::Symbol, component_id::Int)
    return get(get(input_map, component_type, Dict()), component_id, nothing)
end
