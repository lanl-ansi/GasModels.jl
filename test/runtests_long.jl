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
using AmplNLWriter

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0, sb="yes")
cbc_solver = JuMP.with_optimizer(Cbc.Optimizer, logLevel=0)
juniper_solver = JuMP.with_optimizer(Juniper.Optimizer, nl_solver=JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0), mip_solver=cbc_solver, log_levels=[])
gurobi_solver = JuMP.with_optimizer(Gurobi.Optimizer)
scip_solver = JuMP.with_optimizer(SCIP.Optimizer)
ecos_solver = JuMP.with_optimizer(ECOS.Optimizer, verbose=false, maxit=10000)
scs_solver = JuMP.with_optimizer(SCS.Optimizer)
cplex_solver = JuMP.with_optimizer(CPLEX.Optimizer, CPX_PARAM_SCRIND = 0)
couenne_solver = JuMP.with_optimizer(AmplNLWriter.Optimizer, "couenne.exe")
bonmin_solver = JuMP.with_optimizer(AmplNLWriter.Optimizer, "bonmin.exe")

misocp_solver = gurobi_solver

if scip_solver != nothing
    minlp_solver = scip_solver
else
    minlp_solver = couenne_solver
end

include("long_tests_gf.jl")
include("long_tests_ne_minlp.jl")
include("long_tests_ne_misocp.jl")
include("long_tests_ne_nlp.jl")

#include("long_tests_unstable.jl")
