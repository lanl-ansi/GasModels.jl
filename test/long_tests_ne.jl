@testset "test minlp ne" begin
    @testset "A1 MINLP case" begin
        println("A1 MINLP")
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/A1.json", MINLPGasModel, couenne_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end

    @testset "A2 MINLP case" begin
        println("A2 MINLP")  
        obj_normalization = 1000000.0                                    
        result = run_ne("../test/data/A2.json", MINLPGasModel, couenne_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end

    @testset "A3 MINLP case" begin
        println("A3 MINLP")          
        obj_normalization = 1000000.0                                    
        result = run_ne("../test/data/A3.json", MINLPGasModel, couenne_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end
    
    @testset "gaslib 40 5% case" begin
        println("gaslib 40 - MINLP 5%")
        obj_normalization = 1000000.0                                
        result = run_ne("../test/data/gaslib-40-5.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 11924688; atol = 1e3)
    end  
        
    @testset "gaslib 40 10% case" begin
        println("gaslib 40 - MINLP 10%")        
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-10.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 32827932; atol = 1e3)
    end
        
    @testset "gaslib 40 25% case" begin
        println("gaslib 40 - MINLP 25%")        
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-25.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 41082189; atol = 1e3)
    end
    
    @testset "gaslib 40 50% case" begin
        println("gaslib 40 - MINLP 50%")      
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-50.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 156055200; atol = 1e3)
    end
        
    @testset "gaslib 40 75% case" begin
        println("gaslib 40 - MINLP 75%")       
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-75.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 333007019; atol = 1e3)
    end
        
    @testset "gaslib 40 100% case" begin
        println("gaslib 40 - MINLP 100%")        
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-100.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 551644663; atol = 1e3)
    end
    
    @testset "gaslib 40 125% case" begin
        println("gaslib 40 - MINLP 125%")       
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-125.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
    end
     
    @testset "gaslib 40 150% case" begin
        println("gaslib 40 - MINLP 150%")        
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-125.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
    end
        
#        @testset "gaslib 135 5% case" begin
 #           println("gaslib 135 - MINLP 5%")        
#            obj_normalization = 1000000.0                            

        
  #          result = run_ne("../test/data/gaslib-135-5.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
   #         @test result["status"] == :LocalOptimal || result["status"] == :Optimal
    #        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-2)
    #    end
#        @testset "gaslib 135 25% case" begin
#            println("gaslib 135 - MINLP 25%")              
#            obj_normalization = 1000000.0                            
  
