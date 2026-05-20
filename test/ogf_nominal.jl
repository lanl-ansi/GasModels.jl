@testset "test ogf nominal" begin
    @testset "nominal dispatch variable bounds" begin
        data = GasModels.parse_file("../test/data/matgas/case-6-nels.m")
        transfer = data["transfer"]["1"]
        transfer["is_dispatchable"] = 1
        transfer["withdrawal_min"] = -12.0
        transfer["withdrawal_max"] = 30.0
        transfer["withdrawal_nominal"] = -5.0
        gm = GasModels.instantiate_model(data, WPGasModel, GasModels.build_ogf; ref_extensions = [ref_nominal_flow_as_capacity!])

        receipt = ref(gm, :receipt, 1)
        delivery = ref(gm, :delivery, 1)
        fg = var(gm, :fg)[1]
        fl = var(gm, :fl)[1]
        ft = var(gm, :ft)[1]

        @test (JuMP.lower_bound(fg), JuMP.upper_bound(fg), JuMP.start_value(fg)) ==
              (receipt["injection_min"], receipt["injection_nominal"], receipt["injection_nominal"])
        @test (JuMP.lower_bound(fl), JuMP.upper_bound(fl), JuMP.start_value(fl)) ==
              (delivery["withdrawal_min"], delivery["withdrawal_nominal"], delivery["withdrawal_nominal"])
        @test (JuMP.lower_bound(ft), JuMP.upper_bound(ft), JuMP.start_value(ft)) == (-5.0, 0.0, -5.0)
    end

    @testset "test wp ogf nominal" begin
        @testset "case 6 ogf nominal" begin
            @_info "Testing OGF Nominal"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits-nominal.m")
            result = solve_ogf_nominal(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.6821; atol = 1e-2)
        end

        @testset "case 6 ogf nominal modified transfer" begin
            @_info "Testing OGF Nominal Modified transfer"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits-nominal.m")
            transfer = data["transfer"]["1"]
            transfer["withdrawal_nominal"] = - transfer["withdrawal_max"] / 2.0

            result = solve_ogf_nominal(data, WPGasModel, nlp_solver)
            GasModels.make_si_units!(result["solution"])
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["solution"]["transfer"]["1"]["ft"], -15.0; atol = 1e-2)
        end

        @testset "case 6 ogf nominal" begin
            @_info "Testing OGF Nominal"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits-nominal.m")
            result = solve_ogf_nominal(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -253.683; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 123.6821; atol = 1e-2)
        end

        @testset "case 6 ogf nominal weymouth lin rel" begin
            @_info "Testing OGF Nominal Linear Relaxation of Pipe Weymouth Physics"
            data = GasModels.parse_file("../test/data/matgas/case-6-no-power-limits-nominal.m")
            result = solve_ogf_nominal(data, LRWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -260.001; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 130.0004; atol = 1e-2)
        end

        @testset "case 6 wp ogf nominal binding energy constraint" begin
            @_info "Testing OGF Nominal Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-nominal.m")
            result = solve_ogf_nominal(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.6788; atol = 1e-2)
        end

        @testset "case 6 wp ogf nominal elevation constraint" begin
            @_info "Testing OGF Nominal Elevation Constraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation-nominal.m")
            result = solve_ogf_nominal(data, WPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.2727; atol = 1e-2)
        end

        @testset "case 6 cwp ogf nominal binding energy constraint" begin
            @_info "Testing OGF Nominal Binding Energy Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-nominal.m")
            result = solve_ogf_nominal(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -167.190; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 60.6788; atol = 1e-2)
        end

        @testset "case 6 cwp ogf nominal elevation constraint" begin
            @_info "Testing OGF Nominal Elevation Cosntraint"
            data = GasModels.parse_file("../test/data/matgas/case-6-elevation-nominal.m")
            result = solve_ogf_nominal(data, CWPGasModel, nlp_solver)
            @test result["termination_status"] in [LOCALLY_SOLVED, ALMOST_LOCALLY_SOLVED, OPTIMAL, :Suboptimal]
            @test isapprox(result["objective"], -191.169; atol = 1e-2)
            GasModels.make_si_units!(result["solution"])
            @test isapprox(result["solution"]["receipt"]["1"]["fg"], 69.2727; atol = 1e-2)
        end
    end
end
