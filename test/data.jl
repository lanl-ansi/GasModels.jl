@testset "connection status = false" begin
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
 