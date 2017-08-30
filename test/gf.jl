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
      
    # yp[178] + yn[178] == 1
    set = GasModels.constraint_flow_direction_choice(gm, 178)
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.lb, 1.0; atol = 1e-4)
        @test JuMP.sense(c) == :(==)
        @test length(c.terms.coeffs) == 2                
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][178]
                @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:yn][178]
                @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            else
                @test true == false
            end
        end
    end
    
    # 5038.8285000000005 yp[161] - p[503] + p[415] <= 5038.8285000000005
    # p[503] - p[415] + 5038.8285000000005 yn[161] <= 5038.8285000000005
    set = GasModels.constraint_on_off_pressure_drop(gm, 161)
    constraint1 = false
    constraint2 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.ub, 5038.8285000000005; atol = 1e-4)
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 3                

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yn][161]
                ok = ok && isapprox(c.terms.coeffs[i], 5038.8285000000005; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][503]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:p][415]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)          
            else
                ok == false
            end
        end
        if ok
            constraint2 = true
        end
                
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][161]
                ok = ok && isapprox(c.terms.coeffs[i], 5038.8285000000005; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][503]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:p][415]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)          
            else
                ok == false
            end
        end
        if ok
            constraint1 = true
        end                
    end                  
    @test constraint1 = true
    @test constraint2 = true
   
    

    # 19.877719475620037 yp[186] - f[186] <= 19.877719475620037
    # f[186] + 19.877719475620037 yn[186] <= 19.877719475620037
    set = GasModels.constraint_on_off_pipe_flow_direction(gm, 186)
    constraint1 = false
    constraint2 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.ub, 19.877719475620037; atol = 1e-4)
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 2                

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][186]
                ok = ok && isapprox(c.terms.coeffs[i], 19.877719475620037; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][186]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint1 = true
        end
                
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yn][186]
                ok = ok && isapprox(c.terms.coeffs[i], 19.877719475620037; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][186]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint2 = true
        end                
    end                  
    @test constraint1 = true
    @test constraint2 = true
    
 
    # "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) >= 0"
    # "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) <= 0"                
    # "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) <= 0"                
    # "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) >= 0"                                
    set = GasModels.constraint_weymouth(gm, 222)
    ok1 = false
    ok2 = false
    ok3 = false
    ok4 = false           
    for ref in set
        c = gm.model.nlpdata.nlconstr[ref.idx]
        if JuMP.sense(c) == :<=
             @test isapprox(c.ub, 0.0; atol = 1e-4)
        elseif JuMP.sense(c) == :>=
             @test isapprox(c.lb, 0.0; atol = 1e-4)
        else
             @test true == false
        end
        @test length(c.terms.nd) == 17 
        
        ok1 = ok1 || string(ref) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) >= 0"
        ok2 = ok2 || string(ref) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) <= 0"
        ok3 = ok3 || string(ref) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) <= 0"
        ok4 = ok4 || string(ref) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) >= 0"
    end                  
    @test ok1 = true
    @test ok2 = true
    @test ok3 = true
    @test ok4 = true
        
    
    # p[302] - p[83] == 0
    set = GasModels.constraint_short_pipe_pressure_drop(gm, 423) 
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.ub, 0.0; atol = 1e-4)
        @test JuMP.sense(c) == :(==)
        @test length(c.terms.coeffs) == 2                

         for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][302]
                @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][83]
                @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)                            
            else
                ok == false
            end
        end
   end                  
    
    # 325.31057760000004 yp[321] - f[321] <= 325.31057760000004
    # f[321] + 325.31057760000004 yn[321] <= 325.31057760000004
    set = GasModels.constraint_on_off_short_pipe_flow_direction(gm, 321)
    constraint1 = false
    constraint2 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 2                

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][321]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][186]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint1 = true
        end
                
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yn][321]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][321]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint2 = true
        end                
    end                  
    @test constraint1 = true
    @test constraint2 = true
   
    # 325.31057760000004 yp[549] - f[549] <= 325.31057760000004
    # f[549] + 325.31057760000004 yn[549] <= 325.31057760000004
    set = GasModels.constraint_on_off_compressor_flow_direction(gm, 549)
    constraint1 = false
    constraint2 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 2                

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][549]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][549]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint1 = true
        end
                
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yn][549]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][549]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint2 = true
        end                
    end                  
    @test constraint1 = true
    @test constraint2 = true
       
    # p[560] - p[561] + 5038.8285000000005 yp[551] <= 5038.8285000000005
    # p[560] - 25 p[561] + 4941.5522865 yn[551] <= 4941.5522865
    # p[561] - 25 p[560] - 32931.465056159606 yp[551] <= -32931.465056159606
    # p[561] - p[560] + 5474.778423202535 yn[551] <= 5474.778423202535
    set = GasModels.constraint_on_off_compressor_ratios(gm, 551)
    constraint1 = false
    constraint2 = false
    constraint3 = false
    constraint4 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 3                

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][561]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][560]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:yn][551]
                ok = ok && isapprox(c.terms.coeffs[i], 5474.778423202535; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint4 = isapprox(c.ub, 5474.778423202535; atol = 1e-4)
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][561]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][560]
                ok = ok && isapprox(c.terms.coeffs[i], -25.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:yp][551]
                ok = ok && isapprox(c.terms.coeffs[i], -32931.465056159606; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint3 = isapprox(c.ub, -32931.465056159606; atol = 1e-4)
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][560]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][561]
                ok = ok && isapprox(c.terms.coeffs[i], -25.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:yn][551]
                ok = ok && isapprox(c.terms.coeffs[i], 4941.5522865; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint2 = isapprox(c.ub, 4941.5522865; atol = 1e-4)
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][560]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][561]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:yp][551]
                ok = ok && isapprox(c.terms.coeffs[i], 5038.8285000000005; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint1 = isapprox(c.ub, 5038.8285000000005; atol = 1e-4)
        end
                
    end                  
    @test constraint1 = true
    @test constraint2 = true
    @test constraint3 = true
    @test constraint4 = true
    
    # f[558] - 325.31057760000004 v[558] <= 0
    # -325.31057760000004 v[558] - f[558] <= 0
    # 325.31057760000004 yp[558] - f[558] <= 325.31057760000004
    # f[558] + 325.31057760000004 yn[558] <= 325.31057760000004
    set = GasModels.constraint_on_off_valve_flow_direction(gm, 558)
    constraint1 = false
    constraint2 = false
    constraint3 = false
    constraint4 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 2                

        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:f][558]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:yn][558]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint4 = isapprox(c.ub, 325.31057760000004; atol = 1e-4)
        end
        
        

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:f][558]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:yp][558]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint3 = isapprox(c.ub, 325.31057760000004; atol = 1e-4)
        end
        
        
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:f][558]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:v][558]
                ok = ok && isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint2 = isapprox(c.ub, 0.0; atol = 1e-4)
        end
                
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:f][558]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:v][558]
                ok = ok && isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint1 = isapprox(c.ub, 0.0; atol = 1e-4)
        end
        
                  
    end                  
    @test constraint1 = true
    @test constraint2 = true
    @test constraint3 = true
    @test constraint4 = true
    
    
    
    # p[164] + 7398.2791755625 v[571] - p[170] <= 7398.2791755625
    # p[170] - p[164] + 7398.2791755625 v[571] <= 7398.2791755625
    set = GasModels.constraint_on_off_valve_pressure_drop(gm, 571)
    constraint1 = false
    constraint2 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test isapprox(c.ub, 7398.2791755625; atol = 1e-4)
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 3                

        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][164]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:v][571]
                ok = ok && isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:p][170]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)          
            else
                ok == false
            end
        end
        if ok
            constraint2 = true
        end
        
        
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][164]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:v][571]
                ok = ok && isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:p][170]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)          
            else
                ok == false
            end
        end
        if ok
            constraint1 = true
        end
                
    end                  
    @test constraint1 = true
    @test constraint2 = true
    
    # -325.31057760000004 v[591] - f[591] <= 0
    # f[591] + 325.31057760000004 yn[591] <= 325.31057760000004
    # 325.31057760000004 yp[591] - f[591] <= 325.31057760000004
    # f[591] - 325.31057760000004 v[591] <= 0
    set = GasModels.constraint_on_off_control_valve_flow_direction(gm, 591)
    constraint1 = false
    constraint2 = false
    constraint3 = false
    constraint4 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test JuMP.sense(c) == :<=
        @test length(c.terms.coeffs) == 2                

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:v][591]
                ok = ok && isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][591]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint4 = isapprox(c.ub, 0.0; atol = 1e-4)
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yp][591]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][591]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint3 = isapprox(c.ub, 325.31057760000004; atol = 1e-4)
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:yn][591]
                ok = ok && isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][591]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint2 = isapprox(c.ub, 325.31057760000004; atol = 1e-4)
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:v][591]
                ok = ok && isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:f][591]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            else
                ok == false
            end
        end
        if ok
            constraint1 = isapprox(c.ub, 0.0; atol = 1e-4)
        end                  
    end                  
    @test constraint1 = true
    @test constraint2 = true
    @test constraint3 = true
    @test constraint4 = true
    
    # p[217] - p[524] + 7398.2791755625 yn[585] + 7398.2791755625 v[585] <= 14796.558351125
    # p[524] - p[217] + 72.47543368414073 yp[585] + 72.47543368414073 v[585] <= 144.95086736828145 
    # -p[217] <= 0
    # -p[524] <= 0
    set = GasModels.constraint_on_off_control_valve_pressure_drop(gm, 585)
    constraint1 = false
    constraint2 = false
    constraint3 = false
    constraint4 = false
    for ref in set
        c = gm.model.linconstr[ref.idx]      
        @test JuMP.sense(c) == :<=

        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][524]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            else
                ok == false
            end
        end
        if ok
            constraint4 = isapprox(c.ub, 0.0; atol = 1e-4) && length(c.terms.coeffs) == 1
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][217]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            else
                ok == false
            end
        end
        if ok
            constraint3 = isapprox(c.ub, 0.0; atol = 1e-4) && length(c.terms.coeffs) == 1
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][217]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][524]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:yp][585]
                ok = ok && isapprox(c.terms.coeffs[i], 72.47543368414073; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:v][585]
                ok = ok && isapprox(c.terms.coeffs[i], 72.47543368414073; atol = 1e-4)          
            else
                ok == false
            end
        end
        if ok
            constraint2 = isapprox(c.ub, 144.95086736828145; atol = 1e-4) && length(c.terms.coeffs) == 4
        end
        
        ok = true
        for i = 1:length(c.terms.vars)
            if c.terms.vars[i] == gm.var[:p][217]
                ok = ok && isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
            elseif c.terms.vars[i] == gm.var[:p][524]
                ok = ok && isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:yn][585]
                ok = ok && isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)       
            elseif c.terms.vars[i] == gm.var[:v][585]
                ok = ok && isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)          
            else
                ok == false
            end
        end
        if ok
            constraint1 = isapprox(c.ub, 14796.558351125; atol = 1e-4) && length(c.terms.coeffs) == 4
        end
        
    end                  
    @test constraint1 = true
    @test constraint2 = true
    @test constraint3 = true
    @test constraint4 = true
    
end


