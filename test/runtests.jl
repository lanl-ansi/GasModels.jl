using GasModels
using Logging
# suppress warnings during testing
Logging.configure(level=ERROR)

using Ipopt
using Pajarito
using GLPKMathProgInterface
#using SCS
using ECOS
using SCS

scip_solver = nothing
bonmin_solver = nothing
couenne_solver = nothing
cplex_solver = nothing
gurobi_solver = nothing
cbc_solver = nothing

if (Pkg.installed("AmplNLWriter") != nothing && Pkg.installed("CoinOptServices") != nothing)
    using AmplNLWriter
    using CoinOptServices
 #   bonmin_solver = BonminNLSolver()
    couenne_solver = CouenneNLSolver()    
    bonmin_solver = OsilBonminSolver() # until BonminNLSolver supports quadratic constraints declared with @constraint
 #   couenne_solver = OsilCouenneSolver()
    if isfile("../bin/scipampl.exe")      
#        AmplNLWriter.setdebug(true)
        scip_solver = AmplNLSolver("../bin/scipampl.exe", ["../scip.set"])
    end 
end

if Pkg.installed("Gurobi") != nothing
    using Gurobi
    gurobi_solver = GurobiSolver()
end

if Pkg.installed("CPLEX") != nothing
    using CPLEX
    cplex_solver = CplexSolver()
end

if Pkg.installed("Cbc") != nothing
    using Cbc
    cbc_solver = CbcSolver()
end



if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

# default setup for solvers
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
ecos_solver = ECOSSolver(maxit=10000)
scs_solver = SCSSolver
#pajarito_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=ipopt_solver, log_level=3)
pajarito_solver = PajaritoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, log_level=1)


# The paper used cplex 12.6.0
#if Pkg.installed("Gurobi") != nothing
#   misocp_solver = gurobi_solver
#elseif Pkg.installed("CPLEX") != nothing
 #  misocp_solver = cplex_solver
#else
   misocp_solver = pajarito_solver
#end   


# The paper used SCIP
#if scip_solver != nothing
    #minlp_solver = scip_solver
 #   minlp_solver = couenne_solver       
#else
    minlp_solver = couenne_solver   
#end

include("gf.jl")
include("ne.jl")
include("ls.jl")
include("nels.jl")

