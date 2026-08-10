"""
Generate IA sufficient condition constraints from decomposed matrices.

This implements the CORRECT approach from your Research_Ideas-2.pdf.
Key: We write inequalities on equation (83) using decomposed PRODUCTS.
"""

# Placeholder - will be implemented in next step after understanding residual structure



#### Old

"variables for inner approximation"
function variable_ia(gm::AbstractGasModel, nw::Int=nw_id_default; bounded::Bool=false, report::Bool=true)
    # junction pressures
    ##p
    l_pi_p = var(gm, nw)[:l_pi_p] = JuMP.@variable(
        gm.model, [i in ids(gm, nw, :junction)], base_name="$(nw)_l_pi_p",
        )
    report && sol_component_value(gm, nw, :junction, :l_pi_p, ids(gm, nw, :junction), l_pi_p)
    ##n
    l_pi_n = var(gm, nw)[:l_pi_n] = JuMP.@variable(
        gm.model, [i in ids(gm, nw, :junction)], base_name="$(nw)_l_pi_n",
        )
    report && sol_component_value(gm, nw, :junction, :l_pi_n, ids(gm, nw, :junction), l_pi_n)

    # edge flows
    ## pipe_p
    l_f_pipe_p = var(gm, nw)[:l_f_pipe_p] = JuMP.@variable(gm.model,
        [i in ids(gm, nw, :pipe)],
        base_name="$(nw)_l_f_pipe_p",
    )
    report && sol_component_value(gm, nw, :pipe, :l_f_pipe_p, ids(gm, nw, :pipe), l_f_pipe_p)
    ## pipe_n
    l_f_pipe_n = var(gm, nw)[:l_f_pipe_n] = JuMP.@variable(gm.model,
        [i in ids(gm, nw, :pipe)],
        base_name="$(nw)_l_f_pipe_n",
    )
    report && sol_component_value(gm, nw, :pipe, :l_f_pipe_n, ids(gm, nw, :pipe), l_f_pipe_n)
    ## compressor_p
    l_f_compressor_p = var(gm, nw)[:l_f_compressor_p] = JuMP.@variable(gm.model,
        [i in ids(gm, nw, :compressor)],
        base_name="$(nw)_l_f_compressor_p",
    )
    report && sol_component_value(gm, nw, :compressor, :l_f_compressor_p, ids(gm, nw, :compressor), l_f_compressor_p)
    ## compressor_n
    l_f_compressor_n = var(gm, nw)[:l_f_compressor_n] = JuMP.@variable(gm.model,
        [i in ids(gm, nw, :compressor)],
        base_name="$(nw)_l_f_compressor_n",
    )
    report && sol_component_value(gm, nw, :compressor, :l_f_compressor_n, ids(gm, nw, :compressor), l_f_compressor_n)

    # compression ratio square
    # cr_p
    compressors = ref(gm, nw, :compressor)
    l_a2_p = var(gm, nw)[:l_a2_p] = JuMP.@variable(gm.model,
        [i in keys(compressors)],
        base_name="$(nw)_l_a2_p",
        # start=comp_start_value(ref(gm, nw, :compressor), i, "ratio_start", 1.0)
    )
    report && sol_component_value(gm, nw, :compressor, :l_a2_p, keys(compressors), l_a2_p)
    # cr_n
    l_a2_n = var(gm, nw)[:l_a2_n] = JuMP.@variable(gm.model,
        [i in keys(compressors)],
        base_name="$(nw)_l_a2_n",
        # start=comp_start_value(ref(gm, nw, :compressor), i, "ratio_start", 1.0)
    )
    report && sol_component_value(gm, nw, :compressor, :l_a2_n, keys(compressors), l_a2_n)

    # receipts, deliveries, transfers & storage
    l_fg_p = var(gm, nw)[:l_fg_p] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_receipt)],
        base_name="$(nw)_l_fg_p",
        )

    if report
        sol_component_value(gm, nw, :receipt, :l_fg_p, ids(gm, nw, :dispatchable_receipt), l_fg_p)
    end

    l_fg_n = var(gm, nw)[:l_fg_n] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_receipt)],
        base_name="$(nw)_l_fg_n",
        )

    if report
        sol_component_value(gm, nw, :receipt, :l_fg_n, ids(gm, nw, :dispatchable_receipt), l_fg_n)
    end

    l_fl_p = var(gm, nw)[:l_fl_p] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_delivery)],
        base_name="$(nw)_l_fl_p",
    )

    if report
        sol_component_value(gm, nw, :delivery, :l_fd_p, ids(gm, nw, :dispatchable_delivery), l_fl_p)
    end

    l_fl_n = var(gm, nw)[:l_fl_n] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_delivery)],
        base_name="$(nw)_l_fl_n",
    )

    if report
        sol_component_value(gm, nw, :delivery, :l_fd_n, ids(gm, nw, :dispatchable_delivery), l_fl_n)
    end



    l_ft_p = var(gm, nw)[:l_ft_p] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_transfer)],
        base_name="$(nw)_l_ft_p",
    )

    if report
        sol_component_value(gm, nw, :transfer, :l_ft_p, ids(gm, nw, :dispatchable_transfer), l_ft_p)
    end


    l_ft_n = var(gm, nw)[:l_ft_n] = JuMP.@variable(gm.model,
        [i in ids(gm,nw,:dispatchable_transfer)],
        base_name="$(nw)_l_ft_n",
    )

    if report
        sol_component_value(gm, nw, :transfer, :l_ft_n, ids(gm, nw, :dispatchable_transfer), l_ft_n)
    end

    l_f_wh_p = var(gm, nw)[:l_well_head_flow_p] = JuMP.@variable(gm.model,[i in ids(gm, nw, :storage)],base_name = "$(nw)_storage_well_head_p")

    if report
        _IM.sol_component_value(gm,gm_it_sym,nw,:storage,:l_withdrawal_p,ids(gm, nw, :storage),l_f_wh_p)
    end

    l_f_wh_n = var(gm, nw)[:l_well_head_flow_n] = JuMP.@variable(gm.model,[i in ids(gm, nw, :storage)],base_name = "$(nw)_storage_well_head_n")

    if report
        _IM.sol_component_value(gm,gm_it_sym,nw,:storage,:l_withdrawal_n,ids(gm, nw, :storage),l_f_wh_n)
    end
