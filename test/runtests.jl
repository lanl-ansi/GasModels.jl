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
    bonmin_solver = BonminNLSolver()
    couenne_solver = CouenneNLSolver()    
#    bonmin_solver = OsilBonminSolver()
#    couenne_solver = OsilCouenneSolver()
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
#scs_solver = SCSSolver(max_iters=1000000, verbose=0)

#include("output.jl")


# used by OTS and Loadshed TS models
#function check_br_status(sol)
 #   for (idx,val) in sol["branch"]
  #      @test val["br_status"] == 0.0 || val["br_status"] == 1.0
   # end
#end

include("gf.jl")

