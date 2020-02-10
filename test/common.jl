""
function check_pressure_status(sol, gm)
    for (idx,val) in sol["junction"]
        @test val["p_nominal"] <= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["p_max"]
        @test val["p_nominal"] >= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["p_min"]
    end
end


""
function check_pressure_status(sol, gm)
    for (idx,val) in sol["junction"]
        @test val["p_nominal"] <= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["p_max"]
        @test val["p_nominal"] >= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["p_min"]
    end
end


""
function check_compressor_ratio(sol, gm)
    for (idx,val) in sol["compressor"]
        k = parse(Int64,idx)
        connection = gm.ref[:nw][gm.cnw][:compressor][parse(Int64,idx)]
        @test val["ratio"] <= connection["c_ratio_max"] + 1e-6
        @test val["ratio"] >= connection["c_ratio_min"] - 1e-6
    end
end
