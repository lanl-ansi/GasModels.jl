function check_pressure_status(sol, gm)
    for (idx,val) in sol["junction"]
        @test val["p"] <= gm.ref[:junction][parse(Int64,idx)]["pmax"]
        @test val["p"] >= gm.ref[:junction][parse(Int64,idx)]["pmin"]
    end
end


#Check the second order code model
@testset "test misocp gf" begin
    @testset "gaslib 40 case" begin
        result = run_gf("../test/data/gaslib-40.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-6)
        data = GasModels.parse_file("../test/data/gaslib-40.json")  
        gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)        
        check_pressure_status(result["solution"], gm)   
    end      
    @testset "gaslib 135 case" begin
        result = run_gf("../test/data/gaslib-135.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-6)
        data = GasModels.parse_file("../test/data/gaslib-135.json")  
        gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)                  
        check_pressure_status(result["solution"], gm) 
    end
end

@testset "test minlp gf mathematical program" begin
    data = GasModels.parse_file("../test/data/gaslib-582.json")
    gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)
    @test length(gm.var[:p])  == 582
    @test length(gm.var[:f])  == 609
    @test length(gm.var[:yp]) == 609
    @test length(gm.var[:yn]) == 609
    @test haskey(gm.var,:l)   == false
    @test length(gm.var[:v])  == 49  
      
     # -f[128] == 0.0555264                                 
    set = GasModels.constraint_junction_flow_balance(gm, 100)
    for ref in set
        c = gm.model.linconstr[ref.idx]
        @test isapprox(c.ub, 0.0555264; atol = 1e-4)
        @test JuMP.sense(c) == :(==)
        @test length(c.terms.coeffs) == 1
        @test isapprox(c.terms.coeffs[1], -1.0; atol = 1e-4)
        @test c.terms.vars[1] == gm.var[:f][128]
    end
    
    # -f[426] - f[77] + f[78] == 0
    set = GasModels.constraint_junction_flow_balance(gm, 306)
    for ref in set
        c = gm.model.linconstr[ref.idx]
        @test isapprox(c.ub, 0.0; atol = 1e-4)
        @test JuMP.sense(c) == :(==)
        @test length(c.terms.coeffs) == 3
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:f][426]
                @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][77]
                @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:f][78]
                @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            else
                @test true == false
            end
        end
    end

    # -f[360] - f[269] == -45.4464
    set = GasModels.constraint_junction_flow_balance(gm, 26)
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.ub, -45.4464; atol = 1e-4)
        @test JuMP.sense(c) == :(==)
        @test length(c.terms.coeffs) == 2
                
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:f][360]
                @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][269]
                @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            else
                @test true == false
            end
        end
    end
    
    # "yp[360] + yp[269] >= 1"    
    set = GasModels.constraint_source_flow(gm, 26)
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.lb, 1.0; atol = 1e-4)
        @test JuMP.sense(c) == :>=
        @test length(c.terms.coeffs) == 2
                
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][360]
                @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:yp][269]
                @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            else
                @test true == false
            end
        end
    end
    
    #"yp[483] >= 1"
    set = GasModels.constraint_sink_flow(gm, 112)            
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.lb, 1.0; atol = 1e-4)
        @test JuMP.sense(c) == :>=
        @test length(c.terms.coeffs) == 1
        @test isapprox(c.terms.coeffs[1], 1.0; atol = 1e-4)
        @test c.terms.vars[1] == gm.var[:yp][483]
    end
 
    #  "yn[0] + yn[294] + yn[327] + yn[295] + yn[293] + yn[296] + yp[248] + yp[275] >= 1"
    set = GasModels.constraint_sink_flow(gm, 32)             
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.lb, 1.0; atol = 1e-4)
        @test JuMP.sense(c) == :>=
        @test length(c.terms.coeffs) == 8
                    
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] in [gm.var[:yn][0], gm.var[:yn][294], gm.var[:yn][327], gm.var[:yn][295], gm.var[:yn][293], gm.var[:yn][296], gm.var[:yp][248], gm.var[:yp][275] ]
                @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            else
                @test true == false
            end
        end
    end
    
    # yn[239] - yp[238] == 0
    set = GasModels.constraint_conserve_flow(gm, 523)
    is_ok = false
    for ref in set
        c = gm.model.linconstr[ref.idx]
        is_ok = true
              
        is_ok = isapprox(c.ub, 0.0; atol = 1e-4) && is_ok
        is_ok = JuMP.sense(c) == :(==) && is_ok
        is_ok = length(c.terms.coeffs) == 2 && is_ok
                    
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yn][239]
                is_ok =  isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4) && is_ok
            elseif c.terms.vars[i] == gm.var[:yp][238]
                is_ok =  isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4) && is_ok                
            else
                is_ok = false
            end
        end
        
        if is_ok
          break
        end
    end
    @test is_ok == true
    
    # yn[221] - yn[514] == 0
    set = GasModels.constraint_conserve_flow(gm, 496)
    is_ok = false
    for ref in set
        c = gm.model.linconstr[ref.idx]
        is_ok = true
              
        is_ok = isapprox(c.ub, 0.0; atol = 1e-4) && is_ok
        is_ok = JuMP.sense(c) == :(==) && is_ok
        is_ok = length(c.terms.coeffs) == 2 && is_ok
                    
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yn][221]
                is_ok =  isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4) && is_ok
            elseif c.terms.vars[i] == gm.var[:yn][514]
                is_ok =  isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4) && is_ok                
            else
                is_ok = false
            end
        end
        
        if is_ok
          break
        end
    end
    @test is_ok == true
    
    # yp[77] - yp[76] == 0
    set = GasModels.constraint_conserve_flow(gm, 305)
    is_ok = false
    for ref in set
        c = gm.model.linconstr[ref.idx]
        is_ok = true
              
        is_ok = isapprox(c.ub, 0.0; atol = 1e-4) && is_ok
        is_ok = JuMP.sense(c) == :(==) && is_ok
        is_ok = length(c.terms.coeffs) == 2 && is_ok
                    
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][77]
                is_ok =  isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4) && is_ok
            elseif c.terms.vars[i] == gm.var[:yp][76]
                is_ok =  isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4) && is_ok                
            else
                is_ok = false
            end
        end
        
        if is_ok
          break
        end
    end
    @test is_ok == true
   
    
    
    
    
    
    
                      
   for (i,connection) in gm.ref[:connection]
       set = GasModels.constraint_flow_direction_choice(gm, i)
       for constraint in set
           if i == 178
   #            @test string(constraint) == "yp[178] + yn[178] == 1"       
           end
       end
       set = GasModels.constraint_parallel_flow(gm, i)
    #   @test set == nothing       
   end

    performed_test1 = false       
    performed_test2 = false        
    performed_test3 = false   
    for i in [collect(keys(gm.ref[:pipe])); collect(keys(gm.ref[:resistor]))]
        set = GasModels.constraint_on_off_pressure_drop(gm, i)
        if i == 161
            is_ok1 = false
            is_ok2 = false
            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "5038.8285000000005 yp[161] - p[503] + p[415] <= 5038.8285000000005"
                is_ok2 = is_ok2 || string(constraint) == "p[503] - p[415] + 5038.8285000000005 yn[161] <= 5038.8285000000005"                
            end
     #       @test is_ok1 && is_ok2 == true
            performed_test1 = true
        end                          
        
        set = GasModels.constraint_on_off_pipe_flow_direction(gm, i)
        if i == 186
            is_ok1 = false
            is_ok2 = false
            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "19.877719475620037 yp[186] - f[186] <= 19.877719475620037"
                is_ok2 = is_ok2 || string(constraint) == "f[186] + 19.877719475620037 yn[186] <= 19.877719475620037"                
            end
      #      @test is_ok1 && is_ok2 == true
            performed_test2 = true
        end 
           
        set = GasModels.constraint_weymouth(gm, i)
        if i == 222
            is_ok1 = false
            is_ok2 = false
            is_ok3 = false
            is_ok4 = false            

            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) >= 0"
                is_ok2 = is_ok2 || string(constraint) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) <= 0"                
                is_ok3 = is_ok3 || string(constraint) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) <= 0"                
                is_ok4 = is_ok4 || string(constraint) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) >= 0"                                
            end
       #     @test is_ok1 == true
        #    @test is_ok2 == true
         #   @test is_ok3 == true
          #  @test is_ok4 == true
            performed_test3 = true
        end 
    end
