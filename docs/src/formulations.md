# Network Formulations

## Type Hierarchy
We begin with the top of the hierarchy, where we can distinguish between gas flow models. There are currently five formulations supported in GasModels. Two full non convex formulations and three relaxations.

```julia
AbstractNLPForm <: AbstractGasFormulation
AbstractMINLPForm <: AbstractGasFormulation
AbstractMISOCPForm <: AbstractGasFormulation
AbstractMIPForm <: AbstractGasFormulation
AbstractLPForm <: AbstractGasFormulation
```

## Gas Models
Each of these forms can be used as the type parameter for a GasModel, i.e.:

```julia
NLPGasModel = GenericGasModel(StandardNLPForm)
MINLPGasModel = GenericGasModel(StandardMINLPForm)
MISOCPGasModel = GenericGasModel(StandardMISOCPForm)
MIPGasModel = GenericGasModel(StandardMIPForm)
LPGasModel = GenericGasModel(StandardLPForm)
```

For details on `GenericGasModel`, see the section on [Gas Model](@ref).

## User-Defined Abstractions

The user-defined abstractions begin from a root abstract like the `AbstractGasFormulation` abstract type, i.e.

```julia
AbstractMyFooForm <: AbstractGasFormulation

StandardMyFooForm <: AbstractFooForm
FooGasModel = GenericGasModel{StandardFooForm}
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
