function _IM.solution_preprocessor(gm::AbstractGasModel, solution::Dict)
    solution["it"]["ng"]["is_per_unit"] = _IM.get_data_with_function(gm.data, "ng", x -> return x["is_per_unit"])
    solution["it"]["ng"]["multinetwork"] = ismultinetwork(gm)
    solution["it"]["ng"]["base_pressure"] = gm.ref[:it][:ng][:base_pressure]
    solution["it"]["ng"]["base_flow"] = gm.ref[:it][:ng][:base_flow]
    solution["it"]["ng"]["base_time"] = gm.ref[:it][:ng][:base_time]
    solution["it"]["ng"]["base_length"] = gm.ref[:it][:ng][:base_length]
    solution["it"]["ng"]["base_density"] = gm.ref[:it][:ng][:base_density]
    solution["it"]["ng"]["base_volume"] = gm.ref[:it][:ng][:base_volume]
    solution["it"]["ng"]["base_mass"] = gm.ref[:it][:ng][:base_mass]
end



function sol_psqr_to_p!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"]["ng"], "nw")
        nws_data = solution["it"]["ng"]["nw"]
    else
        nws_data = Dict("0" => solution["it"]["ng"])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "junction")
            for (i, junction) in nw_data["junction"]
                if haskey(junction, "psqr")
                    junction["p"] = sqrt(max(0.0, junction["psqr"]))
                end
            end
        end
    end
end


function sol_rsqr_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"]["ng"], "nw")
        nws_data = solution["it"]["ng"]["nw"]
    else
        nws_data = Dict("0" => solution["it"]["ng"])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "compressor")
            for (i, compressor) in nw_data["compressor"]
                if haskey(compressor, "rsqr")
                    compressor["r"] = sqrt(max(0.0, compressor["rsqr"]))
                end
            end
        end
    end
end


function sol_compressor_p_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"]["ng"], "nw")
        nws_data = solution["it"]["ng"]["nw"]
    else
        nws_data = Dict("0" => solution["it"]["ng"])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "compressor")
            for (k, compressor) in nw_data["compressor"]
                i = ref(gm, :compressor, parse(Int64, k); nw = parse(Int64, n))["fr_junction"]
                j = ref(gm, :compressor, parse(Int64, k); nw = parse(Int64, n))["to_junction"]
                f = compressor["f"]
                pi = max(0.0, nw_data["junction"][string(i)]["psqr"])
                pj = max(0.0, nw_data["junction"][string(j)]["psqr"])

                compressor["r"] = (f >= 0) ? sqrt(pj) / sqrt(pi) : sqrt(pi) / sqrt(pj)
            end
        end
    end
end


function sol_ne_compressor_p_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"]["ng"], "nw")
        nws_data = solution["it"]["ng"]["nw"]
    else
        nws_data = Dict("0" => solution["it"]["ng"])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "ne_compressor")
            for (k, compressor) in nw_data["ne_compressor"]
                i = ref(gm, :ne_compressor, parse(Int64, k); nw = parse(Int64, n))["fr_junction"]
                j = ref(gm, :ne_compressor, parse(Int64, k); nw = parse(Int64, n))["to_junction"]
                f = compressor["f"]
                pi = max(0.0, nw_data["junction"][string(i)]["psqr"])
                pj = max(0.0, nw_data["junction"][string(j)]["psqr"])

                compressor["r"] = (f >= 0) ? sqrt(pj) / sqrt(pi) : sqrt(pi) / sqrt(pj)
            end
        end
    end
end

function sol_regulator_p_to_r!(gm::AbstractGasModel, solution::Dict)
    if haskey(solution["it"]["ng"], "nw")
        nws_data = solution["it"]["ng"]["nw"]
    else
        nws_data = Dict("0" => solution["it"]["ng"])
    end

    for (n, nw_data) in nws_data
        if haskey(nw_data, "regulator")
            for (k, regulator) in nw_data["regulator"]
                i = ref(gm, :regulator, parse(Int64, k); nw = parse(Int64, n))["fr_junction"]
                j = ref(gm, :regulator, parse(Int64, k); nw = parse(Int64, n))["to_junction"]
                f = regulator["f"]
                pi = max(0.0, nw_data["junction"][string(i)]["psqr"])
                pj = max(0.0, nw_data["junction"][string(j)]["psqr"])

                regulator["r"] = (f >= 0) ? sqrt(pj) / sqrt(pi) : sqrt(pi) / sqrt(pj)
            end
        end
    end
end
