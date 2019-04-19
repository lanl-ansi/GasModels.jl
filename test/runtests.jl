using GasModels


using JuMP

using Ipopt
using Cbc
using Juniper

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0, sb="yes")
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, 
    nl_solver=JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), 
    mip_solver=cbc_solver, log_levels=[])


import LinearAlgebra
using Test

# default setup for solvers
cvx_minlp_solver = juniper_solver
minlp_solver = juniper_solver

@testset "GasModels" begin

include("data.jl")
include("ls.jl") # this one is unstable with Pajarito... dependent on ordering of variables and constraints
include("nels.jl")
include("gf.jl")
include("ne.jl")

end