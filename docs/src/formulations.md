# Network Formulations

## Type Hierarchy
We begin with the top of the hierarchy, where we can distinguish between gas flow models. There are currently five formulations supported in GasModels. Two full non convex formulations and three relaxations.

```julia
AbstractNLPModel <: AbstractGasModel
AbstractMINLPModel <: AbstractGasModel
AbstractMISOCPModel <: AbstractGasModel
AbstractMIPModel <: AbstractGasModel
AbstractLPModel <: AbstractGasModel
```

## Gas Models
Each of these forms can be used as the type parameter for a GasModel, i.e.:

```julia
NLPGasModel <: AbstractNLPForm
MINLPGasModel <: AbstractMINLPModel
MISOCPGasModel <: AbstractMISOCPModel
MIPGasModel <: AbstractMIPModel
LPGasModel <: AbstractLPModel
```

For details on `AbstractGasModel`, see the section on [Gas Model](@ref).

## User-Defined Abstractions

The user-defined abstractions begin from a root abstract like the `AbstractGasModel` abstract type, i.e.

```julia
AbstractMyFooModel <: AbstractGasModel

StandardMyFooForm <: AbstractFooModel
FooGasModel = AbstractGasModel{StandardFooForm}
```

## NLP

```@autodocs
Modules = [GasModels]
Pages   = ["form/nlp.jl"]
Order   = [:function]
Private  = true
```

## MINLP

```@autodocs
Modules = [GasModels]
Pages   = ["form/mi/minlp.jl"]
Order   = [:function]
Private  = true
```

## MISOCP

```@autodocs
Modules = [GasModels]
Pages   = ["form/mi/misocp.jl"]
Order   = [:function]
Private  = true
```

## MIP

```@autodocs
Modules = [GasModels]
Pages   = ["form/mip.jl"]
Order   = [:function]
Private  = true
```

## LP

```@autodocs
Modules = [GasModels]
Pages   = ["form/lp.jl"]
Order   = [:function]
Private  = true
```
