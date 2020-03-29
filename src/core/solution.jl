function _IM.solution_preprocessor(gm::AbstractGasModel, solution::Dict)
    solution["is_per_unit"] = gm.data["is_per_unit"]
    solution["multinetwork"] = ismultinetwork(gm.data)
    solution["base_pressure"] = gm.ref[:base_pressure]
    solution["base_flow"] = gm.ref[:base_flow]
end
