@testset "test minlp ne" begin
    @testset "A1 MINLP case" begin
        println("A1 MINLP")
        result = run_ne("../test/data/A1.json", MINLPGasModel, couenne_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.444e-4; atol = 1e-2)
    end

    @testset "A2 MINLP case" begin
        println("A2 MINLP")  
        result = run_ne("../test/data/A2.json", MINLPGasModel, couenne_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.687e-3; atol = 1e-2)
    end

    @testset "A3 MINLP case" begin
        println("A3 MINLP")  
        result = run_ne("../test/data/A3.json", MINLPGasModel, couenne_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.781e-3; atol = 1e-2)
    end
    
    @testset "gaslib 40 5% case" begin
        println("gaslib 40 - MINLP 5%")
        result = run_ne("../test/data/gaslib-40-5.json", MINLPGasModel, minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 11.92; atol = 1e-2)
    end  
        @testset "gaslib 40 10% case" begin
            println("gaslib 40 - MINLP 10%")        
            result = run_ne("../test/data/gaslib-40-10.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 32.83; atol = 1e-2)
        end
        @testset "gaslib 40 25% case" begin
            println("gaslib 40 - MINLP 25%")        
            result = run_ne("../test/data/gaslib-40-25.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 41.08; atol = 1e-2)
        end
        @testset "gaslib 40 50% case" begin
            println("gaslib 40 - MINLP 50%")        
            result = run_ne("../test/data/gaslib-40-50.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 156.06; atol = 1e-2)
        end
        @testset "gaslib 40 75% case" begin
            println("gaslib 40 - MINLP 75%")        
            result = run_ne("../test/data/gaslib-40-75.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 333.01; atol = 1e-2)
        end
        @testset "gaslib 40 100% case" begin
            println("gaslib 40 - MINLP 100%")        
            result = run_ne("../test/data/gaslib-40-100.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 551.64; atol = 1e-2)
        end
        @testset "gaslib 40 125% case" begin
            println("gaslib 40 - MINLP 125%")        
            result = run_ne("../test/data/gaslib-40-125.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
        end
        @testset "gaslib 40 150% case" begin
            println("gaslib 40 - MINLP 150%")        
            result = run_ne("../test/data/gaslib-40-125.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
        end
        
#        @testset "gaslib 135 5% case" begin
 #           println("gaslib 135 - MINLP 5%")        
  #          result = run_ne("../test/data/gaslib-135-5.json", MINLPGasModel, minlp_solver)
   #         @test result["status"] == :LocalOptimal || result["status"] == :Optimal
    #        @test isapprox(result["objective"], 0.0; atol = 1e-2)
    #    end
#        @testset "gaslib 135 25% case" begin
#            println("gaslib 135 - MINLP 25%")                
#            result = run_ne("../test/data/gaslib-135-25.json", MINLPGasModel, minlp_solver)
#            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
#            @test isapprox(result["objective"], 60.4; atol = 1e-1)
#        end
        @testset "gaslib 135 125% case" begin
            println("gaslib 135 - MINLP 125%")                
            result = run_ne("../test/data/gaslib-135-125.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
        end
        @testset "gaslib 135 150% case" begin
            println("gaslib 135 - MINLP 150%")                
            result = run_ne("../test/data/gaslib-135-150.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
        end
        @testset "gaslib 135 200% case" begin
            println("gaslib 135 - MINLP 200%")                
            result = run_ne("../test/data/gaslib-135-200.json", MINLPGasModel, minlp_solver)
            @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
        end        
end 


@testset "test misocp ne" begin
    @testset "A1 MISCOP case" begin
        result = run_ne("../test/data/A1.json", MISOCPGasModel, misocp_solver)
        println(result["objective"])
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.444e-4; atol = 1e-2)
    end        

    @testset "A2 MISCOP case" begin
        result = run_ne("../test/data/A2.json", MISOCPGasModel, misocp_solver) 
        println(result["objective"])
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.687e-3; atol = 1e-2)
    end        

    @testset "A3 MISCOP case" begin
        result = run_ne("../test/data/A3.json", MISOCPGasModel, misocp_solver)
        println(result["objective"])
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 1.781e-3; atol = 1e-2)
    end


    if misocp_solver != bonmin_solver  
        @testset "gaslib 40 case 10%" begin
            println("gaslib 40 - MISOCP 10%")
            result = run_ne("../test/data/gaslib-40-10.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 32.83; atol = 1e-2)
        end            
    end
    
        @testset "gaslib 40 case 5%" begin
            println("gaslib 40 - MISOCP 5%")        
            result = run_ne("../test/data/gaslib-40-5.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 11.92; atol = 1e-2)              
        end
        @testset "gaslib 40 case 25%" begin
            println("gaslib 40 - MISOCP 25%")        
            result = run_ne("../test/data/gaslib-40-25.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 41.08; atol = 1e-2)
        end    
        @testset "gaslib 40 case 50%" begin
            println("gaslib 40 - MISOCP 50%")                
            result = run_ne("../test/data/gaslib-40-50.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 156.06; atol = 1e-2)
        end    
        @testset "gaslib 40 case 75%" begin
            println("gaslib 40 - MISOCP 75%")        
            result = run_ne("../test/data/gaslib-40-75.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 333.00; atol = 1e-2)
        end    
        @testset "gaslib 40 case 100%" begin
            println("gaslib 40 - MISOCP 100%")        
            result = run_ne("../test/data/gaslib-40-100.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 551.64; atol = 1e-2)
        end
        @testset "gaslib 40 case 125%" begin
            println("gaslib 40 - MISOCP 125%")            
            result = run_ne("../test/data/gaslib-40-125.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 40 case 150%" begin
            println("gaslib 40 - MISOCP 150%")            
            result = run_ne("../test/data/gaslib-40-150.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
    
        @testset "gaslib 135 case 5%" begin
            println("gaslib 135 - MISOCP 5%")            
            result = run_ne("../test/data/gaslib-135-5.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-2)
        end
        @testset "gaslib 135 case 10%" begin
            println("gaslib 135 - MISOCP 10%")                    
            result = run_ne("../test/data/gaslib-135-10.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-2)
        end
        @testset "gaslib 135 case 25%" begin
            println("gaslib 135 - MISOCP 25%")                    
            result = run_ne("../test/data/gaslib-135-25.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 60.4; atol = 1e-1)
        end
        @testset "gaslib 135 case 50%" begin
            println("gaslib 135 - MISOCP 50%")                    
            result = run_ne("../test/data/gaslib-135-50.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 95.3; atol = 1e-1)
        end
        @testset "gaslib 135 case 75%" begin
            println("gaslib 135 - MISOCP 75%")                            
            result = run_ne("../test/data/gaslib-135-75.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 451.5; atol = 1e-1)
        end
        @testset "gaslib 135 case 100%" begin
            println("gaslib 135 - MISOCP 100%")                            
            result = run_ne("../test/data/gaslib-135-100.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 1234.2; atol = 1e-1)
        end
        @testset "gaslib 135 case 125%" begin
            println("gaslib 135 - MISOCP 125%")                            
            result = run_ne("../test/data/gaslib-135-125.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 135 case 150%" begin
            println("gaslib 135 - MISOCP 150%")                            
            result = run_ne("../test/data/gaslib-135-150.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 135 case 200%" begin
            println("gaslib 135 - MISOCP 200%")                            
            result = run_ne("../test/data/gaslib-135-200.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end

        @testset "gaslib 582 case 5%" begin
            println("gaslib 582 - MISOCP 5%")                            
            result = run_ne("../test/data/gaslib-582-5.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end
        @testset "gaslib 582 case 10%" begin
            println("gaslib 582 - MISOCP 10%")                            
            result = run_ne("../test/data/gaslib-582-10.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 0.0; atol = 1e-1)
        end
        @testset "gaslib 582 case 25%" begin
            println("gaslib 582 - MISOCP 25%")                                    
            result = run_ne("../test/data/gaslib-582-25.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            if misocp_solver == gurobi_solver   
                @test isapprox(result["objective"], 2.89; atol = 1e-1)
            else    
                @test isapprox(result["objective"], 0.0; atol = 1e-1)  
            end
        end
        @testset "gaslib 582 case 50%" begin
            println("gaslib 582 - MISOCP 50%")                                    
            result = run_ne("../test/data/gaslib-582-50.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
            @test isapprox(result["objective"], 14.93; atol = 1e-2)
        end
        @testset "gaslib 582 case 200%" begin
            println("gaslib 582 - MISOCP 200%")                                    
            result = run_ne("../test/data/gaslib-582-200.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
        @testset "gaslib 582 case 300%" begin
            println("gaslib 582 - MISOCP 300%")                                    
            result = run_ne("../test/data/gaslib-582-300.json", MISOCPGasModel, misocp_solver)
            @test result["status"] == :Infeasible
        end
end
