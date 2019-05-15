using GasModels

GasModels.silence()


using JuMP 
using Ipopt
using Cbc
using Juniper
using Gurobi 
using SCIP 
using ECOS 
using SCS 
using CPLEX 
using Test
using AMPLNLWriter

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0, sb="yes")
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, 
    nl_solver=JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), 
    mip_solver=cbc_solver, log_levels=[])
gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer, LogToConsole=0)
scip_solver = JuMP.with_optimizer(SCIP.Optimizer, display_verblevel=0)
ecos_solver = JuMP.with_optimizer(ECOS.Optimizer, verbose=false, maxit=10000)
scs_solver = JuMP.with_optimizer(SCS.Optimizer)
cplex_solver = JuMP.with_optimizer(CPLEX.Optimizer, CPX_PARAM_SCRIND = 0)
couenne_solver = JuMP.with_optimizer(AmplNLWriter.Optimizer, "path/to/couenne.exe")
bonmin_solver = JuMP.with_optimizer(AmplNLWriter.Optimizer, "path/to/bonmin.exe")

# baron_solver = BaronSolver() # has too many backward dependecies
# scip_solver =  isfile("../bin/scipampl.exe") ? AmplNLSolver("../bin/scipampl.exe", ["../scip.set"]) : nothing

misocp_solver = gurobi_solver

if scip_solver != nothing
    minlp_solver = scip_solver
else
    minlp_solver = juniper_solver
end

include("long_tests_gf.jl")
include("long_tests_ne.jl")

#include("long_tests_unstable.jl")
