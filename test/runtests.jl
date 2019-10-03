using GasModels
using InfrastructureModels
using Memento


using JuMP

using Ipopt
using Cbc
using Juniper

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, print_level=0, sb="yes")
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0, sb="yes"),mip_solver=cbc_solver, log_levels=[])
tol_ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, print_level=0, sb="yes", tol=1e-10)


import LinearAlgebra
using Test

# default setup for solvers
cvx_minlp_solver = juniper_solver
minlp_solver = juniper_solver
cvx_solver = ipopt_solver
abs_minlp_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-12, print_level=0, sb="yes"), mip_solver=cbc_solver, log_levels=[])

@testset "GasModels" begin

include("c.jl")
include("matlab.jl")
include("data.jl")
include("ls.jl")
include("nels.jl")
include("gf.jl")
include("ne.jl")

end
