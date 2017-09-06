# Quick Start Guide

Once Gas Models is installed, Pajarito is installed, and a network data file (e.g. `"test/data/gaslib-40.json"`) has been acquired, a Gas Flow with SOC relaxation can be executed with,

```julia
using GasModels
using Pajarito

run_soc_gf("../test/data/gaslib-40.json", PajaritoSolver())
```

Similarly, a full non-convex Gas Flow can be executed with a MINLP solver like

```julia
run_nl_gf("../test/data/gaslib-40.json", CouenneNLSolver())
```


## Getting Results

The run commands in GasModels return detailed results data in the form of a dictionary.
This dictionary can be saved for further processing as follows,

```julia
run_soc_gf("../test/data/gaslib-40.json", PajaritoSolver())
```

For example, the algorithm's runtime and final objective value can be accessed with,

```
result["solve_time"]
result["objective"]
```

The `"solution"` field contains detailed information about the solution produced by the run method.
For example, the following dictionary comprehension can be used to inspect the junction pressures in the solution,

```
Dict(name => data["p"] for (name, data) in result["solution"]["junction"])
```

For more information about GasModels result data see the [GasModels Result Data Format](@ref) section.


## Accessing Different Formulations

The function "run_soc_gf" and "run_nl_gf" are shorthands for a more general formulation-independent gas flow execution, "run_gf".
For example, `run_soc_gf` is equivalent to,

```julia
run_gf("test/data/gaslib-40.json", MISOCPGasModel, PajaritoSolver())
```

where "MISOCPGasModel" indicates an SOC formulation of the gas flow equations.  This more generic `run_gf()` allows one to solve a gas flow feasability problem with any gas network formulation implemented in GasModels.  For example, the full non convex Gas Flow can be run with,

```julia
run_gf("test/data/gaslib-40.json", MINLPGasModel, CouenneNLSolver())
```

## Modifying Network Data
The following example demonstrates one way to perform multiple GasModels solves while modify the network data in Julia,

```julia
network_data = GasModels.parse_file("test/data/gaslib-40.json")

run_gf(network_data, MISOCPGasModel, PajaritoSolver())

network_data["junction"]["24"]["pmin"] = 30.0

run_gf(network_data, MISOCPGasModel, PajaritoSolver())
```

For additional details about the network data, see the [GasModels Network Data Format](@ref) section.

## Inspecting the Formulation
The following example demonstrates how to break a `run_gf` call into separate model building and solving steps.  This allows inspection of the JuMP model created by GasModels for the gas flow problem,

```julia
gm = build_generic_model("test/data/gaslib-40.json", MISOCPGasModel, GasModels.post_gf)

print(gm.model)

solve_generic_model(gm, PajaritoSolver())
```
