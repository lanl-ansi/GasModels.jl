using GasModels
using Logging

# suppress warnings during testing
Logging.configure(level=ERROR)

using Pajarito
using Ipopt
using CoinOptServices
using AmplNLWriter

bonmin_solver = BonminNLSolver()
couenne_solver = CouenneNLSolver()
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)

using Base.Test

cbc_solver = nothing
if Pkg.installed("Cbc") != nothing
    using Cbc
    cbc_solver = CbcSolver()
end

# default setup for solvers
pajarito_solver = PajaritoSolver(mip_solver=cbc_solver, cont_solver=ipopt_solver, log_level=1)
misocp_solver = pajarito_solver
minlp_solver = couenne_solver   


include("gf.jl")
include("ne.jl")
include("ls.jl")
include("nels.jl")
include("nelsfd.jl")

