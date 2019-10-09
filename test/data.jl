@testset "test data handling and parsing" begin
    @testset "gaslib40 summary from dict" begin
        data = GasModels.parse_file("../test/data/matlab/gaslib40.m")
        output = sprint(GasModels.summary, data)

        line_count = count(c -> c == '\n', output)
        @test line_count >= 150 && line_count <= 250
        @test occursin("name: gaslib40", output)
        @test occursin("Table: junction", output)
        @test occursin("Table: pipe", output)
        @test occursin("Table: producer", output)
        @test occursin("Table: consumer", output)
    end

    @testset "check status=false components" begin
        gm = build_model("../test/data/status.m",  MISOCPGasModel, GasModels.post_ls)
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
        gas_file = "../test/data/gaslib-40.m"
        gas_data = GasModels.parse_file(gas_file)
        GasModels.make_si_unit!(gas_data)

        output = sprint(GasModels.summary, gas_data)

        line_count = count(c -> c == '\n', output)

        @test line_count >= 180 && line_count <= 220
        @test occursin("name: gaslib-40", output)
        @test occursin("pipe: 39", output)
        @test occursin("consumer: 29", output)
        @test occursin("junction: 46", output)
        @test occursin("producer: 3", output)
        @test occursin("c_ratio_max: 5", output)
        @test occursin("qg: 201.389", output)
    end

    @testset "check solution summary" begin
        gas_file = "../test/data/gaslib-40.m"
        gas_data = GasModels.parse_file(gas_file)
        result = run_gf("../test/data/gaslib-40.m", MISOCPGasModel, cvx_minlp_solver)

        output = sprint(GasModels.summary, result["solution"])

        line_count = count(c -> c == '\n', output)
        @test line_count >= 100 && line_count <= 125
        @test occursin("pipe: 39", output)
        @test occursin("junction: 46", output)
        @test occursin("Table: pipe", output)
        @test occursin("Table: junction", output)
    end


    @testset "check grail data parsing" begin
        grail_network_file = "../test/data/grail-3.json"
        grail_demand_file = "../test/data/grail-3-profile.json"

        gas_data = GasModels.parse_grail(grail_network_file, grail_demand_file)

        @test length(gas_data["connection"]) == 4
        @test length(gas_data["junction"]) == 4
        @test length(gas_data["producer"]) == 0
        @test length(gas_data["consumer"]) == 2

        #TODO see if we can get one of these test working
        #result = GasModels.run_gf(gas_data, GasModels.MISOCPGasModel, cvx_minlp_solver)
        #result = GasModels.run_ls(gas_data, GasModels.MISOCPGasModel, cvx_minlp_solver)

        #@test result["termination_status"] == OPTIMAL
        #@test result["objective"] == 0.0
    end

    @testset "check resistance calculations" begin
        @testset "calc pipe resistance smeers" begin
            gas_file = "../test/data/gaslib-40.m"
            gas_data = GasModels.parse_file(gas_file)
            gas_ref  = GasModels.build_ref(gas_data)

            @test  isapprox(GasModels._calc_pipe_resistance_smeers(gas_ref[:nw][0], gas_data["pipe"]["32"]), 5.9719269834653; atol=1e-4)
        end

        @testset "calc pipe resistance thorley" begin
            gas_file = "../test/data/A1.m"
            gas_data = GasModels.parse_file(gas_file)
            gas_ref  = GasModels.build_ref(gas_data)

            @test  isapprox(GasModels._calc_pipe_resistance_thorley(gas_ref[:nw][0], gas_data["ne_pipe"]["26"]), (108.24469414437586 * (gas_data["baseP"]^2/gas_data["baseQ"]^2)) / 1e5^2; atol=1e-4)
        end

        @testset "calc resistor resistance simple" begin
            gas_file = "../test/data/gaslib-582.json"
            gas_data = GasModels.parse_file(gas_file)
            gas_ref  = GasModels.build_ref(gas_data)

            @test  isapprox(GasModels._calc_resistor_resistance_simple(gas_ref[:nw][0], gas_data["resistor"]["605"]), (7.434735082304529e10 * (gas_data["baseP"]^2/gas_data["baseQ"]^2)) / 1e5^2; atol=1e-4)
        end
    end
end
