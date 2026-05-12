"Constraint: standard flow balance equation where demand and production are variables"
function constraint_junction_flow_balance(gm::AbstractGasModel, n::Int, i, f_pipes, t_pipes, f_compressors, t_compressors, fl_constant, fg_constant, deliveries, receipts, transfers, storages, flmin, flmax, fgmin, fgmax)
    f_pipe = var(gm, n, :f_pipe)
    f_compressor = var(gm, n, :f_compressor)
    fg = var(gm, n, :injection_receipt)
    fl = var(gm, n, :withdrawal_delivery)
    ft = var(gm, n, :withdrawal_transfer)
    fs = var(gm, n, :withdrawal_storage)

    cstr_mfb = _add_constraint!(gm, n, :junction_mass_flow_balance, i, JuMP.@constraint(gm.model, fg_constant - fl_constant + sum(fg[a] for a in receipts) - sum(fl[a] for a in deliveries) - sum(ft[a] for a in transfers) - sum(fs[a] for a in storages) ==
                                                                            sum(f_pipe[a] for a in f_pipes) - sum(f_pipe[a] for a in t_pipes) +
                                                                            sum(f_compressor[a] for a in f_compressors) - sum(f_compressor[a] for a in t_compressors) 
                                                                        ))
    if _IM.report_duals(gm)
        sol(gm, n)[:junction][i][:lam_junction_mfb] = cstr_mfb
    end
end