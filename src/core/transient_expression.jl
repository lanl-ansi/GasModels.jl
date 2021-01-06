"density derivative"
function expression_density_derivative(gm::AbstractGasModel, nw::Int, nw_prev::Int)
    var(gm, nw)[:density_derivative] = Dict{Int,Any}()
    for i in ref(gm, nw, :non_slack_junction_ids)
        var(gm, nw, :density_derivative)[i] = (var(gm, nw, :density, i) - var(gm, nw_prev, :density, i)) / gm.ref[:it][gm_it_sym][:time_step]
    end
    for i in ids(gm, nw, :slack_junctions)
        var(gm, nw, :density_derivative)[i] = 0
    end
end

"density derivative for well nodal densities"
function expression_well_density_derivative(
    gm::AbstractGasModel,
    nw::Int,
    nw_next::Int;
    num_discretizations::Int = 4,
    report::Bool = true,
)
    var(gm, nw)[:well_density_derivative] = Dict{Int,Any}()
    for storage_id in ids(gm, nw, :storage)
        var(gm, nw, :well_density_derivative)[storage_id] = Dict{Int,Any}()
        for j = 1:(num_discretizations+1)
            var(gm, nw, :well_density_derivative, storage_id)[j] = (
                    var(gm, nw_next, :well_density, storage_id)[j] -
                    var(gm, nw, :well_density, storage_id)[j]
             ) / gm.ref[:it][gm_it_sym][:time_step]
        end
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :well_density_derivative,
        ids(gm, nw, :storage),
        var(gm, nw)[:well_density_derivative],
    )
end

"density derivative for storage reservoir"
function expression_reservoir_density_derivative(
    gm::AbstractGasModel,
    nw::Int,
    nw_next::Int;
    num_discretizations::Int = 4,
    report::Bool = true,
)
    var(gm, nw)[:reservoir_density_derivative] = Dict{Int,Any}()
    for storage_id in ids(gm, nw, :storage)
        var(gm, nw, :reservoir_density_derivative)[storage_id] = (
                var(gm, nw_next, :reservoir_density, storage_id) -
                var(gm, nw, :reservoir_density, storage_id)
               ) / gm.ref[:it][gm_it_sym][:time_step]
    end
    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :storage,
        :reservoir_density_derivative,
        ids(gm, nw, :storage),
        var(gm, nw)[:reservoir_density_derivative],
    )
end

"net nodal injection"
function expression_net_nodal_injection(gm::AbstractGasModel, nw::Int; report::Bool = true)
    q = var(gm, nw)[:net_nodal_injection] = Dict{Int,Any}()
    for (i, junction) in ref(gm, nw, :junction)
        var(gm, nw, :net_nodal_injection)[i] = 0
        for j in ref(gm, nw, :dispatchable_receipts_in_junction, i)
            var(gm, nw, :net_nodal_injection)[i] += var(gm, nw, :injection, j)
        end
        for j in ref(gm, nw, :dispatchable_transfers_in_junction, i)
            var(gm, nw, :net_nodal_injection)[i] -= var(gm, nw, :transfer_effective, j)
        end
        for j in ref(gm, nw, :dispatchable_deliveries_in_junction, i)
            var(gm, nw, :net_nodal_injection)[i] -= var(gm, nw, :withdrawal, j)
        end
        for j in ref(gm, nw, :nondispatchable_receipts_in_junction, i)
            var(gm, nw, :net_nodal_injection)[i] += ref(gm, nw, :receipt, j)["injection_nominal"]
        end
        for j in ref(gm, nw, :nondispatchable_transfers_in_junction, i)
            var(gm, nw, :net_nodal_injection)[i] -= ref(gm, nw, :transfer, j)["withdrawal_nominal"]
        end
        for j in ref(gm, nw, :nondispatchable_deliveries_in_junction, i)
            var(gm, nw, :net_nodal_injection)[i] -= ref(gm, nw, :delivery, j)["withdrawal_nominal"]
        end
        for j in ref(gm, nw, :storages_in_junction, i)
            var(gm, nw, :net_nodal_injection)[i] -= var(gm, nw, :well_head_flow, j)
        end
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :junction,
        :net_injection,
        ids(gm, nw, :junction),
        q,
    )
end

