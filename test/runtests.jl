using GasModels
using Logging
# suppress warnings during testing
Logging.configure(level=ERROR)

using Ipopt
using Pajarito
using GLPKMathProgInterface
#using SCS

# needed for Non-convex OTS tests
if (Pkg.installed("AmplNLWriter") != nothing && Pkg.installed("CoinOptServices") != nothing)
    using AmplNLWriter
    using CoinOptServices
 #   bonmin_solver = BonminNLSolver()
 #   couenne_solver = CouenneNLSolver()    
    bonmin_solver = OsilBonminSolver()
   couenne_solver = OsilCouenneSolver()
end

if Pkg.installed("Gurobi") != nothing
    using Gurobi
    gurobi_solver = GurobiSolver()
end

if Pkg.installed("CPLEX") != nothing
    using CPLEX
    cplex_solver = CplexSolver()
end


if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

# default setup for solvers
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
pajarito_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=ipopt_solver)

# The paper used cplex 12.6.0
if Pkg.installed("Gurobi") != nothing
   misocp_solver = gurobi_solver
else if Pkg.installed("CPLEX") != nothing
   misocp_solver = cplex_solver
else
   misocp_solver = bonmin_solver
end   
   
minlp_solver = couenne_solver # Paper used SCIP


#include("gf.jl")
include("expansion.jl")

