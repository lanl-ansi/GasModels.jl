function check_pressure_status(sol, gm)
    for (idx,val) in sol["junction"]
        @test val["p"] <= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["pmax"]
        @test val["p"] >= gm.ref[:nw][gm.cnw][:junction][parse(Int64,idx)]["pmin"]
    end
end

function check_ratio(sol, gm)
    for (idx,val) in sol["compressor"]
        k = parse(Int64,idx)
        connection = gm.ref[:nw][gm.cnw][:compressor][parse(Int64,idx)]
        @test val["ratio"] <= connection["c_ratio_max"] + 1e-6
        @test val["ratio"] >= connection["c_ratio_min"] - 1e-6
    end
end


#Check the second order code model
@testset "test misocp gf" begin
    @testset "gaslib 40 case" begin
        println("Testing gaslib 40 misocp gf")
        result = run_gf("../test/data/gaslib-40.json", MISOCPGasModel, cvx_minlp_solver)
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-6)
        data = GasModels.parse_file("../test/data/gaslib-40.json")
        gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)
        check_pressure_status(result["solution"], gm)
        check_ratio(result["solution"], gm)
    end
    @testset "gaslib 135 case" begin
        ## THIS TEST IS TIMING OUT ON LINUX in Travis
#        println("Testing gaslib 135 misocp gf")
#        result = run_gf("../test/data/gaslib-135.json", MISOCPGasModel, cvx_minlp_solver)
#        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
#        @test isapprox(result["objective"], 0; atol = 1e-6)
#        data = GasModels.parse_file("../test/data/gaslib-135.json")
#        gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)
#        check_pressure_status(result["solution"], gm)
#        check_ratio(result["solution"], gm)
    end
end

