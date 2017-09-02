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
    ref = gm.constraint[:junction_flow_balance][100]  
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.0555264; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 1
    @test isapprox(c.terms.coeffs[1], -1.0; atol = 1e-4)
    @test c.terms.vars[1] == gm.var[:f][128]
    
    # -f[426] - f[77] + f[78] == 0
    ref = gm.constraint[:junction_flow_balance][306]  
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

    # -f[360] - f[269] == -45.4464
    ref = gm.constraint[:junction_flow_balance][26]  
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
    
    # "yp[360] + yp[269] >= 1"    
    ref = gm.constraint[:source_flow][26]  
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
    
    #"yp[483] >= 1"
    ref = gm.constraint[:sink_flow][112]  
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.lb, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :>=
    @test length(c.terms.coeffs) == 1
    @test isapprox(c.terms.coeffs[1], 1.0; atol = 1e-4)
    @test c.terms.vars[1] == gm.var[:yp][483]
  
    #  "yn[0] + yn[294] + yn[327] + yn[295] + yn[293] + yn[296] + yp[248] + yp[275] >= 1"
    ref = gm.constraint[:sink_flow][32]  
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
    
    # yn[239] - yp[238] == 0
    ref = gm.constraint[:conserve_flow1][523]  
    c = gm.model.linconstr[ref.idx]
              
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2                  
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yn][239]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:yp][238]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)                
        else
            @test true == false
        end
    end
            
    # yn[221] - yn[514] == 0
    ref = gm.constraint[:conserve_flow1][496] 
    c = gm.model.linconstr[ref.idx]              
    @test isapprox(c.ub, 0.0; atol = 1e-4) 
    @test JuMP.sense(c) == :(==) 
    @test length(c.terms.coeffs) == 2
                    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yn][221]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:yn][514]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)                
        else
            @test true == false
        end
    end
          
    # yp[77] - yp[76] == 0
    ref = gm.constraint[:conserve_flow1][305]   
    c = gm.model.linconstr[ref.idx]            
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2                    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yp][77]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:yp][76]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)                
        else
            @test true == false
        end
    end
        
    # yp[178] + yn[178] == 1
    ref = gm.constraint[:flow_direction_choice][178]        
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
    
    # 5038.8285000000005 yp[161] - p[503] + p[415] <= 5038.8285000000005
    # p[503] - p[415] + 5038.8285000000005 yn[161] <= 5038.8285000000005
    ref = gm.constraint[:on_off_pressure_drop2][161]  
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 5038.8285000000005; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3                
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yn][161]
            @test isapprox(c.terms.coeffs[i], 5038.8285000000005; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:p][503]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
        elseif c.terms.vars[i] == gm.var[:p][415]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)          
        else
            @test true == false
        end
    end
                
    ref = gm.constraint[:on_off_pressure_drop1][161]  
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 5038.8285000000005; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3                

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yp][161]
            @test isapprox(c.terms.coeffs[i], 5038.8285000000005; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:p][503]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
        elseif c.terms.vars[i] == gm.var[:p][415]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)          
        else
            @test true == false
       end
    end
   
    # 19.877719475620037 yp[186] - f[186] <= 19.877719475620037
    # f[186] + 19.877719475620037 yn[186] <= 19.877719475620037
    ref = gm.constraint[:on_off_pipe_flow_direction1][186]
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 19.877719475620037; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yp][186]
            @test isapprox(c.terms.coeffs[i], 19.877719475620037; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][186]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end
                
    ref = gm.constraint[:on_off_pipe_flow_direction2][186]
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 19.877719475620037; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yn][186]
            @test isapprox(c.terms.coeffs[i], 19.877719475620037; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][186]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end
    
    # "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) >= 0"
    # "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) <= 0"                
    # "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) <= 0"                
    # "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) >= 0"                                
    ref = gm.constraint[:weymouth1][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]
    @test JuMP.sense(c) == :>=    
    @test isapprox(c.lb, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17 
    @test string(ref) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) >= 0"

    ref = gm.constraint[:weymouth2][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]  
    @test JuMP.sense(c) == :<=    
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17 
    @test string(ref) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) <= 0"
    
    ref = gm.constraint[:weymouth4][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]
    @test JuMP.sense(c) == :<=    
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    @test string(ref) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) <= 0"
    
    ref = gm.constraint[:weymouth3][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]
    @test JuMP.sense(c) == :>=    
    @test isapprox(c.lb, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17 
    @test string(ref) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) >= 0"
                    
    # p[302] - p[83] == 0
    ref = gm.constraint[:short_pipe_pressure_drop][423]  
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
            @test true == false
        end
   end
    
    # 325.31057760000004 yp[321] - f[321] <= 325.31057760000004
    # f[321] + 325.31057760000004 yn[321] <= 325.31057760000004
   ref = gm.constraint[:on_off_short_pipe_flow_direction1][321]
   c = gm.model.linconstr[ref.idx]      
   @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
   @test JuMP.sense(c) == :<=
   @test length(c.terms.coeffs) == 2                
   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:yp][321]
           @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:f][321]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
        else
           @test true == false
        end
    end
                
    ref = gm.constraint[:on_off_short_pipe_flow_direction2][321]
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yn][321]
            @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][321]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end
   
    # 325.31057760000004 yp[549] - f[549] <= 325.31057760000004
    # f[549] + 325.31057760000004 yn[549] <= 325.31057760000004
    ref = gm.constraint[:on_off_compressor_flow_direction1][549]
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yp][549]
            @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][549]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end

    ref = gm.constraint[:on_off_compressor_flow_direction2][549]
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yn][549]
            @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][549]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end
       
    # p[560] - p[561] + 5038.8285000000005 yp[551] <= 5038.8285000000005
    # p[560] - 25 p[561] + 4941.5522865 yn[551] <= 4941.5522865
    # p[561] - 25 p[560] - 32931.465056159606 yp[551] <= -32931.465056159606
    # p[561] - p[560] + 5474.778423202535 yn[551] <= 5474.778423202535
    ref = gm.constraint[:on_off_compressor_ratios4][551]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3                
    @test isapprox(c.ub, 5474.778423202535; atol = 1e-4)
    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:p][561]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:p][560]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
        elseif c.terms.vars[i] == gm.var[:yn][551]
            @test isapprox(c.terms.coeffs[i], 5474.778423202535; atol = 1e-4)       
        else
            @test true == false
        end
    end

    ref = gm.constraint[:on_off_compressor_ratios1][551]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3               
    @test isapprox(c.ub, -32931.465056159606; atol = 1e-4)
    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:p][561]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:p][560]
            @test isapprox(c.terms.coeffs[i], -25.0; atol = 1e-4)       
        elseif c.terms.vars[i] == gm.var[:yp][551]
            @test isapprox(c.terms.coeffs[i], -32931.465056159606; atol = 1e-4)       
        else
            @test true == false
        end
    end
   
    ref = gm.constraint[:on_off_compressor_ratios3][551]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3               
    @test isapprox(c.ub, 4941.5522865; atol = 1e-4)
    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:p][560]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
         elseif c.terms.vars[i] == gm.var[:p][561]
            @test isapprox(c.terms.coeffs[i], -25.0; atol = 1e-4)       
         elseif c.terms.vars[i] == gm.var[:yn][551]
            @test isapprox(c.terms.coeffs[i], 4941.5522865; atol = 1e-4)       
         else
            @test true == false
         end
    end

    ref = gm.constraint[:on_off_compressor_ratios2][551]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3               
    @test isapprox(c.ub, 5038.8285000000005; atol = 1e-4)
        
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:p][560]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:p][561]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
        elseif c.terms.vars[i] == gm.var[:yp][551]
            @test isapprox(c.terms.coeffs[i], 5038.8285000000005; atol = 1e-4)       
        else
            @test true == false
       end
    end
    
    # f[558] - 325.31057760000004 v[558] <= 0
    # -325.31057760000004 v[558] - f[558] <= 0
    # 325.31057760000004 yp[558] - f[558] <= 325.31057760000004
    # f[558] + 325.31057760000004 yn[558] <= 325.31057760000004
    ref = gm.constraint[:on_off_valve_flow_direction2][558]   
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
        
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:f][558]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:yn][558]
            @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)       
        else
            @test true == false
        end
    end

    ref = gm.constraint[:on_off_valve_flow_direction1][558]   
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:f][558]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:yp][558]
            @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)       
        else
            @test true == false
       end
    end
        
    ref = gm.constraint[:on_off_valve_flow_direction3][558]   
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 0.0; atol = 1e-4)    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:f][558]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:v][558]
            @test isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)       
        else
            @test true == false
        end
    end
                
    ref = gm.constraint[:on_off_valve_flow_direction4][558]   
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 0.0; atol = 1e-4)
 
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:f][558]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:v][558]
            @test isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)       
        else
            @test true == false
        end
    end
            
    # p[164] + 7398.2791755625 v[571] - p[170] <= 7398.2791755625
    # p[170] - p[164] + 7398.2791755625 v[571] <= 7398.2791755625
    ref = gm.constraint[:on_off_valve_pressure_drop2][571]
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 7398.2791755625; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3                      
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:p][164]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:v][571]
            @test isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)       
        elseif c.terms.vars[i] == gm.var[:p][170]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)          
        else
            @test true == false
        end
    end

    ref = gm.constraint[:on_off_valve_pressure_drop1][571]
    c = gm.model.linconstr[ref.idx]      
    @test isapprox(c.ub, 7398.2791755625; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3                
   
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:p][164]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:v][571]
           @test isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)       
        elseif c.terms.vars[i] == gm.var[:p][170]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)          
        else
           @test true == false
        end
    end
    
    # -325.31057760000004 v[591] - f[591] <= 0
    # f[591] + 325.31057760000004 yn[591] <= 325.31057760000004
    # 325.31057760000004 yp[591] - f[591] <= 325.31057760000004
    # f[591] - 325.31057760000004 v[591] <= 0
    ref = gm.constraint[:on_off_control_valve_flow_direction4][591]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    
    #    ok = true
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:v][591]
            @test isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][591]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end
   
    ref = gm.constraint[:on_off_control_valve_flow_direction1][591]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
   
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yp][591]
            @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][591]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
         else
            @test true == false
         end
    end

    ref = gm.constraint[:on_off_control_valve_flow_direction2][591]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 325.31057760000004; atol = 1e-4)
    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:yn][591]
            @test isapprox(c.terms.coeffs[i], 325.31057760000004; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][591]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end
        
    ref = gm.constraint[:on_off_control_valve_flow_direction3][591]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2                
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:v][591]
            @test isapprox(c.terms.coeffs[i], -325.31057760000004; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:f][591]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
        else
            @test true == false
        end
    end
    
    # p[217] - p[524] + 7398.2791755625 yn[585] + 7398.2791755625 v[585] <= 14796.558351125
    # p[524] - p[217] + 72.47543368414073 yp[585] + 72.47543368414073 v[585] <= 144.95086736828145 
    # -p[217] <= 0
    # -p[524] <= 0
    ref = gm.constraint[:on_off_control_valve_pressure_drop2][585]
    c = gm.model.linconstr[ref.idx]      
    @test JuMP.sense(c) == :<=
    @test isapprox(c.ub, 0.0; atol = 1e-4) && length(c.terms.coeffs) == 1
    
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:p][524]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
   end

   ref = gm.constraint[:on_off_control_valve_pressure_drop4][585]
   c = gm.model.linconstr[ref.idx]      
   @test JuMP.sense(c) == :<=
   @test isapprox(c.ub, 0.0; atol = 1e-4) && length(c.terms.coeffs) == 1
    
   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:p][217]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
       else
           @test true == false
       end
   end

   ref = gm.constraint[:on_off_control_valve_pressure_drop1][585]
   c = gm.model.linconstr[ref.idx]      
   @test JuMP.sense(c) == :<=
   @test isapprox(c.ub, 144.95086736828145; atol = 1e-4) && length(c.terms.coeffs) == 4
    
   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:p][217]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:p][524]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)       
       elseif c.terms.vars[i] == gm.var[:yp][585]
           @test isapprox(c.terms.coeffs[i], 72.47543368414073; atol = 1e-4)       
       elseif c.terms.vars[i] == gm.var[:v][585]
           @test isapprox(c.terms.coeffs[i], 72.47543368414073; atol = 1e-4)          
       else
           @test true == false
       end
   end
  
   ref = gm.constraint[:on_off_control_valve_pressure_drop3][585]
   c = gm.model.linconstr[ref.idx]      
   @test JuMP.sense(c) == :<=    
   @test isapprox(c.ub, 14796.558351125; atol = 1e-4) && length(c.terms.coeffs) == 4
   
   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:p][217]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:p][524]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)       
       elseif c.terms.vars[i] == gm.var[:yn][585]
           @test isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)       
       elseif c.terms.vars[i] == gm.var[:v][585]
           @test isapprox(c.terms.coeffs[i], 7398.2791755625; atol = 1e-4)          
       else
           @test true == false
       end
   end

end


