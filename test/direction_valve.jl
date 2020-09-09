@testset "Direction of Valves" begin
    @testset "Base Model" begin
        @info "Testing base model"
        result = run_gf("../test/data/matgas/direction.m", CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf("../test/data/matgas/direction.m", LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    end

    @testset "Valve direction" begin
        @info "Testing valve direction"

        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 0
        data["valve"]["60"]["is_bidirectional"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 1
        data["valve"]["60"]["is_bidirectional"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = -1
        data["valve"]["60"]["is_bidirectional"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 0
        data["valve"]["60"]["is_bidirectional"] = 1
        data["valve"]["60"]["fr_junction"] = 62
        data["valve"]["60"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 1
        data["valve"]["60"]["is_bidirectional"] = 1
        data["valve"]["60"]["fr_junction"] = 62
        data["valve"]["60"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = -1
        data["valve"]["60"]["is_bidirectional"] = 1
        data["valve"]["60"]["fr_junction"] = 62
        data["valve"]["60"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 0
        data["valve"]["60"]["is_bidirectional"] = 0
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 1
        data["valve"]["60"]["is_bidirectional"] = 0
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = -1
        data["valve"]["60"]["is_bidirectional"] = 0
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 0
        data["valve"]["60"]["is_bidirectional"] = 0
        data["valve"]["60"]["fr_junction"] = 62
        data["valve"]["60"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = 1
        data["valve"]["60"]["is_bidirectional"] = 0
        data["valve"]["60"]["fr_junction"] = 62
        data["valve"]["60"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE


        data = GasModels.parse_file("../test/data/matgas/direction.m"; skip_correct = true)
        data["valve"]["60"]["flow_direction"] = -1
        data["valve"]["60"]["is_bidirectional"] = 0
        data["valve"]["60"]["fr_junction"] = 62
        data["valve"]["60"]["to_junction"] = 1
        GasModels.correct_network_data!(data)
        result = run_gf(data, CRDWPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, DWPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, WPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRDWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE
        result = run_gf(data, LRWPGasModel, mip_solver)
        @test result["termination_status"] == INFEASIBLE ||
              result["termination_status"] == LOCALLY_INFEASIBLE

    end
end
