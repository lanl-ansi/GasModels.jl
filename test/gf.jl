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
    # @testset "gaslib 135 case" begin
        ## THIS TEST IS TIMING OUT ON LINUX in Travis
#        println("Testing gaslib 135 misocp gf")
#        result = run_gf("../test/data/gaslib-135.json", MISOCPGasModel, cvx_minlp_solver)
#        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
#        @test isapprox(result["objective"], 0; atol = 1e-6)
#        data = GasModels.parse_file("../test/data/gaslib-135.json")
#        gm = GasModels.build_generic_model(data, MINLPGasModel, GasModels.post_gf)
#        check_pressure_status(result["solution"], gm)
#        check_ratio(result["solution"], gm)
    # end
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
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set
    @test isapprox(set.value, 0.64266/data["baseQ"]; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 1
    var_ref = gm.var[:nw][gm.cnw][:f][128]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)

    # -f[426] - f[77] + f[78] == 0
    ref = gm.con[:nw][gm.cnw][:junction_mass_flow_balance][306]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set
    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 3
    var_ref = gm.var[:nw][gm.cnw][:f][426]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:f][77]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:f][78]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)
    
    # -f[360] - f[269] == -526
    ref = gm.con[:nw][gm.cnw][:junction_mass_flow_balance][26]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set
    @test isapprox(set.value, -526.0/data["baseQ"]; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = gm.var[:nw][gm.cnw][:f][360]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:f][269]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    
    # "yp[360] + yp[269] >= 1"
    ref = gm.con[:nw][gm.cnw][:source_flow][26]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set
    @test isapprox(set.lower, 1.0; atol = 1e-4)
    @test isa(set, MOI.GreaterThan{Float64})
    @test length(func.terms) == 2

    var_ref = gm.var[:nw][gm.cnw][:yp][360]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:yp][269]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    #"yp[483] >= 1"
    ref = gm.con[:nw][gm.cnw][:sink_flow][112]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set
    @test isapprox(set.lower, 1.0; atol = 1e-4)
    @test isa(set, MOI.GreaterThan{Float64})
    @test length(func.terms) == 1
    
    var_ref = gm.var[:nw][gm.cnw][:yp][483]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)


    #  "yn[0] + yn[294] + yn[327] + yn[295] + yn[293] + yn[296] + yp[248] + yp[275] >= 1"
    ref = gm.con[:nw][gm.cnw][:sink_flow][32]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set
    @test isapprox(set.lower, 1.0; atol = 1e-4)
    @test isa(set, MOI.GreaterThan{Float64})
    @test length(func.terms) == 8

    var_ref = [gm.var[:nw][gm.cnw][:yn][0], gm.var[:nw][gm.cnw][:yn][294], gm.var[:nw][gm.cnw][:yn][327], gm.var[:nw][gm.cnw][:yn][295], gm.var[:nw][gm.cnw][:yn][293], gm.var[:nw][gm.cnw][:yn][296], gm.var[:nw][gm.cnw][:yp][248], gm.var[:nw][gm.cnw][:yp][275] ]
    for i in var_ref
        @test isapprox(func.terms[i], 1.0; atol = 1e-4)
    end

    #  yp[238] - yn[239] == 0
    ref = gm.con[:nw][gm.cnw][:conserve_flow2][523]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = gm.var[:nw][gm.cnw][:yn][239]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:yp][238]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # - yn[221] + yn[514] == 0
    ref = gm.con[:nw][gm.cnw][:conserve_flow2][496]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = gm.var[:nw][gm.cnw][:yn][221]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:yn][514]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # yp[77] - yp[76] == 0
    ref = gm.con[:nw][gm.cnw][:conserve_flow1][305]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = gm.var[:nw][gm.cnw][:yp][77]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:yp][76]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)

    # yp[178] + yn[178] == 1
    ref = gm.con[:nw][gm.cnw][:flow_direction_choice][178]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.value, 1.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = gm.var[:nw][gm.cnw][:yp][178]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)
    var_ref = gm.var[:nw][gm.cnw][:yn][178]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # 0.34408340524232955 yp[161] + p[503] - p[415] <= 0.34408340524232955
    # p[415] - p[503] + 0.34408340524232955 yn[161] <= 0.34408340524232955
    ref = gm.con[:nw][gm.cnw][:on_off_pressure_drop2][161]
    var_ref = [gm.var[:nw][gm.cnw][:yn][161], gm.var[:nw][gm.cnw][:p][503], gm.var[:nw][gm.cnw][:p][415]]
    coeff = [0.34408340524232955, 1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.34408340524232955; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 
        

    ref = gm.con[:nw][gm.cnw][:on_off_pressure_drop1][161]
    var_ref = [gm.var[:nw][gm.cnw][:yp][161], gm.var[:nw][gm.cnw][:p][503], gm.var[:nw][gm.cnw][:p][415]]
    coeff = [0.34408340524232955, -1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.34408340524232955; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # 0.12220764306078952 yp[186] - f[186] <= 0.12220764306078952
    # f[186] + 0.12220764306078952 yn[186] <= 0.12220764306078952
    ref = gm.con[:nw][gm.cnw][:on_off_pipe_flow1][186]
    var_ref = [gm.var[:nw][gm.cnw][:yp][186], gm.var[:nw][gm.cnw][:f][186]]
    coeff = [0.12220764306078952, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.12220764306078952; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_pipe_flow2][186]
    var_ref = [gm.var[:nw][gm.cnw][:yn][186], gm.var[:nw][gm.cnw][:f][186]]
    coeff = [0.12220764306078952, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.12220764306078952; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # "3.390221630328586 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 1.0 ^ 2.0) >= 0"
    # "3.390221630328586 * (p[498] - p[129]) - (f[222] ^ 2.0 + (1.0 - yp[222]) * 1.0 ^ 2.0) <= 0"
    # "3.390221630328586 * (p[129] - p[498]) - (f[222] ^ 2.0 + (1.0 - yn[222]) * 1.0 ^ 2.0) <= 0"
    # "3.390221630328586 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 1.0 ^ 2.0) >= 0"
    ref = gm.con[:nw][gm.cnw][:weymouth1][222]
    c = gm.model.nlp_data.nlconstr[ref.index.value]
    @test JuMP._sense(c) == :>=
    @test isapprox(c.lb, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    
    ref = gm.con[:nw][gm.cnw][:weymouth2][222]
    c = gm.model.nlp_data.nlconstr[ref.index.value]
    @test JuMP._sense(c) == :<=
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    
    ref = gm.con[:nw][gm.cnw][:weymouth4][222]
    c = gm.model.nlp_data.nlconstr[ref.index.value]
    @test JuMP._sense(c) == :<=
    @test isapprox(c.ub, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    
    ref = gm.con[:nw][gm.cnw][:weymouth3][222]
    c = gm.model.nlp_data.nlconstr[ref.index.value]
    @test JuMP._sense(c) == :>=
    @test isapprox(c.lb, 0.0; atol = 1e-4)
    @test length(c.terms.nd) == 17
    
    # p[302] - p[83] == 0
    ref = gm.con[:nw][gm.cnw][:short_pipe_pressure_drop][423]
    var_ref = [gm.var[:nw][gm.cnw][:p][302], gm.var[:nw][gm.cnw][:p][83]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # yp[321] - f[321] <= 1.0
    # f[321] + yn[321] <= 1.0
    ref = gm.con[:nw][gm.cnw][:on_off_short_pipe_flow1][321]
    var_ref = [gm.var[:nw][gm.cnw][:yp][321], gm.var[:nw][gm.cnw][:f][321]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_short_pipe_flow2][321]
    var_ref = [gm.var[:nw][gm.cnw][:yn][321], gm.var[:nw][gm.cnw][:f][321]]
    coeff = [1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 
    

    # yp[549] - f[549] <= 1.0
    # f[549] + yn[549] <= 1.0
    ref = gm.con[:nw][gm.cnw][:on_off_compressor_flow_direction1][549]
    var_ref = [gm.var[:nw][gm.cnw][:yp][549], gm.var[:nw][gm.cnw][:f][549]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 


    ref = gm.con[:nw][gm.cnw][:on_off_compressor_flow_direction2][549]
    var_ref = [gm.var[:nw][gm.cnw][:yn][549], gm.var[:nw][gm.cnw][:f][549]]
    coeff = [1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # p[2200560] - p[560] + 0.4831288389273021 yn[551] <= 0.4831288389273021
    # p[2200560] - 25 p[560] + 0.4831288389273021 yp[551] <= 0.4831288389273021
    # p[560] - p[2200560] + 0.34436018196723495 yp[551] <= 0.34436018196723495
    # p[560] - p[2200560] + 0.34436018196723495 yn[551] <= 0.34436018196723495
    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios4][551]
    var_ref = [gm.var[:nw][gm.cnw][:p][2200560], gm.var[:nw][gm.cnw][:p][560], gm.var[:nw][gm.cnw][:yn][551]]
    coeff = [1.0, -1.0, 0.4831288389273021]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.4831288389273021; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios1][551]
    var_ref = [gm.var[:nw][gm.cnw][:p][2200560], gm.var[:nw][gm.cnw][:p][560], gm.var[:nw][gm.cnw][:yp][551]]
    coeff = [1.0, -25.0, 0.4831288389273021]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.4831288389273021; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios3][551]
    var_ref = [gm.var[:nw][gm.cnw][:p][560], gm.var[:nw][gm.cnw][:p][2200560], gm.var[:nw][gm.cnw][:yn][551]]
    coeff = [1.0, -1.0, 0.34436018196723495]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.34436018196723495; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 


    ref = gm.con[:nw][gm.cnw][:on_off_compressor_ratios2][551]
    var_ref = [gm.var[:nw][gm.cnw][:p][560], gm.var[:nw][gm.cnw][:p][2200560], gm.var[:nw][gm.cnw][:yp][551]]
    coeff = [1.0, -1.0, 0.34436018196723495]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.34436018196723495; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # f[558] + yn[558] <= 1.0
    # yp[558] - f[558] <= 1.0
    # - v[558] - f[558] <= 0.0
    # f[558] -  v[558] <= 0.0
    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction2][558]
    var_ref = [gm.var[:nw][gm.cnw][:f][558], gm.var[:nw][gm.cnw][:yn][558]]
    coeff = [1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction1][558]
    var_ref = [gm.var[:nw][gm.cnw][:f][558], gm.var[:nw][gm.cnw][:yp][558]]
    coeff = [-1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction3][558]
    var_ref = [gm.var[:nw][gm.cnw][:f][558], gm.var[:nw][gm.cnw][:v][558]]
    coeff = [-1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_valve_flow_direction4][558]
    var_ref = [gm.var[:nw][gm.cnw][:f][558], gm.var[:nw][gm.cnw][:v][558]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # - p[164] + 0.50520177292419455 v[571] + p[170] <= 0.5052017729241945
    # - p[170] + p[164] + 0.5052017729241945 v[571] <= 0.5052017729241945
    ref = gm.con[:nw][gm.cnw][:on_off_valve_pressure_drop2][571]
    var_ref = [gm.var[:nw][gm.cnw][:p][164], gm.var[:nw][gm.cnw][:v][571], gm.var[:nw][gm.cnw][:p][170]]
    coeff = [-1.0, 0.5052017729241945, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.5052017729241945; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_valve_pressure_drop1][571]
    var_ref = [gm.var[:nw][gm.cnw][:p][164], gm.var[:nw][gm.cnw][:v][571], gm.var[:nw][gm.cnw][:p][170]]
    coeff = [1.0, 0.5052017729241945, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.5052017729241945; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # f[591] - v[591] <= 0.0
    # yp[591] - f[591] <= 1.0
    # f[591] + yn[591] <= 1.0
    # - v[591] - f[591] <= 0.0
    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction4][591]
    var_ref = [gm.var[:nw][gm.cnw][:v][591], gm.var[:nw][gm.cnw][:f][591]]
    coeff = [-1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction1][591]
    var_ref = [gm.var[:nw][gm.cnw][:yp][591], gm.var[:nw][gm.cnw][:f][591]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction2][591]
    var_ref = [gm.var[:nw][gm.cnw][:yn][591], gm.var[:nw][gm.cnw][:f][591]]
    coeff = [1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_flow_direction3][591]
    var_ref = [gm.var[:nw][gm.cnw][:v][591], gm.var[:nw][gm.cnw][:f][591]]
    coeff = [-1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    # 0_p[2600217] - 0_p[217] + 0.505201772924194 0_yp[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    # - p[2600217] + 0.505201772924194 yp[585]   + 0.505201772924194 v[585]   <= 1.010403545848389
    # 0_p[2600217] - 0_p[217] + 0.505201772924194 0_yn[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    # 0_p[217] - 0_p[2600217] + 0.505201772924194 0_yn[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop2][585]
    var_ref = [gm.var[:nw][gm.cnw][:p][2600217], gm.var[:nw][gm.cnw][:yp][585], gm.var[:nw][gm.cnw][:v][585]]
    coeff = [-1.0, 0.505201772924194, 0.505201772924194]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.010403545848389; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop4][585]
    var_ref = [gm.var[:nw][gm.cnw][:p][217], gm.var[:nw][gm.cnw][:p][2600217], gm.var[:nw][gm.cnw][:yn][585], gm.var[:nw][gm.cnw][:v][585]]
    coeff = [1.0, -1.0, 0.505201772924194, 0.505201772924194]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.010403545848389; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 4

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end 

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop1][585]
    var_ref = [gm.var[:nw][gm.cnw][:p][217], gm.var[:nw][gm.cnw][:p][2600217], gm.var[:nw][gm.cnw][:yp][585], gm.var[:nw][gm.cnw][:v][585]]
    coeff = [-1.0, 1.0, 0.505201772924194, 0.505201772924194]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.010403545848389; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 4

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = gm.con[:nw][gm.cnw][:on_off_control_valve_pressure_drop3][585]
    var_ref = [gm.var[:nw][gm.cnw][:p][217], gm.var[:nw][gm.cnw][:p][2600217], gm.var[:nw][gm.cnw][:yn][585], gm.var[:nw][gm.cnw][:v][585]]
    coeff = [-1.0, 1.0, 0.505201772924194, 0.505201772924194]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func 
    set = constraint.set

    @test isapprox(set.upper, 1.010403545848389; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 4

    for i in 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

end
