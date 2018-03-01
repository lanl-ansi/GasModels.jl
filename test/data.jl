@testset "connection status = false" begin
    gm = build_generic_model("../test/data/status.json",  MISOCPGasModel, GasModels.post_gf)
    @test !haskey(gm.ref[:nw][gm.cnw][:connection], 32)
      
    try 
        gm.var[:nw][gm.cnw][:f][32] == nothing
        @test true == false
    catch
    end
    
    @test gm.var[:nw][gm.cnw][:f][14] != nothing
end      
 