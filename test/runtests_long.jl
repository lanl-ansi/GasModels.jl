using GasModels
using Logging
# suppress warnings during testing
Logging.configure(level=ERROR)

using Ipopt
using Pajarito
using GLPKMathProgInterface
using ECOS
using SCS
using AmplNLWriter
using CoinOptServices
using Gurobi
using CPLEX
using Cbc
using Base.Test


#baron_solver = BaronSolver() # has too many backward dependecies
couenne_solver =  AmplNLSolver(CoinOptServices.couenne)
bonmin_solver = OsilBonminSolver() # until BonminNLSolver supports quadratic constraints declared with @constraint
gurobi_solver = GurobiSolver()
scip_solver =  isfile("../bin/scipampl.exe") ? AmplNLSolver("../bin/scipampl.exe", ["../scip.set"]) : nothing     
cplex_solver = CplexSolver()
cbc_solver = CbcSolver()
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
ecos_solver = ECOSSolver(maxit=10000)
scs_solver = SCSSolver
pajarito_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=ipopt_solver, log_level=3)
#pajarito_solver = PajaritoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, log_level=3)

misocp_solver = gurobi_solver

if scip_solver != nothing
    minlp_solver = scip_solver
else
    minlp_solver = couenne_solver   
end

include("long_tests_gf.jl")
include("long_tests_ne.jl")

