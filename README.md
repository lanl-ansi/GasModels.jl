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

**Core Network Formulations**
* CWP
* DWP
* WP
* CRDWP
* LRDWP
* LRWP

## Basic Usage


Once GasModels is installed, a optimizer is installed, and a network data file  has been acquired, a Gas Flow can be executed with,
```
using GasModels
using <solver_package>

run_gf("foo.m", FooGasModel, FooSolver())
```

Similarly, an expansion optimizer can be executed with,
```
run_ne("foo.m", FooGasModel, FooSolver())
```

where FooGasModel is the implementation of the mathematical program of the Gas equations you plan to use (i.e. DWPGasModel) and FooSolver is the JuMP optimizer you want to use to solve the optimization problem (i.e. IpoptSolver).


## Acknowledgments

This code has been developed as part of the Advanced Network Science Initiative at Los Alamos National Laboratory.
The primary developer is Russell Bent, with significant contributions from Conrado Borraz-Sanchez, Hassan Hijazi, and Pascal van Hentenryck.

Special thanks to Miles Lubin for his assistance in integrating with Julia/JuMP.


## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, C15024.
