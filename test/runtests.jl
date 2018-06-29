using GasModels
using Logging

# suppress warnings during testing
Logging.configure(level=ERROR)

using Pajarito
using Ipopt
using CoinOptServices
using AmplNLWriter
using Cbc
using GLPKMathProgInterface
#using Juniper

bonmin_solver = AmplNLSolver(CoinOptServices.bonmin)
couenne_solver =  AmplNLSolver(CoinOptServices.couenne)
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
cbc_solver = CbcSolver()
glpk_solver = GLPKSolverMIP()
#juniper_solver = JuniperSolver(ipopt_solver)

pajarito_solver_cbc = PajaritoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, log_level=1)
pajarito_solver_glpk = PajaritoSolver(mip_solver=glpk_solver, cont_solver=ipopt_solver, log_level=1)


using Base.Test

# default setup for solvers
misocp_solver = pajarito_solver_cbc
minlp_solver = couenne_solver   

@testset "GasModels" begin

include("data.jl")
include("ls.jl") # this one is unstable with Pajarito... dependent on ordering of variables and constraints
include("nels.jl")
include("gf.jl")
include("ne.jl")

end