@testset "test minlp gf mathematical program" begin
    data = GasModels.parse_file("../test/data/gaslib-582.json")
    gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)
    @test length(gm.var[:nw][gm.cnw][:p])  == 610
    @test length(gm.var[:nw][gm.cnw][:f])  == 637
    @test length(gm.var[:nw][gm.cnw][:yp]) == 637
    @test length(gm.var[:nw][gm.cnw][:yn]) == 637
    @test haskey(gm.var[:nw][gm.cnw],:l)   == false
    @test length(gm.var[:nw][gm.cnw][:v])  == 72

    ref = gm.con[:nw][gm.cnw][:junction_mass_flow_balance][100]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.64266/data["baseQ"]; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 1
    @test isapprox(c.terms.coeffs[1], -1.0; atol = 1e-4)
    @test c.terms.vars[1] == gm.var[:nw][gm.cnw][:f][128]

    # -f[426] - f[77] + f[78] == 0
    ref = gm.con[:nw][gm.cnw][:junction_mass_flow_balance][306]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 3
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][426]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][77]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][78]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # -f[360] - f[269] == -526
    ref = gm.con[:nw][gm.cnw][:junction_mass_flow_balance][26]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, -526/data["baseQ"]; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][360]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][269]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
         else
            @test true == false
         end
    end

    # "yp[360] + yp[269] >= 1"
    ref = gm.con[:nw][gm.cnw][:source_flow][26]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.lb, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :>=
    @test length(c.terms.coeffs) == 2

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][360]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][269]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    #"yp[483] >= 1"
    ref = gm.con[:nw][gm.cnw][:sink_flow][112]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.lb, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :>=
    @test length(c.terms.coeffs) == 1
    @test isapprox(c.terms.coeffs[1], 1.0; atol = 1e-4)
    @test c.terms.vars[1] == gm.var[:nw][gm.cnw][:yp][483]

    #  "yn[0] + yn[294] + yn[327] + yn[295] + yn[293] + yn[296] + yp[248] + yp[275] >= 1"
    ref = gm.con[:nw][gm.cnw][:sink_flow][32]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.lb, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :>=
    @test length(c.terms.coeffs) == 8

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] in [gm.var[:nw][gm.cnw][:yn][0], gm.var[:nw][gm.cnw][:yn][294], gm.var[:nw][gm.cnw][:yn][327], gm.var[:nw][gm.cnw][:yn][295], gm.var[:nw][gm.cnw][:yn][293], gm.var[:nw][gm.cnw][:yn][296], gm.var[:nw][gm.cnw][:yp][248], gm.var[:nw][gm.cnw][:yp][275] ]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # yn[239] - yp[238] == 0
    ref = gm.con[:nw][gm.cnw][:conserve_flow2][523]
    c = gm.model.linconstr[ref.idx]

    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][239]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][238]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # yn[221] - yn[514] == 0
    ref = gm.con[:nw][gm.cnw][:conserve_flow2][496]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][221]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][514]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # yp[77] - yp[76] == 0
    ref = gm.con[:nw][gm.cnw][:conserve_flow1][305]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][77]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][76]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # yp[178] + yn[178] == 1
    ref = gm.con[:nw][gm.cnw][:flow_direction_choice][178]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.lb, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][178]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][178]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # 0.34408340524232955 yp[161] - p[503] + p[415] <= 0.34408340524232955
    # p[503] - p[415] + 0.34408340524232955 yn[161] <= 0.34408340524232955
    ref = gm.con[:nw][gm.cnw][:on_off_pressure_drop2][161]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.34408340524232955; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][161]
            @test isapprox(c.terms.coeffs[i], 0.34408340524232955; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][503]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][415]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_pressure_drop1][161]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.34408340524232955; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][161]
            @test isapprox(c.terms.coeffs[i], 0.34408340524232955; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][503]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][415]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
       end
    end

    # 0.12220764306078952 yp[186] - f[186] <= 0.12220764306078952
    # f[186] + 0.12220764306078952 yn[186] <= 0.12220764306078952
    ref = gm.con[:nw][gm.cnw][:on_off_pipe_flow1][186]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.12220764306078952; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][186]
            @test isapprox(c.terms.coeffs[i], 0.12220764306078952; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][186]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_pipe_flow2][186]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.12220764306078952; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][186]
            @test isapprox(c.terms.coeffs[i], 0.12220764306078952; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][186]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) >= 0"
    # "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) <= 0"
    # "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) <= 0"
    # "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) >= 0"
    ref = gm.con[:nw][gm.cnw][:weymouth1][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]
    @test JuMP.sense(c) == :>=
    @test isapprox(c.lb, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    #@test string(ref) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) >= 0"

    ref = gm.con[:nw][gm.cnw][:weymouth2][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    #@test string(ref) == "6.124894594 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 325.31057760000004 ^ 2.0) <= 0"

    ref = gm.con[:nw][gm.cnw][:weymouth4][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    #@test string(ref) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) <= 0"

    ref = gm.con[:nw][gm.cnw][:weymouth3][222]
    c = gm.model.nlpdata.nlconstr[ref.idx]
    @test JuMP.sense(c) == :>=
    @test isapprox(c.lb, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    #@test string(ref) == "6.124894594 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 325.31057760000004 ^ 2.0) >= 0"

    # p[302] - p[83] == 0
    ref = gm.con[:nw][gm.cnw][:short_pipe_pressure_drop][423]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test JuMP.sense(c) == :(==)
    @test length(c.terms.coeffs) == 2

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][302]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][83]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
   end

    # 1.0 yp[321] - f[321] <= 325.31057760000004
    # f[321] + 1.0 yn[321] <= 325.31057760000004
   ref = gm.con[:nw][gm.cnw][:on_off_short_pipe_flow1][321]
   c = gm.model.linconstr[ref.idx]
   @test isapprox(c.ub, 1.0; atol = 1e-4)
   @test JuMP.sense(c) == :<=
   @test length(c.terms.coeffs) == 2
   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][321]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][321]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
           @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_short_pipe_flow2][321]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][321]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][321]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # 1.0 yp[549] - f[549] <= 1.0
    # f[549] + 1.0 yn[549] <= 1.0
    ref = gm.con[:nw][gm.cnw][:on_off_compressor_flow_direction1][549]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][549]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][549]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_compressor_flow_direction2][549]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 1.0; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][549]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][549]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # p[2200560] - 25 p[560] + 0.4831288389273021 yp[551] <= 0.4831288389273021
    # p[560] - 25 p[2200560] + 0.34436018196723495 yn[551] <= 0.34436018196723495
    # p[560] - p[2200560] +0.34436018196723495 yp[551] <= 0.34436018196723495
    # p[2200560] - p[560] + 0.4831288389273021 yn[551] <= 0.4831288389273021
    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios4][551]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3

    @test isapprox(c.ub, 0.4831288389273021; atol = 1e-4)
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2200560]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][560]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][551]
            @test isapprox(c.terms.coeffs[i], 0.4831288389273021; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios1][551]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3
    @test isapprox(c.ub,0.4831288389273021; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2200560]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][560]
            @test isapprox(c.terms.coeffs[i], -25.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][551]
            @test isapprox(c.terms.coeffs[i], 0.4831288389273021; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios3][551]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3

    @test isapprox(c.ub, 0.34436018196723495; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][560]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
         elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2200560]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
         elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][551]
            @test isapprox(c.terms.coeffs[i], 0.34436018196723495; atol = 1e-4)
         else
            @test true == false
         end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios2][551]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3
    @test isapprox(c.ub, 0.34436018196723495; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][560]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2200560]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][551]
            @test isapprox(c.terms.coeffs[i], 0.34436018196723495; atol = 1e-4)
        else
            @test true == false
       end
    end

    # f[558] - 1882.584361111111 v[558] <= 0
    # -1.0 v[558] - f[558] <= 0
    # 1.0 yp[558] - f[558] <= 1.0
    # f[558] + 1.0 yn[558] <= 1.0
    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction2][558]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 1.0; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][558]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][558]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction1][558]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 1.0; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][558]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][558]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
       end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction3][558]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][558]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][558]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction4][558]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 0.0; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][558]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][558]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # p[164] + 0.50520177292419455 v[571] - p[170] <= 0.5052017729241945
    # p[170] - p[164] + 0.5052017729241945 v[571] <= 0.5052017729241945
    ref = gm.con[:nw][gm.cnw][:on_off_valve_pressure_drop2][571]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.5052017729241945; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][164]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][571]
            @test isapprox(c.terms.coeffs[i], 0.5052017729241945; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][170]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_valve_pressure_drop1][571]
    c = gm.model.linconstr[ref.idx]
    @test isapprox(c.ub, 0.5052017729241945; atol = 1e-4)
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 3

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][164]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][571]
           @test isapprox(c.terms.coeffs[i], 0.5052017729241945; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][170]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
           @test true == false
        end
    end

    # -1.0 v[591] - f[591] <= 0
    # f[591] + 325.31057760000004 yn[591] <= 1.0
    # 1.0 yp[591] - f[591] <= 1.0
    # f[591] - 1.0 v[591] <= 0
    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction4][591]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 0.0; atol = 1e-4)

    #    ok = true
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][591]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][591]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction1][591]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 1.0; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][591]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][591]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
         else
            @test true == false
         end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction2][591]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 1.0; atol = 1e-4)

    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][591]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][591]
            @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction3][591]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test length(c.terms.coeffs) == 2
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    for i = 1:length(c.terms.vars)
        if c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][591]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:f][591]
            @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
        else
            @test true == false
        end
    end

    # 0_p[2600217] - 0_p[217] + 0.505201772924194 0_yp[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    # - p[2600217] + 0.505201772924194 yp[585]   + 0.505201772924194 v[585]   <= 1.010403545848389
    # 0_p[2600217] - 0_p[217] + 0.505201772924194 0_yn[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    # 0_p[217] - 0_p[2600217] + 0.505201772924194 0_yn[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop2][585]
    c = gm.model.linconstr[ref.idx]
    @test JuMP.sense(c) == :<=
    @test isapprox(c.ub, 1.010403545848389; atol = 1e-4) && length(c.terms.coeffs) == 3

    for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2600217]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       else
           @test true == false
       end
   end

   ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop4][585]
   c = gm.model.linconstr[ref.idx]
   @test JuMP.sense(c) == :<=
   @test isapprox(c.ub, 1.010403545848389; atol = 1e-4) && length(c.terms.coeffs) == 4

   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][217]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2600217]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       else
           @test true == false
       end
   end

   ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop1][585]
   c = gm.model.linconstr[ref.idx]
   @test JuMP.sense(c) == :<=
   @test isapprox(c.ub, 1.010403545848389; atol = 1e-4) && length(c.terms.coeffs) == 4

   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][217]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2600217]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yp][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       else
           @test true == false
       end
   end

   ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop3][585]
   c = gm.model.linconstr[ref.idx]
   @test JuMP.sense(c) == :<=
   @test isapprox(c.ub, 1.010403545848389; atol = 1e-4) && length(c.terms.coeffs) == 4

   for i = 1:length(c.terms.vars)
       if c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][217]
           @test isapprox(c.terms.coeffs[i], -1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:p][2600217]
           @test isapprox(c.terms.coeffs[i], 1.0; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:yn][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       elseif c.terms.vars[i] == gm.var[:nw][gm.cnw][:v][585]
           @test isapprox(c.terms.coeffs[i], 0.505201772924194; atol = 1e-4)
       else
           @test true == false
       end
   end

end
