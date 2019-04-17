# GasModels.jl Documentation

```@meta
CurrentModule = GasModels
```

## Overview

GasModels.jl is a Julia/JuMP package for Steady-State Gas Network Optimization. It provides utilities for parsing and modifying network data (see [GasModels Network Data Format](@ref) for details), and is designed to enable computational evaluation of emerging gas network formulations and algorithms in a common platform.

The code is engineered to decouple [Problem Specifications](@ref) (e.g. Gas Flow, Expansion Planning, ...) from [Network Formulations](@ref) (e.g. MINLP, MISOC-relaxation, ...). This enables the definition of a wide variety of gas network formulations and their comparison on common problem specifications.

## Installation

The latest stable release of GasModels will be installed using the Julia package manager with

```julia
Pkg.add("GasModels")
```

For the current development version, "checkout" this package with

```julia
Pkg.checkout("GasModels")
```

At least one solver is required for running GasModels.  The open-source solver Pavito is recommended and can be used to solve a wide variety of the problems and network formulations provided in GasModels.  The Pavito solver can be installed via the package manager with

```julia
Pkg.add("Pavito")
```

Test that the package works by running

```julia
Pkg.test("GasModels")
```
