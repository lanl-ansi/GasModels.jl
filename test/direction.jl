@testset "Direction of Edges" begin
    @testset "Base Model" begin
        @info "Testing base model"
        result = run_gf("../test/data/matgas/direction.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    end

    @testset "Pipe direction" begin
        @info "Testing pipe direction"
#        data = GasModels.parse("../test/data/matgas/direction.m")
#        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
#        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    end


end