#    @test performed_test1 == true
 #   @test performed_test2 == true
  #  @test performed_test3 == true
    
    count = 0
    performed_test1 = false      
    performed_test2 = false      
    
    for (i,pipe) in gm.ref[:short_pipe]
        count = count + 1
        set = GasModels.constraint_short_pipe_pressure_drop(gm, i)
        for constraint in set
            if i == 423
   #             @test string(constraint) == "p[302] - p[83] == 0"                     
                performed_test1 = true
            end
        end

        set = GasModels.constraint_on_off_short_pipe_flow_direction(gm, i)      
        if i == 321
            is_ok1 = false
            is_ok2 = false
            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "325.31057760000004 yp[321] - f[321] <= 325.31057760000004"  
                is_ok2 = is_ok2 || string(constraint) == "f[321] + 325.31057760000004 yn[321] <= 325.31057760000004"           
            end
#            @test is_ok1 && isok_2 == true
            performed_test2 = true
        end
    end
    #@test count == 269
    #@test performed_test1 == true
    #@test performed_test2 == true

    performed_test1 = false            
    performed_test2 = false                
    for (i, compressor) in gm.ref[:compressor]
        set = GasModels.constraint_on_off_compressor_flow_direction(gm, i)
        
        if i == 549
            is_ok1 = false
            is_ok2 = false
            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "325.31057760000004 yp[549] - f[549] <= 325.31057760000004"  
                is_ok2 = is_ok2 || string(constraint) == "f[549] + 325.31057760000004 yn[549] <= 325.31057760000004"            
            end
 #           @test is_ok1 == true
  #          @test is_ok2 == true
            performed_test1 = true                        
        end
                
        set = GasModels.constraint_on_off_compressor_ratios(gm, i)  
        if i == 551
            is_ok1 = false
            is_ok2 = false
            is_ok3 = false
            is_ok4 = false

            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "p[560] - p[561] + 5038.8285000000005 yp[551] <= 5038.8285000000005"  
                is_ok2 = is_ok2 || string(constraint) == "p[560] - 25 p[561] + 4941.5522865 yn[551] <= 4941.5522865"            
                is_ok3 = is_ok3 || string(constraint) == "p[561] - 25 p[560] - 32931.465056159606 yp[551] <= -32931.465056159606"  
                is_ok4 = is_ok4 || string(constraint) == "p[561] - p[560] + 5474.778423202535 yn[551] <= 5474.778423202535"             
            end
                        
   #         @test is_ok1 == true
    #        @test is_ok2 == true
     #       @test is_ok3 == true
      #      @test is_ok4 == true       
            performed_test2 = true                                       
        end        
    end
    #@test performed_test1 == true
    #@test performed_test2 == true

    performed_test1 = false                  
    performed_test2 = false                      
    for (i,valve) in gm.ref[:valve]    
        set = GasModels.constraint_on_off_valve_flow_direction(gm, i)
        if i == 558
            is_ok1 = false
            is_ok2 = false
            is_ok3 = false
            is_ok4 = false

            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "f[558] - 325.31057760000004 v[558] <= 0"  
                is_ok2 = is_ok2 || string(constraint) == "-325.31057760000004 v[558] - f[558] <= 0"            
                is_ok3 = is_ok3 || string(constraint) == "325.31057760000004 yp[558] - f[558] <= 325.31057760000004"  
                is_ok4 = is_ok4 || string(constraint) == "f[558] + 325.31057760000004 yn[558] <= 325.31057760000004"             
            end
                        
     #       @test is_ok1 == true
      #      @test is_ok2 == true
       #     @test is_ok3 == true
        #    @test is_ok4 == true       
            performed_test1 = true                                       
        end        
        
        set = GasModels.constraint_on_off_valve_pressure_drop(gm, i)  
        if i == 571
            is_ok1 = false
            is_ok2 = false

            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "p[164] + 7398.2791755625 v[571] - p[170] <= 7398.2791755625"  
                is_ok2 = is_ok2 || string(constraint) == "p[170] - p[164] + 7398.2791755625 v[571] <= 7398.2791755625"            
            end
                        
         #   @test is_ok1 == true
          #  @test is_ok2 == true
            performed_test2 = true                                       
        end        
    end
