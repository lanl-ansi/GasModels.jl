@testset "Direction of Edges" begin
    @testset "Base Model" begin
        @info "Testing base model"
        result = run_gf("../test/data/matgas/direction.m", MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    end

    @testset "Short Pipe direction" begin
        @info "Testing short pipe direction"

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 0
        data["short_pipe"]["30"]["is_bidirectional"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 1
        data["short_pipe"]["30"]["is_bidirectional"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = -1
        data["short_pipe"]["30"]["is_bidirectional"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 0
        data["short_pipe"]["30"]["is_bidirectional"] = 1
        data["short_pipe"]["30"]["fr_junction"] = 32
        data["short_pipe"]["30"]["to_junction"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 1
        data["short_pipe"]["30"]["is_bidirectional"] = 1
        data["short_pipe"]["30"]["fr_junction"] = 32
        data["short_pipe"]["30"]["to_junction"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = -1
        data["short_pipe"]["30"]["is_bidirectional"] = 1
        data["short_pipe"]["30"]["fr_junction"] = 32
        data["short_pipe"]["30"]["to_junction"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 0
        data["short_pipe"]["30"]["is_bidirectional"] = 0
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 1
        data["short_pipe"]["30"]["is_bidirectional"] = 0
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = -1
        data["short_pipe"]["30"]["is_bidirectional"] = 0
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 0
        data["short_pipe"]["30"]["is_bidirectional"] = 0
        data["short_pipe"]["30"]["fr_junction"] = 32
        data["short_pipe"]["30"]["to_junction"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = 1
        data["short_pipe"]["30"]["is_bidirectional"] = 0
        data["short_pipe"]["30"]["fr_junction"] = 32
        data["short_pipe"]["30"]["to_junction"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE

        data = GasModels.parse_file("../test/data/matgas/direction.m")
        data["short_pipe"]["30"]["flow_direction"] = -1
        data["short_pipe"]["30"]["is_bidirectional"] = 0
        data["short_pipe"]["30"]["fr_junction"] = 32
        data["short_pipe"]["30"]["to_junction"] = 1
        result = run_gf(data, MISOCPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, cvx_minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE



    end














end