end

"Template: pipe weymouth ia"
function constraint_ia_pipe_weymouth(gm::AbstractGasModel, k; n::Int = nw_id_default)
    pipe = ref(gm, n, :pipe, k)
    i = pipe["fr_junction"]
    j = pipe["to_junction"]
    pd_min, pd_max = _calc_pipe_pd_bounds_sqr(pipe, ref(gm, n, :junction, i), ref(gm, n, :junction, j))
    f_min = pipe["flow_min"]
    f_max = pipe["flow_max"]
    theta = pipe["theta"]
    D = pipe["diameter"]

    f_0 = _ia_fp_value(gm, n, :pipe, k, "f")
    reversal_allowed = _ia_reversal_allowed(gm)

    if(D!=0.0)
        if(rad2deg(abs(theta)) <= 5)
            w = _calc_pipe_resistance(pipe, gm.ref[:it][gm_it_sym][:base_length], gm.ref[:it][gm_it_sym][:base_pressure], gm.ref[:it][gm_it_sym][:base_flow], gm.ref[:it][gm_it_sym][:sound_speed])
            constraint_ia_pipe_weymouth(gm, n, k, i, j, f_min, f_max, w, pd_min, pd_max, f_0, reversal_allowed)
        else
            #TODO Inclined pipes
            @error "Inclined pipes not yet supported"
        end
    end
end


