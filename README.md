# GasModels.jl 


Release: [![GasModels](http://pkg.julialang.org/badges/GasModels_0.4.svg)](http://pkg.julialang.org/?pkg=GasModels), [![GasModels](http://pkg.julialang.org/badges/GasModels_0.5.svg)](http://pkg.julialang.org/?pkg=GasModels)

Dev:
[![Build Status](https://travis-ci.org/lanl-ansi/GasModels.jl.svg?branch=master)](https://travis-ci.org/lanl-ansi/GasModels.jl)
[![codecov](https://codecov.io/gh/lanl-ansi/GasModels.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/lanl-ansi/GasModels.jl)

GasModels.jl is a Julia/JuMP package for Steady-State Gas Network Optimization.
It is designed to enable computational evaluation of emerging Gas network formulations and algorithms in a common platform.
The code is engineered to decouple problem specifications (e.g. Gas Flow, Expansion planning, ...) from the gas network formulations (e.g. MINLP, MISOCP, ...).
This enables the definition of a wide variety of gas network formulations and their comparison on common problem specifications.

**Core Problem Specifications**
* Gas Flow
* Expansion Planning

**Core Network Formulations**
* MINLP 
* MISOCP

## Installation

For the moment, GasModels.jl is not yet registered as a Julia package.  Hence, "clone" should be used instead of "add" for package installation,

`Pkg.clone("git@github.com:lanl-ansi/GasModels.jl.git")`

At least one solver is required for running GasModels.  Commercial or psuedo-commerical solvers seem to handle these problems much better than
some of the open source alternatives.  Gurobi and Cplex perform well on the MISOCP model, and SCIP handles the MINLP model reasonably well.


## Basic Usage


Once GasModels is installed, a solver is installed, and a network data file  has been acquired, a Gas Flow can be executed with,
```
using GasModels
using <solver_package>

run_gf("foo.json", <>Solver())
```

Similarly, an expansion solver can be executed with,
```
run_expansion("foo,.son", <>Solver())
```

## Acknowledgments

This code has been developed as part of the Advanced Network Science Initiative at Los Alamos National Laboratory.
The primary developer is Russell Bent, with significant contributions from Conrado Borraz-Sanchez, Hassan Hijazi, and Pascal van Hentenryck.

Special thanks to Miles Lubin for his assistance in integrating with Julia/JuMP.


## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
