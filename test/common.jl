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
