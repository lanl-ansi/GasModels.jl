

@testset "test minlp gf" begin
    @testset "gaslib 40 5% case" begin
#        result = run_gf("../test/data/gaslib-40-5.json", MINLPGasModel, minlp_solver)
 #       @test result["status"] == :LocalOptimal || result["status"] == :Optimal
  #      @test isapprox(result["objective"], 11.92; atol = 1e-2)
    end
    if minlp_solver != couenne_solver    
        @testset "gaslib 40 10% case" begin
            result = run_gf("../test/data/gaslib-40-10.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 32.83; atol = 1e-2)
        end
        @testset "gaslib 40 25% case" begin
            result = run_gf("../test/data/gaslib-40-25.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 41.08; atol = 1e-2)
        end
        @testset "gaslib 40 50% case" begin
            result = run_gf("../test/data/gaslib-40-50.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 156.06; atol = 1e-2)
        end
        @testset "gaslib 40 75% case" begin
            result = run_gf("../test/data/gaslib-40-75.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 333.01; atol = 1e-2)
        end
        @testset "gaslib 40 100% case" begin
            result = run_gf("../test/data/gaslib-40-100.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 551.64; atol = 1e-2)
        end
        @testset "gaslib 40 125% case" begin
            result = run_gf("../test/data/gaslib-40-125.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 40 150% case" begin
            result = run_gf("../test/data/gaslib-40-125.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible
        end
        
        @testset "gaslib 135 5% case" begin
            result = run_gf("../test/data/gaslib-135-5.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-2)
        end
        @testset "gaslib 135 25% case" begin
            result = run_gf("../test/data/gaslib-135-25.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 60.4; atol = 1e-1)
        end
        @testset "gaslib 135 125% case" begin
            result = run_gf("../test/data/gaslib-135-125.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible
            enddoc
        @testset "gaslib 135 150% case" begin
            result = run_gf("../test/data/gaslib-135-150.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 135 200% case" begin
            result = run_gf("../test/data/gaslib-135-200.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible
        end        
    end
end 


if minlp_solver != bonmin_solver
    @testset "test misocp expansion" begin
        @testset "gaslib 40 case 5%" begin
            result = run_expansion("../test/data/gaslib-40-5.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 11.92; atol = 1e-2)
        end
        @testset "gaslib 40 case 10%" begin
            result = run_expansion("../test/data/gaslib-40-10.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 32.83; atol = 1e-2)
        end    
        @testset "gaslib 40 case 25%" begin
            result = run_expansion("../test/data/gaslib-40-25.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 41.08; atol = 1e-2)
        end    
        @testset "gaslib 40 case 50%" begin
            result = run_expansion("../test/data/gaslib-40-50.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 156.06; atol = 1e-2)
        end    
        @testset "gaslib 40 case 75%" begin
            result = run_expansion("../test/data/gaslib-40-75.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 333.00; atol = 1e-2)
        end    
        @testset "gaslib 40 case 100%" begin
            result = run_expansion("../test/data/gaslib-40-100.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 551.64; atol = 1e-2)
        end
        @testset "gaslib 40 case 125%" begin
            result = run_expansion("../test/data/gaslib-40-125.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 40 case 150%" begin
            result = run_expansion("../test/data/gaslib-40-150.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
    
        @testset "gaslib 135 case 5%" begin
            result = run_expansion("../test/data/gaslib-135-5.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-2)
        end
        @testset "gaslib 135 case 10%" begin
            result = run_expansion("../test/data/gaslib-135-10.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-2)
        end
        @testset "gaslib 135 case 25%" begin
            result = run_expansion("../test/data/gaslib-135-25.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 60.4; atol = 1e-1)
        end
        @testset "gaslib 135 case 50%" begin
            result = run_expansion("../test/data/gaslib-135-50.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 95.3; atol = 1e-1)
        end
        @testset "gaslib 135 case 75%" begin
            result = run_expansion("../test/data/gaslib-135-75.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 451.5; atol = 1e-1)
        end
        @testset "gaslib 135 case 100%" begin
            result = run_expansion("../test/data/gaslib-135-100.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 1234.2; atol = 1e-1)
        end
        @testset "gaslib 135 case 125%" begin
            result = run_expansion("../test/data/gaslib-135-125.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 135 case 150%" begin
            result = run_expansion("../test/data/gaslib-135-150.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 135 case 200%" begin
            result = run_expansion("../test/data/gaslib-135-200.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end

        @testset "gaslib 582 case 5%" begin
            result = run_expansion("../test/data/gaslib-582-5.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end
        @testset "gaslib 582 case 10%" begin
            result = run_expansion("../test/data/gaslib-582-10.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end
        @testset "gaslib 582 case 25%" begin
            result = run_expansion("../test/data/gaslib-582-25.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            if misocp_solver == gurobi_solver   
                @test isapprox(result["objective"], 1.96; atol = 1e-1)
            else    
                @test isapprox(result["objective"], 0.0; atol = 1e-1)  
            end
        end
        @testset "gaslib 582 case 50%" begin
            result = run_expansion("../test/data/gaslib-582-50.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 14.93; atol = 1e-2)
        end
        @testset "gaslib 582 case 200%" begin
            result = run_expansion("../test/data/gaslib-582-200.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 582 case 300%" begin
            result = run_expansion("../test/data/gaslib-582-300.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
    end
end




