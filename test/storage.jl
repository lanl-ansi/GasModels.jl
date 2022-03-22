@testset "Steady State Storage" begin
    @info "Testing GF Storage"
    result = run_gf("../test/data/matgas/case-6-storage.m", CRDWPGasModel, misocp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    result = run_gf("../test/data/matgas/case-6-storage.m", DWPGasModel, minlp_solver)
    @test result["termination_status"] in [ALMOST_LOCALLY_SOLVED, LOCALLY_SOLVED, OPTIMAL]
    result = run_gf("../test/data/matgas/case-6-storage.m", WPGasModel, minlp_solver)
    @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    result = run_gf("../test/data/matgas/case-6-storage.m", LRDWPGasModel, mip_solver)
    @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
    result = run_gf("../test/data/matgas/case-6-storage.m", LRWPGasModel, mip_solver)
    @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
end
