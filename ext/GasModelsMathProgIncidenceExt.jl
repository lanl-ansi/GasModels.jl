module GasModelsMathProgIncidenceExt

import JuMP
import GasModels
import MathProgIncidence as MPIN

function get_dependent_subsystem(gm::GasModels.AbstractGasModel)
    # TODO:
    # - Make sure subsystem is square and nonsingular
    # - Make sure subsystem contains no inequalities
    ref = gm.ref[:it][:gm][:nw][0]
    nonslack_junctions = filter(i -> ref[:junction][i]["junction_type"] == 0, collect(keys(ref[:junction])))

    pipe_flows = GasModels.var(gm, :f_pipe).data
    compressor_flows = GasModels.var(gm, :f_compressor).data
    nonslack_pressures = map(i -> GasModels.var(gm, :psqr, i), nonslack_junctions)

    nonslack_balances = map(i -> GasModels.con(gm, :junction_mass_flow_balance, i), nonslack_junctions)
    weymouth_eqs = collect(values(GasModels.con(gm, :weymouth1)))
    compressor_ratio_eqs = collect(values(GasModels.con(gm, :compressor_ratio_value1)))

    cons = vcat(nonslack_balances, weymouth_eqs, compressor_ratio_eqs)
    vars = vcat(pipe_flows, compressor_flows, nonslack_pressures)
    @assert !any(MPIN.is_inequality.(cons))
    subsystem = MPIN.Subsystem((cons, vars))
    return subsystem
end

function MPIN.explain(
    gm::GasModels.AbstractGasModel,
    var::JuMP.VariableRef;
    options::MPIN.ExplanationOptions = MPIN.ExplanationOptions(),
)
    dependent = get_dependent_subsystem(gm)
    explanation = MPIN.explain(
        var,
        convert(Vector{JuMP.VariableRef}, dependent.var),
        convert(Vector{JuMP.ConstraintRef}, dependent.con);
        options,
    )
    return explanation
end

function MPIN.explain(
    gm::GasModels.AbstractGasModel,
    component::Symbol,
    index::Int;
    options::MPIN.ExplanationOptions = MPIN.ExplanationOptions(),
)
    var = GasModels.var(gm, component, index)
    return MPIN.explain(gm, var; options)
end

end
