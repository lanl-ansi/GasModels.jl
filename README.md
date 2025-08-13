# GasModels.jl

<img src="https://lanl-ansi.github.io/GasModels.jl/dev/assets/logo.svg" align="left" width="200" alt="GasModels logo">

Status:
[![CI](https://github.com/lanl-ansi/GasModels.jl/workflows/CI/badge.svg)](https://github.com/lanl-ansi/GasModels.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/lanl-ansi/GasModels.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/lanl-ansi/GasModels.jl)
[![Documentation](https://github.com/lanl-ansi/GasModels.jl/workflows/Documentation/badge.svg)](https://lanl-ansi.github.io/GasModels.jl/stable/)
</p>

GasModels.jl is a Julia/JuMP package for Steady-State Gas Network Optimization.
It is designed to enable computational evaluation of emerging Gas network formulations and algorithms in a common platform.
The code is engineered to decouple problem specifications (e.g. Gas Flow, Expansion planning, ...) from the gas network formulations (e.g. CWP, DWP, CRDWP, ...).
This enables the definition of a wide variety of gas network formulations and their comparison on common problem specifications.

**Core Problem Specifications**
* Gas Flow (gf)
* Expansion Planning (ne)
* Load Shed (ls)


* ## Supported Formulations

All formulation names refer to how underlying physics of a gas network is modeled. For example, the `LRWP` model uses a linear representation of natural gas physics. If a model includes valves, then the resulting mathematical optimization problems will be mixed integer since valve controls are discrete.

| Formulation      | Steady-State         | Transient             | Description           |
| ---------------- | -------------------- | --------------------- | --------------------- |
| WP               |       Y              |          Y            | Physics is modeled using nonlinear equations. |
| DWP              |       Y              |          N            | Physics is modeled using nonlinear equations. Directionality of flow is modeled using discrete variables |
| CWP              |       Y              |          N            | Physics is modeled using nonlinear equations. Pipe flow in each direction is modeled by a nonnegative continuous variable. Complementarity constraints are used to ensure that flow is zero in at least one direction. |
| CRDWP            |       Y              |          N            | Physics is modeled using convex equations. Directionality of flow is modeled using discrete variables |
| LRDWP            |       Y              |          N            | Physics is modeled using linear equations. Directionality of flow is modeled using discrete variables |
| LRWP             |       Y              |          N            | Physics is modeled using linear equations. |

## Basic Usage

Note: Different problem formulations require different types of solvers. For continuous models such as CWP, WP, and LRWP, it is recommended to use Ipopt. For formulations that involve discrete variables—such as DWP, CRDWP, and LRDWP—a mixed-integer nonlinear programming (MINLP) solver like Juniper is required. See the second example for details on configuring Juniper.

Once GasModels is installed, a optimizer is installed, and a network data file  has been acquired, a Gas Flow can be executed with,
```
using GasModels, Ipopt
ipopt_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0)
casepath = "case-6.m"
result = run_gf(casepath, CWPGasModel, ipopt_solver)
```

For discrete problems requiring the Juniper optimizer, refer to the following example:
```
using GasModels, Ipopt, Juniper, HiGHS
# Create Juniper solver for MINLP
nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4)
mip_solver = optimizer_with_attributes(HiGHS.Optimizer)
juniper_solver = optimizer_with_attributes(
    Juniper.Optimizer,
    "nl_solver" => nl_solver,
    "mip_solver" => mip_solver
)
casepath = "case-6.m"
result = run_gf(casepath, DWPGasModel, juniper_solver)
```

Similarly, an expansion optimizer can be executed with,
```
run_ne(casepath, FooGasModel, FooSolver())
```

where FooGasModel is the implementation of the mathematical program of the Gas equations you plan to use (i.e. DWPGasModel) and FooSolver is the JuMP optimizer you want to use to solve the optimization problem (i.e. IpoptSolver).


## Acknowledgments

This code has been developed as part of the Advanced Network Science Initiative at Los Alamos National Laboratory.
The primary developer is Russell Bent, with significant contributions from Conrado Borraz-Sanchez, Hassan Hijazi, and Pascal van Hentenryck.

Special thanks to Miles Lubin for his assistance in integrating with Julia/JuMP.


## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, C15024.
