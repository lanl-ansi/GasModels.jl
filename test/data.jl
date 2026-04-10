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

    @testset "asset ID overflow" begin
        @test_throws OverflowError case=parse_files("../test/data/matgas/case-6-overflow.m", "../test/data/transient/time-series-case-6a.csv")
    end

    @testset "check status = false components" begin
        gm = instantiate_model("../test/data/status.m", CRDWPGasModel, GasModels.build_ls)

        @test !haskey(ref(gm, nw_id_default, :pipe), 32)

        try
            var(gm, nw_id_default, :pipe)[32] === nothing
            var(gm, nw_id_default, :pipe)[34] === nothing
            @test true == false
        catch
        end

        @test var(gm, nw_id_default, :f_pipe)[14] !== nothing

        try
            var(gm, nw_id_default, :ql)[24] === nothing
            var(gm, nw_id_default, :ql)[29] === nothing
            @test true == false
        catch
        end

        @test var(gm, nw_id_default, :fl)[10004] !== nothing

        try
            var(gm, nw_id_default, :fg)[1] === nothing
            @test true == false
        catch
        end

        @test var(gm, nw_id_default, :fg)[10002] !== nothing
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
        result = solve_gf(gas_file, CRDWPGasModel, misocp_solver)
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

            @test isapprox(GasModels._calc_pipe_resistance(
                gas_data["ne_pipe"]["26"], gas_ref[:it][GasModels.gm_it_sym][:base_length],
                gas_ref[:it][GasModels.gm_it_sym][:base_pressure], gas_ref[:it][GasModels.gm_it_sym][:base_flow],
                gas_ref[:it][GasModels.gm_it_sym][:sound_speed]), 2.3023057843927686; atol = 1e-4)
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

    @testset "check data sources table" begin
        gas_file = "../test/data/matgas/case-6.m"
        gas_data = GasModels.parse_file(gas_file)

        @test haskey(gas_data, "sources")
        @test length(gas_data["sources"]) == 1
        @test gas_data["sources"][1]["name"] == "test" && gas_data["sources"][1]["agreement_year"] == 2020
    end

    @testset "flow partition helpers" begin
        @test_throws ErrorException GasModels.build_flow_partition(-4.0, 6.0, 0)
        @test GasModels.build_flow_partition(1.0, 5.0, 1) == [1.0, 3.0, 5.0]
        @test GasModels.build_flow_partition(-4.0, 6.0, 1) == [-4.0, 0.0, 6.0]
        @test GasModels.build_flow_partition(-4.0, 6.0, 3) ≈ [-4.0, -2.0 / 3.0, 0.0, 8.0 / 3.0, 6.0]
        @test GasModels.build_flow_partition(-4.0, 6.0, [-1.0, 2.0]) == [-4.0, -1.0, 0.0, 2.0, 6.0]
        @test GasModels.build_flow_partition(2.0, 2.0, [2.0]) == [2.0]
        @test_throws ErrorException GasModels.build_flow_partition(-1.0, 1.0, -1)
        @test_throws ErrorException GasModels.build_flow_partition(-1.0, 1.0, [-2.0, 0.0])
    end

    @testset "flow partition unit conversions" begin
        data = Dict{String,Any}(
            "base_pressure" => 100.0,
            "base_density" => 10.0,
            "base_length" => 5.0,
            "base_flow" => 20.0,
            "base_time" => 2.0,
            "base_diameter" => 1.0,
            "si_units" => true,
            "english_units" => false,
            "per_unit" => false,
            "pipe" => Dict(
                "1" => Dict{String,Any}(
                    "id" => 1,
                    "si_units" => true,
                    "english_units" => false,
                    "per_unit" => false,
                    "flow_min" => -40.0,
                    "flow_max" => 60.0,
                    "flow_partition" => [-10.0, 0.0, 30.0],
                ),
            ),
        )

        GasModels.make_per_unit!(data)
        @test data["pipe"]["1"]["flow_min"] == -2.0
        @test data["pipe"]["1"]["flow_max"] == 3.0
        @test data["pipe"]["1"]["flow_partition"] == [-0.5, 0.0, 1.5]

        GasModels.make_si_units!(data)
        @test data["pipe"]["1"]["flow_min"] == -40.0
        @test data["pipe"]["1"]["flow_max"] == 60.0
        @test data["pipe"]["1"]["flow_partition"] == [-10.0, 0.0, 30.0]
    end

    @testset "set flow partitions on parsed data" begin
        data = Dict{String,Any}(
            "pipe" => Dict(
                "1" => Dict{String,Any}("flow_min" => -4.0, "flow_max" => 6.0),
                "2" => Dict{String,Any}("flow_min" => 1.0, "flow_max" => 5.0),
            ),
            "resistor" => Dict(
                "1" => Dict{String,Any}("flow_min" => -3.0, "flow_max" => 3.0),
            ),
        )

        GasModels.set_flow_partitions!(data, 3)

        @test data["pipe"]["1"]["flow_partition"] ≈ [-4.0, -2.0 / 3.0, 0.0, 8.0 / 3.0, 6.0]
        @test data["pipe"]["2"]["flow_partition"] == [1.0, 2.0, 3.0, 4.0, 5.0]
        @test data["resistor"]["1"]["flow_partition"] == [-3.0, -1.0, 0.0, 1.0, 3.0]
    end

    @testset "set flow partitions on parsed data with si points" begin
        data = Dict{String,Any}(
            "base_pressure" => 100.0,
            "base_density" => 10.0,
            "base_length" => 5.0,
            "base_flow" => 20.0,
            "base_time" => 2.0,
            "base_diameter" => 1.0,
            "si_units" => false,
            "english_units" => false,
            "per_unit" => true,
            "pipe" => Dict(
                "1" => Dict{String,Any}("flow_min" => -2.0, "flow_max" => 3.0),
            ),
        )

        GasModels.set_flow_partitions!(data, [-10.0, 30.0]; units = "si")

        @test data["pipe"]["1"]["flow_partition"] == [-2.0, -0.5, 0.0, 1.5, 3.0]
    end
end
