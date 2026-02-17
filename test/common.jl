"Ensures that junction pressure solution resides within bounds."
function check_pressure_status(sol, gm)
    for (idx, val) in sol["junction"]
        @test val["p"] <= ref(gm, :junction, parse(Int64, idx))["p_max"]
        @test val["p"] >= ref(gm, :junction, parse(Int64, idx))["p_min"]
    end
end


"Ensures that compression ratio solution resides within bounds."
function check_compressor_ratio(sol, gm)
    for (idx, val) in sol["compressor"]
        connection = ref(gm, :compressor, parse(Int64, idx))
        @test val["r"] <= connection["c_ratio_max"] + 1e-6
        @test val["r"] >= connection["c_ratio_min"] - 1e-6
    end
end


"Compare number dictionaries"
function compare(d1::Dict, d2::Dict; atol=0, rtol=0)
    for (k,v) in d1
        if haskey(d2, k)
            if !compare(v, d2[k]; atol, rtol)
                return false
            end
        end
    end
    return true
end
function compare(d1::Number, d2::Number; atol=0, rtol=0)
    if !isapprox(d1, d2; atol, rtol)
        println("Values $d1 and $d2 do not match")
        return false
    end
    return true
end