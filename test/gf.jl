#Check the second order code model
@testset "test misocp gf" begin
    @testset "gaslib 40 case" begin
        result = run_gf("../test/data/gaslib-40.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-6)
    end      
    @testset "gaslib 135 case" begin
        result = run_gf("../test/data/gaslib-135.json", MISOCPGasModel, misocp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-6)
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
      
    source_count = 0             
    sink_count = 0
    degree_count = 0
    for (i,junction) in gm.ref[:junction]
        set = GasModels.constraint_junction_flow_balance(gm, i)
        for ref in set
            c = gm.model.linconstr[ref.idx]
            if i == 100
                # -f[128] == 0.0555264                
                @test isapprox(c.ub, 0.0555264; atol = 1e-4)
                @test JuMP.sense(c) == :(==)
                @test length(c.terms.coeffs) == 1
                @test isapprox(c.terms.coeffs[1], -1.0; atol = 1e-4)
                @test c.terms.vars[1] == gm.var[:f][128]                 
            elseif i == 306
                # -f[426] - f[77] + f[78] == 0
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
                                
            elseif i == 26
                # -f[360] - f[269] == -45.4464
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
        end
        
                   
        if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0 
            set = GasModels.constraint_source_flow(gm, i)
            for constraint in set
                if i == 26
#                    @test string(constraint) == "yp[360] + yp[269] >= 1"
                end              
            end
        else
            source_count = source_count + 1            
        end      
        
        
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
            set = GasModels.constraint_sink_flow(gm, i)
            for constraint in set
                if i == 112
 #                   @test string(constraint) == "yp[483] >= 1"
                elseif i == 32
  #                  @test string(constraint) == "yn[0] + yn[294] + yn[327] + yn[295] + yn[293] + yn[296] + yp[248] + yp[275] >= 1"
                end
            end
        else
            sink_count = sink_count + 1
        end      
        
        if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree"] == 2
            set = GasModels.constraint_conserve_flow(gm, i)
            is_ok = false
            for constraint in set
                if i == 523
                    is_ok = string(constraint) == "yn[239] - yp[238] == 0" || is_ok
                elseif i == 496
                    is_ok = string(constraint) == "yn[221] - yn[514] == 0" || is_ok
                elseif i == 305
                    is_ok = string(constraint) == "yp[77] - yp[76] == 0" || is_ok
                end
            end
            
            if i == 523 || i == 496 || i == 305
   #             @test is_ok == true 
            end
        else
            degree_count = degree_count + 1
        end        
    end
#    @test source_count == 571
 #   @test sink_count == 532
  #  @test degree_count == 372
          
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


