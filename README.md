# GasModels.jl 

Release: [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://lanl-ansi.github.io/GasModels.jl/stable)

Dev:
[![Build Status](https://travis-ci.org/lanl-ansi/GasModels.jl.svg?branch=master)](https://travis-ci.org/lanl-ansi/GasModels.jl)
[![codecov](https://codecov.io/gh/lanl-ansi/GasModels.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/lanl-ansi/GasModels.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://lanl-ansi.github.io/GasModels.jl/latest)

GasModels.jl is a Julia/JuMP package for Steady-State Gas Network Optimization.
It is designed to enable computational evaluation of emerging Gas network formulations and algorithms in a common platform.
The code is engineered to decouple problem specifications (e.g. Gas Flow, Expansion planning, ...) from the gas network formulations (e.g. MINLP, MISOCP, ...).
This enables the definition of a wide variety of gas network formulations and their comparison on common problem specifications.

**Core Problem Specifications**
* Gas Flow (gf)
* Expansion Planning (ne)
* Load Shed (ls)

**Core Network Formulations**
* MINLP 
* MISOCP
* MIP

## Basic Usage


Once GasModels is installed, a solver is installed, and a network data file  has been acquired, a Gas Flow can be executed with,
```
using GasModels
using <solver_package>

run_gf("foo.json", FooGasModel, FooSolver())
```

Similarly, an expansion solver can be executed with,
```
run_ne("foo.json", FooGasModel, FooSolver())
```

where FooGasModel is the implementation of the mathematical program of the Gas equations you plan to use (i.e. MINLPGasModel) and FooSolver is the JuMP solver you want to use to solve the optimization problem (i.e. IpoptSolver).


## Acknowledgments

This code has been developed as part of the Advanced Network Science Initiative at Los Alamos National Laboratory.
The primary developer is Russell Bent, with significant contributions from Conrado Borraz-Sanchez, Hassan Hijazi, and Pascal van Hentenryck.

Special thanks to Miles Lubin for his assistance in integrating with Julia/JuMP.


## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
