@testset "test gaslib 582 dwp gf" begin
    data = GasModels.parse_file("../test/data/matgas/gaslib-582-G.m")
    gm = GasModels.instantiate_model(data, DWPGasModel, GasModels.build_gf)
    @test length(var(gm, :psqr)) == 605
    @test length(var(gm, :f_pipe)) == 278
    @test length(var(gm, :f_compressor)) == 5
    @test length(var(gm, :f_short_pipe)) == 269
    @test length(var(gm, :f_resistor)) == 8
    @test length(var(gm, :f_valve)) == 26
    @test length(var(gm, :f_regulator)) == 46
    @test length(var(gm, :y_pipe)) == 278
    @test length(var(gm, :y_compressor)) == 5
    @test length(var(gm, :y_short_pipe)) == 269
    @test length(var(gm, :y_resistor)) == 8
    @test length(var(gm, :y_valve)) == 26
    @test length(var(gm, :y_regulator)) == 46
    @test haskey(var(gm), :l) == false
    @test length(var(gm, :v_valve)) == 26

    ref = con(gm, :junction_mass_flow_balance)[100]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set
    @test isapprox(set.value, 0.64266 / get_base_flow(data); atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 1
    var_ref = var(gm, :f_pipe)[128]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)

    # -f[426] - f[77] + f[78] == 0
    ref = con(gm, :junction_mass_flow_balance)[306]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set
    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 3
    var_ref = var(gm, :f_short_pipe)[426]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = var(gm, :f_pipe)[77]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = var(gm, :f_pipe)[78]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # -f[360] - f[269] == -526
    ref = con(gm, :junction_mass_flow_balance)[26]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set
    @test isapprox(set.value, -526.0 / get_base_flow(data); atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = var(gm, :f_short_pipe)[360]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = var(gm, :f_pipe)[269]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)

    # "yp[360] + yp[269] >= 1"
    ref = con(gm, :source_flow)[26]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set
    @test isapprox(set.lower, 1.0; atol = 1e-4)
    @test isa(set, MOI.GreaterThan{Float64})
    @test length(func.terms) == 2

    var_ref = var(gm, :y_short_pipe)[360]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)
    var_ref = var(gm, :y_pipe)[269]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # "yp[483] >= 1"
    ref = con(gm, :sink_flow)[112]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set
    @test isapprox(set.lower, 1.0; atol = 1e-4)
    @test isa(set, MOI.GreaterThan{Float64})
    @test length(func.terms) == 1

    var_ref = var(gm, :y_short_pipe)[483]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # "yn[0] + yn[294] + yn[327] + yn[295] + yn[293] + yn[296] + yp[248] + yp[275] >= 1"
    ref = con(gm, :sink_flow)[32]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set
    @test isapprox(set.lower, -5.0; atol = 1e-4)
    @test isa(set, MOI.GreaterThan{Float64})
    @test length(func.terms) == 8

    var_ref = [
        var(gm, :y_short_pipe)[294],
        var(gm, :y_short_pipe)[293],
        var(gm, :y_short_pipe)[327],
        var(gm, :y_short_pipe)[295],
        var(gm, :y_pipe)[0],
        var(gm, :y_short_pipe)[296],
        var(gm, :y_pipe)[248],
        var(gm, :y_pipe)[275],
    ]
    coeff = [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 1.0, 1.0]

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # yp[238] - yn[239] == 0
    ref = con(gm, :conserve_flow)[523]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.value, 1.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = var(gm, :y_pipe)[239]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)
    var_ref = var(gm, :y_pipe)[238]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # - yn[221] + yn[514] == 0
    ref = con(gm, :conserve_flow)[496]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = var(gm, :y_pipe)[221]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)
    var_ref = var(gm, :y_short_pipe)[514]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)

    # yp[77] - yp[76] == 0
    ref = con(gm, :conserve_flow)[305]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    var_ref = var(gm, :y_pipe)[77]
    @test isapprox(func.terms[var_ref], -1.0; atol = 1e-4)
    var_ref = var(gm, :y_pipe)[76]
    @test isapprox(func.terms[var_ref], 1.0; atol = 1e-4)

    # 0.34408340524232955 yp[161] + p[503] - p[415] <= 0.34408340524232955
    # p[415] - p[503] + 0.34408340524232955 yn[161] <= 0.34408340524232955
    ref = con(gm, :on_off_pressure_drop2)[161]
    var_ref = [
        var(gm, :y_pipe)[161],
        var(gm, :psqr)[503],
        var(gm, :psqr)[415],
    ]
    coeff = [-0.34408340524232955, 1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end


    ref = con(gm, :on_off_pressure_drop1)[161]
    var_ref = [
        var(gm, :y_pipe)[161],
        var(gm, :psqr)[503],
        var(gm, :psqr)[415],
    ]
    coeff = [0.34408340524232955, -1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.34408340524232955; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # 0.12220764306078952 yp[186] - f[186] <= 0.12220764306078952
    # f[186] + 0.12220764306078952 yn[186] <= 0.12220764306078952
    ref = con(gm, :on_off_pipe_flow1)[186]
    var_ref = [var(gm, :y_pipe)[186], var(gm, :f_pipe)[186]]
    coeff = [0.12256998344699432, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.12256998344699432; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_pipe_flow2)[186]
    var_ref = [var(gm, :y_pipe)[186], var(gm, :f_pipe)[186]]
    coeff = [-0.12256998344699432, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # "3.390221630328586 * (p[498] - p[129]) - (f[222] ^ 2.0 - (1.0 - yp[222]) * 2.0) >= 0"
    # "3.390221630328586 * (p[498] - p[129]) - (f[222] ^ 2.0) <= 0"
    # "3.390221630328586 * (p[129] - p[498]) - (f[222] ^ 2.0) <= 0"
    # "3.390221630328586 * (p[129] - p[498]) - (f[222] ^ 2.0 - (1.0 - yn[222]) * 2.0) >= 0"
    ref = con(gm, :weymouth1)[222]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isa(set, MOI.GreaterThan{Float64})
    @test isapprox(set.lower, -2.1698633598; atol = 1e-4)
    @test length(func.terms) == 1

    ref = con(gm, :weymouth2)[222]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set


    @test isa(set, MOI.LessThan{Float64})
    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test length(func.terms) == 1

    ref = con(gm, :weymouth4)[222]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isa(set, MOI.LessThan{Float64})
    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test length(func.terms) == 1

    ref = con(gm, :weymouth3)[222]
    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isa(set, MOI.GreaterThan{Float64})
    @test isapprox(set.lower, 0.0; atol = 1e-4)
    @test length(func.terms) == 1

    # p[302] - p[83] == 0
    ref = con(gm, :short_pipe_pressure_drop)[423]
    var_ref = [var(gm, :psqr)[302], var(gm, :psqr)[83]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.value, 0.0; atol = 1e-4)
    @test isa(set, MOI.EqualTo{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # yp[321] - f[321] <= 1.0
    # f[321] + yn[321] <= 1.0
    ref = con(gm, :on_off_short_pipe_flow1)[321]
    var_ref = [var(gm, :y_short_pipe)[321], var(gm, :f_short_pipe)[321]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_short_pipe_flow2)[321]
    var_ref = [var(gm, :y_short_pipe)[321], var(gm, :f_short_pipe)[321]]
    coeff = [-1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end


    # yp[549] - f[549] <= 1.0
    # f[549] + yn[549] <= 1.0
    ref = con(gm, :on_off_compressor_flow_direction1)[549]
    var_ref = [var(gm, :y_compressor)[549], var(gm, :f_compressor)[549]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end


    ref = con(gm, :on_off_compressor_flow_direction2)[549]
    var_ref = [var(gm, :y_compressor)[549], var(gm, :f_compressor)[549]]
    coeff = [-1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # p[561] - p[560] + 0.4831288389273021 y[551] <= 0.4831288389273021
    # p[561] - 25 p[560] + 0.4831288389273021 y[551] <= 0.4831288389273021
    # p[560] - 25 p[561] + 0.34436018196723495 y[551] <= 0.34436018196723495
    # p[560] - p[561] + 0.34436018196723495 y[551] <= 0.34436018196723495
    ref = con(gm, :on_off_compressor_ratios4)[551]
    var_ref = [
        var(gm, :psqr)[561],
        var(gm, :psqr)[560],
        var(gm, :y_compressor)[551],
    ]
    coeff = [1.0, -1.0, -0.4831288389273021]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_compressor_ratios1)[551]
    var_ref = [
        var(gm, :psqr)[561],
        var(gm, :psqr)[560],
        var(gm, :y_compressor)[551],
    ]
    coeff = [1.0, -25.0, 0.4831288389273021]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.4831288389273021; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_compressor_ratios3)[551]
    var_ref = [
        var(gm, :psqr)[560],
        var(gm, :psqr)[561],
        var(gm, :y_compressor)[551],
    ]
    coeff = [1.0, -25.0, -0.34436018196723495]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_compressor_ratios2)[551]
    var_ref = [
        var(gm, :psqr)[560],
        var(gm, :psqr)[561],
        var(gm, :y_compressor)[551],
    ]
    coeff = [1.0, -1.0, 0.34436018196723495]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.34436018196723495; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # f[558] + yn[558] <= 1.0
    # yp[558] - f[558] <= 1.0
    # - v[558] - f[558] <= 0.0
    # f[558] -  v[558] <= 0.0
    ref = con(gm, :on_off_valve_flow_direction2)[558]
    var_ref = [var(gm, :f_valve)[558], var(gm, :y_valve)[558]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_valve_flow_direction1)[558]
    var_ref = [var(gm, :f_valve)[558], var(gm, :y_valve)[558]]
    coeff = [-1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_valve_flow_direction3)[558]
    var_ref = [var(gm, :f_valve)[558], var(gm, :v_valve)[558]]
    coeff = [-1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_valve_flow_direction4)[558]
    var_ref = [var(gm, :f_valve)[558], var(gm, :v_valve)[558]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # - p[164] + 0.50520177292419455 v[571] + p[170] <= 0.5052017729241945
    # - p[170] + p[164] + 0.5052017729241945 v[571] <= 0.5052017729241945
    ref = con(gm, :valve_pressure_drop2)[571]
    var_ref = [
        var(gm, :psqr)[164],
        var(gm, :v_valve)[571],
        var(gm, :psqr)[170],
    ]
    coeff = [-1.0, 0.5052017729241945, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.5052017729241945; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :valve_pressure_drop1)[571]
    var_ref = [
        var(gm, :psqr)[164],
        var(gm, :v_valve)[571],
        var(gm, :psqr)[170],
    ]
    coeff = [1.0, 0.5052017729241945, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.5052017729241945; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # f[591] - v[591] <= 0.0
    # yp[591] - f[591] <= 1.0
    # f[591] + yn[591] <= 1.0
    # - v[591] - f[591] <= 0.0
    ref = con(gm, :on_off_regulator_flow_direction4)[591]
    var_ref = [var(gm, :v_regulator)[591], var(gm, :f_regulator)[591]]
    coeff = [-1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_regulator_flow_direction1)[591]
    var_ref = [var(gm, :y_regulator)[591], var(gm, :f_regulator)[591]]
    coeff = [1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 1.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_regulator_flow_direction2)[591]
    var_ref = [var(gm, :y_regulator)[591], var(gm, :f_regulator)[591]]
    coeff = [-1.0, 1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :on_off_regulator_flow_direction3)[591]
    var_ref = [var(gm, :v_regulator)[591], var(gm, :f_regulator)[591]]
    coeff = [-1.0, -1.0]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.0; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 2

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    # 0_p[2600217] - 0_p[217] + 0.505201772924194 0_yp[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    # - p[2600217] + 0.505201772924194 yp[585]   + 0.505201772924194 v[585]   <= 1.010403545848389
    # 0_p[2600217] - 0_p[217] + 0.505201772924194 0_yn[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    # 0_p[217] - 0_p[2600217] + 0.505201772924194 0_yn[585] + 0.505201772924194 0_v[585] <= 1.010403545848389
    ref = con(gm, :regulator_pressure_drop2)[585]
    var_ref = [
        var(gm, :psqr)[2600217],
        var(gm, :y_regulator)[585],
        var(gm, :v_regulator)[585],
    ]
    coeff = [-1.0, 0.505201772924194, 0.505201772924194]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 1.010403545848389; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 3

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :regulator_pressure_drop4)[585]
    var_ref = [
        var(gm, :psqr)[217],
        var(gm, :psqr)[2600217],
        var(gm, :y_regulator)[585],
        var(gm, :v_regulator)[585],
    ]
    coeff = [1.0, -1.0, -0.505201772924194, 0.505201772924196]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.505201772924196; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 4

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :regulator_pressure_drop1)[585]
    var_ref = [
        var(gm, :psqr)[217],
        var(gm, :psqr)[2600217],
        var(gm, :y_regulator)[585],
        var(gm, :v_regulator)[585],
    ]
    coeff = [-1.0, 1.0, 0.505201772924194, 0.505201772924194]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 1.010403545848389; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 4

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end

    ref = con(gm, :regulator_pressure_drop3)[585]
    var_ref = [
        var(gm, :psqr)[217],
        var(gm, :psqr)[2600217],
        var(gm, :y_regulator)[585],
        var(gm, :v_regulator)[585],
    ]
    coeff = [-1.0, 1.0, -0.505201772924194, 0.505201772924194]

    constraint_ref = JuMP.constraint_ref_with_index(gm.model, ref.index)
    constraint = JuMP.constraint_object(constraint_ref)
    func = constraint.func
    set = constraint.set

    @test isapprox(set.upper, 0.505201772924196; atol = 1e-4)
    @test isa(set, MOI.LessThan{Float64})
    @test length(func.terms) == 4

    for i = 1:length(var_ref)
        @test isapprox(func.terms[var_ref[i]], coeff[i]; atol = 1e-4)
    end
end
