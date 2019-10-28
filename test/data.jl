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

    @testset "check data parser warnings / errors" begin
        gas_file = "../test/data/warnings.m"

        Memento.setlevel!(TESTLOG, "warn")

        @test_warn(TESTLOG, "pmax 6.0e6 at junction 4 is > 5.861e6 Pa (850 PSI)", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "max power 100.0 MW > 20MW on compressor 1", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "max c-ratio 2.5 on compressor 1 is unrealistic", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "min c-ratio 0.5 on compressor 1 is unrealistic", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "baseP 1000000 is different than calculated baseP = 3.0e6", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "baseQ 7000.0 is different than calculated baseQ = 10033.444816053512", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "temperature of 259.0 K is unrealistic", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "gas specific gravity 0.4 is unrealistic", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "R / molar mass of 800.0 is unrealistic", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "sound speed of 299.0 m/s is unrealistic", GasModels.parse_file(gas_file))
        @test_warn(TESTLOG, "compressibility_factor 0.6 is unrealistic", GasModels.parse_file(gas_file))

        Memento.setlevel!(TESTLOG, "error")

        data = GasModels.parse_file(gas_file)

        data["junction"]["1"]["pmin"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["junction"]["1"]["pmin"] = 3.0

        data["junction"]["1"]["pmax"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["junction"]["1"]["pmax"] = 6.0

        data["pipe"]["1"]["diameter"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["pipe"]["1"]["diameter"] = 0.6

        data["pipe"]["1"]["friction_factor"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["pipe"]["1"]["friction_factor"] = 0.01

        data["compressor"]["1"]["c_ratio_max"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["compressor"]["1"]["c_ratio_max"] = 2.5

        data["compressor"]["1"]["c_ratio_min"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["compressor"]["1"]["c_ratio_min"] = 0.5

        data["compressor"]["1"]["c_ratio_max"] = 0.5
        data["compressor"]["1"]["c_ratio_min"] = 2.5
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["compressor"]["1"]["c_ratio_max"] = 2.5
        data["compressor"]["1"]["c_ratio_min"] = 0.5

        data["compressibility_factor"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["compressibility_factor"] = 0.6

        data["gas_specific_gravity"] = -1
        @test_throws(TESTLOG, ErrorException, GasModels.correct_network_data!(data))
        data["gas_specific_gravity"] = 0.4
    end

    @testset "check topology data functions" begin
        gas_file = "../test/data/warnings.m"
        gas_data = GasModels.parse_file(gas_file)

        gas_data["pipe"]["2"]["status"] = 0
        gas_data["pipe"]["3"]["status"] = 0
        connected_components = GasModels.calc_connected_components(gas_data)
        @test length(connected_components) == 2

        gas_data["junction"]["3"]["status"] = 0
        GasModels.propagate_topology_status!(gas_data)

        @test gas_data["pipe"]["2"]["status"] == 0
        @test gas_data["pipe"]["4"]["status"] == 0
        @test gas_data["consumer"]["2"]["status"] == 0
        @test gas_data["consumer"]["4"]["status"] == 0
    end
end
