using GasModels
using InfrastructureModels
using Memento

if VERSION < v"0.7.0-"
    # suppress warnings during testing
    import Compat: occursin
end

if VERSION > v"0.7.0-"
    # suppress warnings during testing
    GasModels.silence()
end

using JuMP

using Pavito
using Ipopt
using GLPKMathProgInterface
using Juniper


ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
glpk_solver = GLPKSolverMIP()
juniper_solver = JuniperSolver(ipopt_solver)

pavito_solver_glpk = PavitoSolver(mip_solver=glpk_solver, cont_solver=ipopt_solver, mip_solver_drives=false, log_level=1)

using Compat.Test

# default setup for solvers
cvx_minlp_solver = pavito_solver_glpk
minlp_solver = juniper_solver

@testset "GasModels" begin

include("matlab.jl")
include("data.jl")
include("ls.jl")
include("nels.jl")
include("gf.jl")
include("ne.jl")

end
