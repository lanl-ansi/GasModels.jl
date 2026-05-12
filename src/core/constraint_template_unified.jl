"Template: Constraints for mass flow balance equation where demand and production is are a mix of constants and variables"
function constraint_junction_flow_balance(gm::AbstractGasModel, i; n::Int = nw_id_default)
    junction = ref(gm, n, :junction, i)
    f_pipes = ref(gm, n, :pipes_fr, i)
    t_pipes = ref(gm, n, :pipes_to, i)
    f_compressors = ref(gm, n, :compressors_fr, i)
    t_compressors = ref(gm, n, :compressors_to, i)
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
    fgmax = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_max"] for j in dispatch_receipts) : 0
    flmax = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_max"] for j in dispatch_deliveries) : 0
    flmax += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_max"] for j in dispatch_transfers) : 0
    fgmin = length(dispatch_receipts) > 0 ? sum(receipt[j]["injection_min"] for j in dispatch_receipts) : 0
    flmin = length(dispatch_deliveries) > 0 ? sum(delivery[j]["withdrawal_min"] for j in dispatch_deliveries) : 0
    flmin += length(dispatch_transfers) > 0 ? sum(transfer[j]["withdrawal_min"] for j in dispatch_transfers) : 0

    constraint_junction_flow_balance(gm, n, i, f_pipes, t_pipes, f_compressors, t_compressors, fl, fg, dispatch_deliveries, dispatch_receipts, dispatch_transfers, storages, flmin, flmax, fgmin, fgmax)
end