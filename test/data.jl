@testset "status = false" begin
    gm = build_generic_model("../test/data/status.json",  MISOCPGasModel, GasModels.post_ls)
    @test !haskey(gm.ref[:nw][gm.cnw][:connection], 32)

    try
        gm.var[:nw][gm.cnw][:f][32] == nothing
        gm.var[:nw][gm.cnw][:f][34] == nothing
        @test true == false
    catch
    end

    @test gm.var[:nw][gm.cnw][:f][14] != nothing

    try
        gm.var[:nw][gm.cnw][:ql][24] == nothing
        gm.var[:nw][gm.cnw][:ql][29] == nothing
        @test true == false
    catch
    end

    @test gm.var[:nw][gm.cnw][:fl][4] != nothing

    try
        gm.var[:nw][gm.cnw][:fg][1] == nothing
        @test true == false
    catch
    end

    @test gm.var[:nw][gm.cnw][:fg][2] != nothing
end


@testset "data summary" begin
    gas_file = "../test/data/gaslib-40.json"
    gas_data = GasModels.parse_file(gas_file)
    GasModels.make_si_units(gas_data)

    output = sprint(GasModels.summary, gas_data)

    line_count = count(c -> c == '\n', output)
    
    @test line_count >= 175 && line_count <= 200
    @test contains(output, "name: gaslib 40")
    @test contains(output, "connection: 51")
    @test contains(output, "consumer: 29")
    @test contains(output, "junction: 46")
    @test contains(output, "producer: 3")
    @test contains(output, "c_ratio_max: 5")
    @test contains(output, "qgfirm: 201.389")
end

@testset "solution summary" begin
    gas_file = "../test/data/gaslib-40.json"
    gas_data = GasModels.parse_file(gas_file)
    result = run_gf("../test/data/gaslib-40.json", MISOCPGasModel, misocp_solver)

    output = sprint(GasModels.summary, result["solution"])

    line_count = count(c -> c == '\n', output)
    @test line_count >= 100 && line_count <= 125
    @test contains(output, "connection: 51")
    @test contains(output, "junction: 46")
    @test contains(output, "Table: connection")
    @test contains(output, "Table: junction")
end


@testset "grail data" begin
    grail_network_file = "../test/data/grail-3.json"
    grail_demand_file = "../test/data/grail-3-profile.json"

    gas_data = GasModels.parse_grail_file(grail_network_file, grail_demand_file)

    @test length(gas_data["connection"]) == 4
    @test length(gas_data["junction"]) == 4
    @test length(gas_data["producer"]) == 0
    @test length(gas_data["consumer"]) == 2

    #TODO see if we can get one of these test working
    #result = GasModels.run_gf(gas_data, GasModels.MISOCPGasModel, misocp_solver)
    #result = GasModels.run_ls(gas_data, GasModels.MISOCPGasModel, misocp_solver)

    #@test result["status"] == :Optimal
    #@test result["objective"] == 0.0
end

@testset "resistance calculation" begin
    @testset "smeers" begin
        gas_file = "../test/data/gaslib-40.json"
        gas_data = GasModels.parse_file(gas_file)

        @test  isapprox(GasModels.calc_pipe_resistance_smeers(gas_data, gas_data["connection"]["32"]), 5.9719269834653; atol=1e-4)
    end
    
    @testset "thorley" begin
        gas_file = "../test/data/A1.json"
        gas_data = GasModels.parse_file(gas_file)

        @test  isapprox(GasModels.calc_pipe_resistance_thorley(gas_data, gas_data["ne_connection"]["26"]), (108.24469414437586 * (gas_data["baseP"]^2/gas_data["baseQ"]^2)) / 1e5^2; atol=1e-4)
    end
    
    @testset "resistor" begin
        gas_file = "../test/data/gaslib-582.json"
        gas_data = GasModels.parse_file(gas_file)
        @test  isapprox(GasModels.calc_resistor_resistance_simple(gas_data, gas_data["connection"]["605"]), (7.434735082304529e10 * (gas_data["baseP"]^2/gas_data["baseQ"]^2)) / 1e5^2; atol=1e-4)
    end
    
    

end
