using GasModels

import InfrastructureModels
import Memento

# Suppress warnings during testing.
const TESTLOG = Memento.getlogger(GasModels)
Memento.setlevel!(TESTLOG, "error")
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")

import JuMP

import Ipopt
import Cbc
import Juniper

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0, "sb" => "yes", "max_iter" => 50000)
cbc_solver = JuMP.optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0)
juniper_solver = JuMP.optimizer_with_attributes(Juniper.Optimizer,
    "nl_solver" => JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0, "sb" => "yes"),
    "mip_solver" => cbc_solver, "log_levels" => [])

juniper_solver2 = JuMP.optimizer_with_attributes(Juniper.Optimizer,
        "nl_solver" => JuMP.optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0, "sb" => "yes", "max_iter" => 50000),
        "mip_solver" => cbc_solver, "log_levels" => [])

juniper_solver3 = JuMP.optimizer_with_attributes(Juniper.Optimizer,
            "nl_solver" => JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-5, "print_level" => 0, "sb" => "yes"),
            "mip_solver" => cbc_solver, "log_levels" => [])



using Test

# default setup for solvers
cvx_minlp_solver = juniper_solver
minlp_solver = juniper_solver
cvx_solver = ipopt_solver

include("common.jl")

@testset "GasModels" begin
    include("data.jl")

    include("ogf.jl")

    include("ls.jl")

    include("nels.jl")

    include("gf.jl")

    include("ne.jl")

    include("transient.jl")

    include("debug.jl")  # test gaslib-582 minlp gf

    include("direction_pipe.jl")
    include("direction_short_pipe.jl")
    include("direction_resistor.jl")
    include("direction_valve.jl")
    include("direction_regulator.jl")
    include("direction_compressor.jl")
end
