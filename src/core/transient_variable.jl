"variables associated with density (transient)"
function variable_density(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    rho = var(gm, nw)[:density] = JuMP.@variable(gm.model, 
        [i in keys(ref(gm, nw, :junction))], 
        base_name="$(nw)_rho", 
        start=comp_start_value(ref(gm, nw, :junction), i, "rho_start", ref(gm, nw, :junction, i)["p_min"])
    )
    
    if bounded 
        for (i, junction) in ref(gm, nw, :junction)
            JuMP.set_lower_bound(rho[i], ref(gm, nw, :junction, i)["p_min"])
            JuMP.set_upper_bound(rho[i], ref(gm, nw, :junction, i)["p_max"])
        end 
    end 

    report && _IM.sol_component_value(gm, nw, :junction, :rho, ids(gm, nw, :junction), rho)
    report && _IM.sol_component_value(gm, nw, :junction, :p, ids(gm, nw, :junction), rho)
end 

"variables associated with compressor mass flow (transient)"
function variable_compressor_flow(gm::AbstractGasModel, nw::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    max_mass_flow = ref(gm, nw, :max_mass_flow)
    f = var(gm, nw)[:compressor_flow] = JuMP.@variable(gm.model, 
        [i in keys(ref(gm, nw, :compressor))], 
        base_name="$(nw)_f_compressor", 
        start=comp_start_value(ref(gm, nw, :compressor), i, "f_compressor_start", 0.0)
    )
    
    if bounded 
        for (i, compressor) in ref(gm, nw, :compressor)
            JuMP.set_lower_bound(f[i], -max_mass_flow)
            JuMP.set_upper_bound(f[i], max_mass_flow)
        end 
    end 

    report && _IM.sol_component_value(gm, nw, :compressor, :f, ids(gm, nw, :compressor), f)
end 



