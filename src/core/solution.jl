function _IM.solution_preprocessor(gm::AbstractGasModel, solution::Dict)
    solution["is_per_unit"] = gm.data["is_per_unit"]
    solution["multinetwork"] = ismultinetwork(gm.data)
    solution["base_pressure"] = gm.ref[:base_pressure]
    solution["base_flow"] = gm.ref[:base_flow]
    solution["base_time"] = gm.ref[:base_time]
    solution["base_length"] = gm.ref[:base_length]
    solution["base_density"] = gm.ref[:base_density]
end
