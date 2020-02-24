@testset "test matgas parsing" begin
    #Check the second order code model on load shedding
    @testset "test matgas gaslib 40 misocp ls" begin
        @info "Testing matgas gaslib 40 misocp ls"
        result = run_ls("../test/data/matgas/gaslib-40-ls.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
#        @test isapprox(result["objective"]*result["solution"]["base_flow"], 515.23066377; atol = 1e-1)  || isapprox(result["objective"]*result["solution"]["base_flow"], 456.54; atol = 1e-1)
        @test isapprox(result["objective"]*result["solution"]["base_flow"], 456.54; atol = 1e-1)
    end

    #Check the second order code model
    @testset "test matgas gaslib 40 misocp gf" begin
        @info "Testing matgas gaslib 40 misocp"
        data = GasModels.parse_file("../test/data/matgas/gaslib-40.m")
        result = run_gf("../test/data/matgas/gaslib-40.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 0; atol = 1e-6)
        gm = GasModels.instantiate_model(data, MINLPGasModel, GasModels.post_gf)
        check_pressure_status(result["solution"], gm)
        check_compressor_ratio(result["solution"], gm)
    end
end
