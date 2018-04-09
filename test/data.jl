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
    
    @test gm.var[:nw][gm.cnw][:ql][4] != nothing
      
    try 
        gm.var[:nw][gm.cnw][:qg][1] == nothing
        @test true == false
    catch
    end
    
    @test gm.var[:nw][gm.cnw][:qg][2] != nothing      
end      
 

@testset "gis data" begin
    gas_file = "../test/data/gaslib-40.json"
    gas_data = GasModels.parse_file(gas_file)
    
    @test gas_data["junction"]["2"]["latitude"] == 49.76190172  
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
