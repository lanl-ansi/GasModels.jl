using GasModels

import InfrastructureModels
import Memento
import Logging

# Suppress warnings during testing.
const TESTLOG = Memento.getlogger(GasModels)
Memento.setlevel!(TESTLOG, "error")
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Logging.disable_logging(Logging.Info)
Logging.disable_logging(Logging.Warn)

import JuMP

import Ipopt
import Cbc
import Juniper

ipopt_solver = JuMP.optimizer_with_attributes(
    Ipopt.Optimizer,
    "print_level" => 0,
    "sb" => "yes",
    "max_iter" => 1000,
    "acceptable_tol" => 1.0e-2,
)
cbc_solver = JuMP.optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0)
juniper_solver = JuMP.optimizer_with_attributes(
    Juniper.Optimizer,
    "nl_solver" => ipopt_solver,
    "mip_solver" => cbc_solver,
    "log_levels" => [],
)


using Test

misocp_solver = juniper_solver
mip_solver = juniper_solver
lp_solver = ipopt_solver
minlp_solver = juniper_solver
nlp_solver = ipopt_solver

include("common.jl")

@testset "GasModels" begin
    include("data.jl")

    include("ogf.jl")

    include("ls.jl")

    include("nels.jl")

    include("gf.jl")

    include("ne.jl")

    include("storage.jl")

    include("transient.jl")

    # test gaslib-582 dwp gf
    include("debug.jl")

    include("direction_pipe.jl")
    include("direction_short_pipe.jl")
    include("direction_resistor.jl")
    include("direction_valve.jl")
    include("direction_regulator.jl")
    include("direction_compressor.jl")
end
