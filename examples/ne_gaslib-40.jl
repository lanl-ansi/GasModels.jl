@testset "test nlp ne gaslib 40" begin

    @testset "gaslib 40 150% case" begin
        println("gaslib 40 - NLP 150%")
        result = run_ne("../examples/data/matgas/gaslib-40-150.m", NLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end

end


@testset "test minlp ne gaslib 40" begin
    @testset "gaslib 40 5% case" begin
        println("gaslib 40 - MINLP 5%")
        result = solve_ne("../examples/data/matgas/gaslib-40-5.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 11.92; atol = 1e-2)
    end

    @testset "gaslib 40 10% case" begin
        println("gaslib 40 - MINLP 10%")
        result = solve_ne("../examples/data/matgas/gaslib-40-10.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 32.83; atol = 1e-2)
    end

    @testset "gaslib 40 25% case" begin
        println("gaslib 40 - MINLP 25%")
        result = solve_ne("../examples/data/matgas/gaslib-40-25.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 41.08; atol = 1e-2)
    end

    @testset "gaslib 40 50% case" begin
        println("gaslib 40 - MINLP 50%")
        result = solve_ne("../examples/data/matgas/gaslib-40-50.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 156.06; atol = 1e-2)
    end

    @testset "gaslib 40 75% case" begin
        println("gaslib 40 - MINLP 75%")
        result = solve_ne("../examples/data/matgas/gaslib-40-75.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 333.01; atol = 1e-2)
    end

    @testset "gaslib 40 100% case" begin
        println("gaslib 40 - MINLP 100%")
        result = solve_ne("../examples/data/matgas/gaslib-40-100.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 551.64; atol = 1e-2)
    end

    @testset "gaslib 40 125% case" begin
        println("gaslib 40 - MINLP 125%")
        result = solve_ne("../examples/data/matgas/gaslib-40-125.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end

    @testset "gaslib 40 150% case" begin
        println("gaslib 40 - MINLP 150%")
        result = solve_ne("../examples/data/matgas/gaslib-40-150.m", MINLPGasModel, minlp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == :LocalInfeasible
    end
end

@testset "test misocp ne gaslib 40" begin
    @testset "gaslib 40 case 5%" begin
        println("gaslib 40 - MISOCP 5%")
        result = solve_ne("../examples/data/matgas/gaslib-40-5.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 11.92; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 10%" begin
        println("gaslib 40 - MISOCP 10%")
        result = solve_ne("../examples/data/matgas/gaslib-40-10.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 32.83; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 25%" begin
        println("gaslib 40 - MISOCP 25%")
        result = solve_ne("../examples/data/matgas/gaslib-40-25.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 41.08; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 50%" begin
        println("gaslib 40 - MISOCP 50%")
        result = solve_ne("../examples/data/matgas/gaslib-40-50.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 156.06; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 75%" begin
        println("gaslib 40 - MISOCP 75%")
        result = solve_ne("../examples/data/matgas/gaslib-40-75.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 333.01; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 100%" begin
        println("gaslib 40 - MISOCP 100%")
        result = solve_ne("../examples/data/matgas/gaslib-40-100.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == OPTIMAL
        @test isapprox(result["objective"], 551.64; atol = 1e-2)
        GC.gc()
    end

    @testset "gaslib 40 case 125%" begin
        println("gaslib 40 - MISOCP 125%")
        result = solve_ne("../examples/data/matgas/gaslib-40-125.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end

    @testset "gaslib 40 case 150%" begin
        println("gaslib 40 - MISOCP 150%")
        result = solve_ne("../examples/data/matgas/gaslib-40-150.m", MISOCPGasModel, misocp_solver)
        @test result["termination_status"] == INFEASIBLE || result["termination_status"] == INFEASIBLE_OR_UNBOUNDED
        GC.gc()
    end
end
