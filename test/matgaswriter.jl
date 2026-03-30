@testset "matgas file I/O" begin
    @testset "basic file IO" begin
        case_a = parse_file("../test/data/matgas/case-6.m")
        res_a = solve_ogf(case_a, WPGasModel, nlp_solver)
        write_matgas("../test/data/matgas/case-6-mg-writer.m", case_a)
        @test isfile("../test/data/matgas/case-6-mg-writer.m")
        case_b = parse_file("../test/data/matgas/case-6-mg-writer.m")
        res_b = solve_ogf(case_b, WPGasModel, nlp_solver)
        @test isapprox(res_a["objective"], res_b["objective"], atol = 1e-2)
    end
    
    @testset "case 6 elevation file IO" begin
        #this should write the elevation/coordinates data to the extra table
        case_a = parse_file("../test/data/matgas/case-6-elevation.m")
        res_a = solve_ogf(case_a, WPGasModel, nlp_solver)
        write_matgas("../test/data/matgas/case-6-elevation-mgw.m", case_a)
        @test isfile("../test/data/matgas/case-6-elevation-mgw.m")
        case_b = parse_file("../test/data/matgas/case-6-elevation-mgw.m")
        res_b = solve_ogf(case_b, WPGasModel, nlp_solver)
        @test isapprox(res_a["objective"], res_b["objective"], atol = 1e-2)
    end
end

rm("../test/data/matgas/case-6-mg-writer.m")
rm("../test/data/matgas/case-6-mg-elevation-mgw.m")