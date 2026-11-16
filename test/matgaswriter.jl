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
    @testset "case 6 ne file IO" begin
        case_a = parse_file("../test/data/matgas/case-6-ne.m")
        write_matgas("../test/data/matgas/case-6-ne-mgw.m", case_a)
        @test isfile("../test/data/matgas/case-6-ne-mgw.m")
        case_b = parse_file("../test/data/matgas/case-6-ne-mgw.m")

        @test length(case_a["junction"]) == length(case_b["junction"])
        @test length(case_a["pipe"]) == length(case_b["pipe"])
        @test length(case_a["ne_pipe"]) == length(case_b["ne_pipe"])
        @test length(case_a["compressor"]) == length(case_b["compressor"])
        @test length(case_a["ne_compressor"]) == length(case_b["ne_compressor"])
    end

    @testset "per_unit and base_flow round trip through write_matgas" begin
        # Regression test for a bug where write_matgas wrote the per-unit
        # flag under "mgc.per_unit" (parse_matgas only ever reads
        # "mgc.is_per_unit", the key every real .m fixture uses) and never
        # wrote base_flow at all, so a round-tripped per-unit .m file
        # silently lost its per_unit flag and always got base_flow
        # auto-derived from base_pressure/sound_speed instead of keeping
        # the source case's value. case-6.m's base_flow happens to equal
        # its auto-derived value, so that fixture alone can't catch this;
        # this test sets a base_flow far from the auto-derived value and
        # a per_unit case to actually exercise the round trip.
        case_a = parse_file("../test/data/matgas/case-6.m")
        case_a["per_unit"] = true
        case_a["base_flow"] = 12345.0  # deliberately not base_pressure/sound_speed
        write_matgas("../test/data/matgas/case-6-per-unit-mgw.m", case_a)
        @test isfile("../test/data/matgas/case-6-per-unit-mgw.m")

        case_b = parse_file("../test/data/matgas/case-6-per-unit-mgw.m"; skip_correct = true)
        @test case_b["per_unit"] == true
        @test isapprox(case_b["base_flow"], 12345.0; atol = 1e-6)
    end
end

if isfile("../test/data/matgas/case-6-mg-writer.m")
    rm("../test/data/matgas/case-6-mg-writer.m")
end
if isfile("../test/data/matgas/case-6-elevation-mgw.m")
    rm("../test/data/matgas/case-6-elevation-mgw.m")
end
if isfile("../test/data/matgas/case-6-ne-mgw.m")
    rm("../test/data/matgas/case-6-ne-mgw.m")
end
if isfile("../test/data/matgas/case-6-per-unit-mgw.m")
    rm("../test/data/matgas/case-6-per-unit-mgw.m")
end