"Weymouth equation with absolute value"
function constraint_ia_pipe_weymouth(gm::AbstractWPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max, f_0, reversal_allowed::Bool)
    l_pi_i_p = var(gm, n, :l_pi_p, i)
    l_pi_i_n = var(gm, n, :l_pi_n, i)
    l_pi_j_p = var(gm, n, :l_pi_p, j)
    l_pi_j_n = var(gm, n, :l_pi_n, j)
    l_f_p = var(gm, n, :l_f_pipe_p, k)
    l_f_n = var(gm, n, :l_f_pipe_n, k)

    @info "pipe $k fp value $f_0"
    if w == 0.0
        #TODO
        @error " pipe resistance 0"
    else
        if reversal_allowed == false
            if f_0 > 0 
                _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, -l_pi_i_n - l_pi_j_p - (2*abs(f_0)*l_f_p / w) <= 0))
                _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, l_pi_i_p + l_pi_j_n + (2*abs(f_0)*l_f_n / w) >= l_f_n^2/w))
                _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, l_pi_i_p + l_pi_j_n + (2*abs(f_0)*l_f_n / w) >= l_f_p^2/w))
            elseif f_0 < 0
                _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, -l_pi_i_n - l_pi_j_p - (2*abs(f_0)*l_f_p / w) <= -l_f_n^2/w))
                _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, -l_pi_i_n - l_pi_j_p - (2*abs(f_0)*l_f_p / w) <= -l_f_p^2/w))
                _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, l_pi_i_p + l_pi_j_n + (2*abs(f_0)*l_f_n / w) >= 0))
            elseif f_0 == 0.0
                #TODO
                @error "0 flow in pipe not yet supported"
            end
        else
            @error "Pipe flow reversal not yet supported"
        end
    end
end

