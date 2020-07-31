@testset "Direction of Regulators" begin
    @testset "Base Model" begin
        @info "Testing base model"
        result = run_gf("../test/data/matgas/direction.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    end

    @testset "Regulator direction" begin
        @info "Testing regulator direction"

        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 0
        data["regulator"]["50"]["is_bidirectional"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 1
        data["regulator"]["50"]["is_bidirectional"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = -1
        data["regulator"]["50"]["is_bidirectional"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 0
        data["regulator"]["50"]["is_bidirectional"] = 1
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        # These will become infeasible once pressure variables are introduced
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 0
        data["regulator"]["50"]["is_bidirectional"] = 1
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        data["junction"]["52"]["p_max"] = 6000000
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 1
        data["regulator"]["50"]["is_bidirectional"] = 1
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = -1
        data["regulator"]["50"]["is_bidirectional"] = 1
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        # These will become infeasible once pressure variables are introduced
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = -1
        data["regulator"]["50"]["is_bidirectional"] = 1
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        data["junction"]["52"]["p_max"] = 6000000
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 0
        data["regulator"]["50"]["is_bidirectional"] = 0
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 1
        data["regulator"]["50"]["is_bidirectional"] = 0
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = -1
        data["regulator"]["50"]["is_bidirectional"] = 0
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 0
        data["regulator"]["50"]["is_bidirectional"] = 0
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = 1
        data["regulator"]["50"]["is_bidirectional"] = 0
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct=true)
        data["regulator"]["50"]["flow_direction"] = -1
        data["regulator"]["50"]["is_bidirectional"] = 0
        data["regulator"]["50"]["fr_junction"] = 52
        data["regulator"]["50"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, MIPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == LOCALLY_INFEASIBLE

    end
end
