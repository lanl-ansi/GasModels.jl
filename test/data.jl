@testset "test data handling and parsing" begin
    @testset "GasLib-Integration parsing from zip" begin
        data = GasModels.parse_file("../test/data/gaslib/GasLib-Integration.zip")
        @test length(data["delivery"]) == 7
        @test length(data["receipt"]) == 4
    end

    @testset "gaslib40 summary from dict" begin
        data = GasModels.parse_file("../test/data/matgas/gaslib-40-E.m")
        output = sprint(GasModels.summary, data)

        line_count = count(c -> c == '\n', output)
        @test line_count >= 150 && line_count <= 250
        @test occursin("name: gaslib-40", output)
        @test occursin("Table: junction", output)
        @test occursin("Table: pipe", output)
        @test occursin("Table: receipt", output)
        @test occursin("Table: delivery", output)
    end

    @testset "check status=false components" begin
        gm = instantiate_model("../test/data/status.m", CRDWPGasModel, GasModels.build_ls)
        @test !haskey(gm.ref[:nw][gm.cnw][:pipe], 32)

        try
            gm.var[:nw][gm.cnw][:pipe][32] == nothing
            gm.var[:nw][gm.cnw][:pipe][34] == nothing
            @test true == false
        catch
        end

        @test gm.var[:nw][gm.cnw][:f_pipe][14] != nothing

        try
            gm.var[:nw][gm.cnw][:ql][24] == nothing
            gm.var[:nw][gm.cnw][:ql][29] == nothing
            @test true == false
        catch
        end

        @test gm.var[:nw][gm.cnw][:fl][10004] != nothing

        try
            gm.var[:nw][gm.cnw][:fg][1] == nothing
            @test true == false
        catch
        end

        @test gm.var[:nw][gm.cnw][:fg][10002] != nothing
    end

    @testset "check data summary" begin
        gas_file = "../test/data/matgas/gaslib-40-E.m"
        gas_data = GasModels.parse_file(gas_file)

        output = sprint(GasModels.summary, gas_data)

        line_count = count(c -> c == '\n', output)

        @test line_count >= 180 && line_count <= 240
        @test occursin("name: gaslib-40", output)
        @test occursin("pipe: 39", output)
        @test occursin("delivery: 29", output)
        @test occursin("junction: 40", output)
        @test occursin("receipt: 3", output)
        @test occursin("c_ratio_max: 5", output)
        @test occursin("injection_nominal: 0.333", output)
    end

    @testset "check solution summary" begin
        gas_file = "../test/data/matgas/gaslib-40-E.m"
        gas_data = GasModels.parse_file(gas_file)
        result = run_gf(gas_file, CRDWPGasModel, misocp_solver)

        output = sprint(GasModels.summary, result["solution"])

        line_count = count(c -> c == '\n', output)
        @test line_count >= 100 && line_count <= 150
        @test occursin("pipe: 39", output)
        @test occursin("junction: 40", output)
        @test occursin("Table: pipe", output)
        @test occursin("Table: junction", output)
    end


    @testset "check resistance calculations" begin
        @testset "calc pipe resistance" begin
            gas_file = "../test/data/matgas/A1.m"
            gas_data = GasModels.parse_file(gas_file)
            gas_ref = GasModels.build_ref(gas_data)

            @test isapprox(
                GasModels._calc_pipe_resistance(
                    gas_data["ne_pipe"]["26"],
                    gas_ref[:base_length],
                    gas_ref[:base_pressure],
                    gas_ref[:base_flow],
                    gas_ref[:sound_speed],
                ),
                2.3023057843927686;
                atol = 1e-4,
            )
        end
    end

    @testset "check topology data functions" begin
        gas_file = "../test/data/matgas/case-6.m"
        gas_data = GasModels.parse_file(gas_file)

        gas_data["pipe"]["2"]["status"] = 0
        gas_data["pipe"]["3"]["status"] = 0
        connected_components = GasModels.calc_connected_components(gas_data)
        @test length(connected_components) == 2

        gas_data["junction"]["3"]["status"] = 0
        GasModels.propagate_topology_status!(gas_data)

        @test gas_data["pipe"]["2"]["status"] == 0
        @test gas_data["pipe"]["4"]["status"] == 0
    end
end