#    @test performed_test1 == true
 #   @test performed_test2 == true
    
    performed_test1 == false    
    performed_test2 == false    
    for (i, valve) in gm.ref[:control_valve]    
        set = GasModels.constraint_on_off_control_valve_flow_direction(gm, i)

        if i == 591
            is_ok1 = false
            is_ok2 = false
            is_ok3 = false
            is_ok4 = false

            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "-325.31057760000004 v[591] - f[591] <= 0"  
                is_ok2 = is_ok2 || string(constraint) == "f[591] + 325.31057760000004 yn[591] <= 325.31057760000004"            
                is_ok3 = is_ok3 || string(constraint) == "325.31057760000004 yp[591] - f[591] <= 325.31057760000004"  
                is_ok4 = is_ok4 || string(constraint) == "f[591] - 325.31057760000004 v[591] <= 0"             
            end
                        
  #          @test is_ok1 == true
   #         @test is_ok2 == true
    #        @test is_ok3 == true
     #       @test is_ok4 == true       
            performed_test1 = true                                       
        end        
        
        set = GasModels.constraint_on_off_control_valve_pressure_drop(gm, i)  
        if i == 585
            is_ok1 = false
            is_ok2 = false
            is_ok3 = false
            is_ok4 = false

            for constraint in set
                is_ok1 = is_ok1 || string(constraint) == "p[217] - p[524] + 7398.2791755625 yn[585] + 7398.2791755625 v[585] <= 14796.558351125"  
                is_ok2 = is_ok2 || string(constraint) == "p[524] - p[217] + 72.47543368414073 yp[585] + 72.47543368414073 v[585] <= 144.95086736828145"            
                is_ok3 = is_ok3 || string(constraint) == "-p[217] <= 0"  
                is_ok4 = is_ok4 || string(constraint) == "-p[524] <= 0"             
            end
                        
      #      @test is_ok1 == true
       #     @test is_ok2 == true
        #    @test is_ok3 == true
         #   @test is_ok4 == true       
            performed_test2 = true                                       
        end        
    end
#    @test performed_test1 == true
 #   @test performed_test2 == true
              
end


