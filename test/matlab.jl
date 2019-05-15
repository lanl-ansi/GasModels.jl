function check_pressure_status(sol, gm)
    for (idx,val) in sol["junction"]
        @test val["p"] <= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["pmax"]
        @test val["p"] >= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["pmin"]
    end
end

function check_compressor_ratio(sol, gm)
    for (idx,val) in sol["compressor"]
        k = parse(Int64,idx)
        connection = gm.ref[:nw][gm.cnw][:compressor][parse(Int64,idx)]
        @test val["ratio"] <= connection["c_ratio_max"] + 1e-6
        @test val["ratio"] >= connection["c_ratio_min"] - 1e-6
    end
end

#Check the second order code model on load shedding
@testset "test misocp ls" begin
    @testset "gaslib 40 case" begin
        println("Testing matlab gaslib 40 misocp ls")
        result = run_ls("../test/data/matlab/gaslib40-ls.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*result["solution"]["baseQ"], 515.23066377; atol = 1e-1)
     end
end


#Check the second order code model
@testset "test misocp gf" begin
    @testset "gaslib 40" begin
        println("Testing matlab gaslib 40 misocp")
        data = GasModels.parse_file("../test/data/matlab/gaslib40.m")
        result = run_gf("../test/data/matlab/gaslib40.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-6)
        gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)
        check_pressure_status(result["solution"], gm)
        check_compressor_ratio(result["solution"], gm)
    end

end