#            result = run_ne("../test/data/gaslib-135-25.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
#            @test result["status"] == :LocalOptimal || result["status"] == :Optimal
#            @test isapprox(result["objective"]*obj_normalization, 6040000; atol = 1.0)
#        end
    
    @testset "gaslib 135 125% case" begin
        println("gaslib 135 - MINLP 125%")              
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-135-125.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible || result["status"] == :LocalInfeasible
    end
    
    @testset "gaslib 135 150% case" begin
        println("gaslib 135 - MINLP 150%")
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-135-150.json", MINLPGasModel, minlp_solver; obj_normalization = obj_normalization)
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
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/A1.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 144.4; atol = 1e-1)
    end        

    @testset "A2 MISCOP case" begin
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/A2.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization) 
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1687; atol = 1.0)
    end        

    @testset "A3 MISCOP case" begin
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/A3.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)          
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1781; atol = 1.0)
    end

    @testset "gaslib 40 case 5%" begin
        println("gaslib 40 - MISOCP 5%")        
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-5.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 11924688; atol = 1e3)              
    end
        
    @testset "gaslib 40 case 10%" begin
        println("gaslib 40 - MISOCP 10%")
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-10.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 32827932; atol = 1e3)
    end            
            
    @testset "gaslib 40 case 25%" begin
        println("gaslib 40 - MISOCP 25%")        
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-25.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 41082189; atol = 1e3)
    end    
        
    @testset "gaslib 40 case 50%" begin
        println("gaslib 40 - MISOCP 50%")                
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-50.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 156055200; atol = 1e3)
    end    
        
    @testset "gaslib 40 case 75%" begin
        println("gaslib 40 - MISOCP 75%")        
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-75.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 333007019; atol = 1e3)
    end
        
    @testset "gaslib 40 case 100%" begin
        println("gaslib 40 - MISOCP 100%")
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-100.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 551644663; atol = 1e3)
    end
        
    @testset "gaslib 40 case 125%" begin
        println("gaslib 40 - MISOCP 125%")            
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-125.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end
    
    @testset "gaslib 40 case 150%" begin
        println("gaslib 40 - MISOCP 150%")           
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-40-150.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end
    
    @testset "gaslib 135 case 5%" begin
        println("gaslib 135 - MISOCP 5%")
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-135-5.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-2)
    end
       
    @testset "gaslib 135 case 10%" begin
        println("gaslib 135 - MISOCP 10%")                   
        obj_normalization = 1000000.0                             
        result = run_ne("../test/data/gaslib-135-10.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-2)
    end
    
    @testset "gaslib 135 case 25%" begin
        println("gaslib 135 - MISOCP 25%")                  
        obj_normalization = 1000000.0                              
        result = run_ne("../test/data/gaslib-135-25.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 60439674; atol = 1e3)
    end
    
    @testset "gaslib 135 case 50%" begin
        println("gaslib 135 - MISOCP 50%")                    
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-135-50.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 95319858; atol = 1e3)
    end
    
    @testset "gaslib 135 case 75%" begin
        println("gaslib 135 - MISOCP 75%")                       
        obj_normalization = 1000000.0                                 
        result = run_ne("../test/data/gaslib-135-75.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 451591677; atol = 1e3)
    end
    
    @testset "gaslib 135 case 100%" begin
        println("gaslib 135 - MISOCP 100%")                            
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-135-100.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal        
        # This one has some slight numerical instabilities, depending on the version of the misocp solver  
        @test isapprox(result["objective"]*obj_normalization, 1234234179; atol = 1e3) || isapprox(result["objective"]*obj_normalization, 1229077198; atol = 1e3)
    end
       
    @testset "gaslib 135 case 125%" begin
        println("gaslib 135 - MISOCP 125%")      
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-135-125.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end
    
    @testset "gaslib 135 case 150%" begin
        println("gaslib 135 - MISOCP 150%")
        obj_normalization = 1000000.0                                             
        result = run_ne("../test/data/gaslib-135-150.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end
    
    @testset "gaslib 135 case 200%" begin
        println("gaslib 135 - MISOCP 200%") 
        obj_normalization = 1000000.0                            
        result = run_ne("../test/data/gaslib-135-200.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :Infeasible
    end

    @testset "gaslib 582 case 5%" begin
        println("gaslib 582 - MISOCP 5%")
        obj_normalization = 10000.0                            
        result = run_ne("../test/data/gaslib-582-5.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end       
    
    @testset "gaslib 582 case 10%" begin
        println("gaslib 582 - MISOCP 10%")                            
        obj_normalization = 1.0                            
        result = run_ne("../test/data/gaslib-582-10.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)
    end
    
    @testset "gaslib 582 case 25%" begin
        println("gaslib 582 - MISOCP 25%")                                    
        obj_normalization = 1.0                            
        result = run_ne("../test/data/gaslib-582-25.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 0.0; atol = 1e-1)          
    end
     
    @testset "gaslib 582 case 50%" begin
        println("gaslib 582 - MISOCP 50%")                                    
        obj_normalization = 1.0                            
        result = run_ne("../test/data/gaslib-582-50.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"]*obj_normalization, 1.493228019682e7; atol = 1e3)
     end
     
     @testset "gaslib 582 case 200%" begin
         println("gaslib 582 - MISOCP 200%")                                    
         obj_normalization = 1000000.0                            
         result = run_ne("../test/data/gaslib-582-200.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
         @test result["status"] == :Infeasible
     end
     
     @testset "gaslib 582 case 300%" begin
         println("gaslib 582 - MISOCP 300%")                                    
         obj_normalization = 1000000.0                            
         result = run_ne("../test/data/gaslib-582-300.json", MISOCPGasModel, misocp_solver; obj_normalization = obj_normalization)
         @test result["status"] == :Infeasible
     end
end
