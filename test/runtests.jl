using GasModels
using Logging

if VERSION < v"0.7.0-"
    # suppress warnings during testing
    Logging.configure(level=ERROR)
    import Compat: occursin
end

if VERSION > v"0.7.0-"
    # suppress warnings during testing
    disable_logging(Logging.Warn)
end

using JuMP

using Pavito
using Ipopt
#using Cbc
using GLPKMathProgInterface
using Juniper

ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
#cbc_solver = CbcSolver()
glpk_solver = GLPKSolverMIP()
juniper_solver = JuniperSolver(ipopt_solver)

#pavito_solver_cbc = PavitoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, mip_solver_drives=false, log_level=1)
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