"net nodal edge flow out"
function expression_net_nodal_edge_out_flow(
    gm::AbstractGasModel,
    nw::Int;
    report::Bool = true,
)
    q = var(gm, nw)[:net_nodal_edge_out_flow] = Dict{Int,Any}()
    for (i, junction) in ref(gm, nw, :junction)
        var(gm, nw, :net_nodal_edge_out_flow)[i] = 0
        for j in ref(gm, nw, :pipes_fr, i)
            var(gm, nw, :net_nodal_edge_out_flow)[i] += (var(gm, nw, :pipe_flux_fr, j) * ref(gm, nw, :pipe, j)["area"])
        end
        for j in ref(gm, nw, :compressors_fr, i)
            var(gm, nw, :net_nodal_edge_out_flow)[i] += var(gm, nw, :compressor_flow, j)
        end
        for j in ref(gm, nw, :pipes_to, i)
            var(gm, nw, :net_nodal_edge_out_flow)[i] -= (var(gm, nw, :pipe_flux_to, j) * ref(gm, nw, :pipe, j)["area"])
        end
        for j in ref(gm, nw, :compressors_to, i)
            var(gm, nw, :net_nodal_edge_out_flow)[i] -= var(gm, nw, :compressor_flow, j)
        end
    end
    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :junction,
        :net_nodal_edge_out_flow,
        ids(gm, nw, :junction),
        q,
    )
end

"non slack affine derivative"
function expression_non_slack_affine_derivative(
    gm::AbstractGasModel,
    nw::Int;
    report::Bool = true,
)
    var(gm, nw)[:non_slack_derivative] = Dict{Int,Any}()
    for i in ref(gm, nw, :non_slack_junction_ids)
        var(gm, nw, :non_slack_derivative)[i] = 0
        derivative_indices = ref(gm, nw, :non_slack_neighbor_junction_ids, i)
        for j in derivative_indices
            pipe_info = ref(gm, nw, :neighbor_edge_info, j)[i]
            id = pipe_info["id"]
            is_compressor = pipe_info["is_compressor"]
            pipe = is_compressor ? ref(gm, nw, :compressor, id) : ref(gm, nw, :pipe, id)
            x = pipe["length"] * pi * pipe["diameter"]^2 / 4.0
            if (is_compressor && pipe["fr_junction"] == j && pipe["to_junction"] == i)
                var(gm, nw, :non_slack_derivative)[i] += (
                    x *
                    var(gm, nw, :compressor_ratio, id) *
                    var(gm, nw, :density_derivative, j)
                )
            else
                var(gm, nw, :non_slack_derivative)[i] += (x * var(gm, nw, :density_derivative, j))
            end
        end

        for (j, neighbor) in ref(gm, nw, :neighbor_edge_info, i)
            id = neighbor["id"]
            is_compressor = neighbor["is_compressor"]
            pipe = is_compressor ? ref(gm, nw, :compressor, id) : ref(gm, nw, :pipe, id)
            x = pipe["length"] * pi * pipe["diameter"]^2 / 4.0
            if (is_compressor && pipe["fr_junction"] == i && pipe["to_junction"] == j)
                var(gm, nw, :non_slack_derivative)[i] += (
                    x *
                    var(gm, nw, :compressor_ratio, id) *
                    var(gm, nw, :density_derivative, i)
                )
            else
                var(gm, nw, :non_slack_derivative)[i] += (x * var(gm, nw, :density_derivative, i))
            end
        end
    end
end

"compression power"
function expression_compressor_power(gm::AbstractGasModel, nw::Int; report::Bool = true)
    comp_power = var(gm, nw)[:compressor_power_expr] = Dict{Int,Any}()
    for (i, compressor) in ref(gm, nw, :compressor)
        alpha = var(gm, nw, :compressor_ratio, i)
        f = var(gm, nw, :compressor_flow, i)
        m = (gm.ref[:it][gm_it_sym][:specific_heat_capacity_ratio] - 1) /
            gm.ref[:it][gm_it_sym][:specific_heat_capacity_ratio]
        W = 286.76 * gm.ref[:it][gm_it_sym][:temperature] / gm.ref[:it][gm_it_sym][:gas_specific_gravity] / m
        var(gm, nw, :compressor_power_expr)[i] = JuMP.@NLexpression(gm.model, W * abs(f) * (alpha^m - 1.0))
    end

    report && _IM.sol_component_value(
        gm,
        gm_it_sym,
        nw,
        :compressor,
        :power_expr,
        ids(gm, nw, :compressor),
        comp_power,
    )
end