"Template: Constraints for inner approximating the mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_ia_mass_flow_balance(gm::AbstractGasModel, i; n::Int = nw_id_default)
    receipt_min(receipt) = receipt["injection_min"]
    receipt_max(receipt) =  receipt["injection_max"]
    delivery_min(delivery) = delivery["withdrawal_min"]
    delivery_max(delivery) = delivery["withdrawal_max"]
    transfer_min(transfer) = transfer["withdrawal_min"]
    transfer_max(transfer) = transfer["withdrawal_max"]

    junction = ref(gm, n, :junction, i)
    f_pipes = ref(gm, n, :pipes_fr, i)
    t_pipes = ref(gm, n, :pipes_to, i)
    f_compressors = ref(gm, n, :compressors_fr, i)
    t_compressors = ref(gm, n, :compressors_to, i)
    f_resistors = ref(gm, n, :resistors_fr, i)
    t_resistors = ref(gm, n, :resistors_to, i)
    f_loss_resistors = ref(gm, n, :loss_resistors_fr, i)
    t_loss_resistors = ref(gm, n, :loss_resistors_to, i)
    f_short_pipes = ref(gm, n, :short_pipes_fr, i)
    t_short_pipes = ref(gm, n, :short_pipes_to, i)
    f_valves = ref(gm, n, :valves_fr, i)
    t_valves = ref(gm, n, :valves_to, i)
    f_regulators = ref(gm, n, :regulators_fr, i)
    t_regulators = ref(gm, n, :regulators_to, i)
    delivery = ref(gm, n, :delivery)
    receipt = ref(gm, n, :receipt)
    transfer = ref(gm, n, :transfer)
    dispatch_receipts = ref(gm, n, :dispatchable_receipts_in_junction, i)
    nondispatch_receipts = ref(gm, n, :nondispatchable_receipts_in_junction, i)
    dispatch_deliveries = ref(gm, n, :dispatchable_deliveries_in_junction, i)
    nondispatch_deliveries = ref(gm, n, :nondispatchable_deliveries_in_junction, i)
    dispatch_transfers = ref(gm, n, :dispatchable_transfers_in_junction, i)
    nondispatch_transfers = ref(gm, n, :nondispatchable_transfers_in_junction, i)
    storages = ref(gm, n, :storages_in_junction, i)

    fg = length(nondispatch_receipts) > 0 ? sum(receipt[j]["injection_nominal"] for j in nondispatch_receipts) : 0
    fl = length(nondispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_nominal"] for j in nondispatch_deliveries) : 0
    fl += length(nondispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_nominal"] for j in nondispatch_transfers) : 0
    fgmax = length(dispatch_receipts) > 0 ? sum(receipt_max(receipt[j]) for j in dispatch_receipts) : 0
    flmax = length(dispatch_deliveries) > 0 ? sum(delivery_max(delivery[j]) for j in dispatch_deliveries) : 0
    flmax += length(dispatch_transfers) > 0 ? sum(transfer_max(transfer[j]) for j in dispatch_transfers) : 0
    fgmin = length(dispatch_receipts) > 0 ? sum(receipt_min(receipt[j]) for j in dispatch_receipts) : 0
    flmin = length(dispatch_deliveries) > 0 ? sum(delivery_min(delivery[j]) for j in dispatch_deliveries) : 0
    flmin += length(dispatch_transfers) > 0 ? sum(transfer_min(transfer[j]) for j in dispatch_transfers) : 0

    constraint_ia_mass_flow_balance(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, fl, fg, dispatch_deliveries, dispatch_receipts, dispatch_transfers, storages, flmin, flmax, fgmin, fgmax)
end

"Constraint: IA flow balance equation where demand and production are variables"
function constraint_ia_mass_flow_balance(gm::AbstractGasModel, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, f_resistors, t_resistors, f_loss_resistors, t_loss_resistors, f_short_pipes, t_short_pipes, f_valves, t_valves, f_regulators, t_regulators, fl_constant, fg_constant, deliveries, receipts, transfers, storages, flmin, flmax, fgmin, fgmax)
    l_f_pipe_p = var(gm, n, :l_f_pipe_p)
    l_f_pipe_n = var(gm, n, :l_f_pipe_n)
    l_f_compressor_p = var(gm, n, :l_f_compressor_p)
    l_f_compressor_n = var(gm, n, :l_f_compressor_n)
    
    l_fg_p = var(gm, n, :l_fg_p)
    l_fg_n = var(gm, n, :l_fg_n)
    l_fl_p = var(gm, n, :l_fl_p)
    l_fl_n = var(gm, n, :l_fl_n)
    l_ft_p = var(gm, n, :l_ft_p)
    l_ft_n = var(gm, n, :l_ft_n)
    l_fs_p = var(gm, n, :l_well_head_flow_p)
    l_fs_n = var(gm, n, :l_well_head_flow_n)

    _add_constraint!(gm, n, :junction_mass_flow_balance_1, i, JuMP.@constraint(gm.model, - sum(l_fg_n[a] for a in receipts) - sum(l_fl_p[a] for a in deliveries) - sum(l_ft_p[a] for a in transfers) - sum(l_fs_p[a] for a in storages) >=
                                                                            -sum(l_f_pipe_n[a] for a in f_pipes) - sum(l_f_pipe_p[a] for a in t_pipes) 
                                                                            - sum(l_f_compressor_n[a] for a in f_compressors) - sum(l_f_compressor_p[a] for a in t_compressors)
                                                                        ))
    _add_constraint!(gm, n, :junction_mass_flow_balance_2, i, JuMP.@constraint(gm.model, sum(l_fg_p[a] for a in receipts) + sum(l_fl_n[a] for a in deliveries) + sum(l_ft_n[a] for a in transfers) + sum(l_fs_n[a] for a in storages) <=
                                                                            sum(l_f_pipe_p[a] for a in f_pipes) + sum(l_f_pipe_n[a] for a in t_pipes) +
                                                                            sum(l_f_compressor_p[a] for a in f_compressors) + sum(l_f_compressor_n[a] for a in t_compressors)
                                                                        ))

end


#TODO
#Need to create variables for receipts, deliveries and transfers.
# Need to write the mass_flow_balance equation considering their coefficient signs in the original equation.
# Need to be careful with receipts, delivereis and transfers
