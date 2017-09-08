# Network Formulations

## Type Hierarchy
We begin with the top of the hierarchy, where we can distinguish between gas flow models. Currently, there are two variations
of the disjunctive form of the weymouth equations: The full non convex formulation and its conic relaxation.
```julia
AbstractMINLPForm <: AbstractGasFormulation
AbstractMISOCPForm <: AbstractGasFormulation
```

## Gas Models
Each of these forms can be used as the type parameter for a GasModel:
```julia
MINLPGasModel = GenericGasModel(StandardMINLPForm)
MISOCPGasModel = GenericGasModel(StandardMISOCPForm)
```

For details on `GenericGasModel`, see the section on [Gas Model](@ref).

## User-Defined Abstractions

The user-defined abstractions begin from a root abstract like the `AbstractGasFormulation` abstract type, i.e. 
```julia
AbstractMyFooForm <: AbstractGasFormulation

StandardMyFooForm <: AbstractFooForm
FooGasModel = GenericGasModel{StandardFooForm}
```
## MINLP

```@autodocs
Modules = [GasModels]
Pages   = ["form/minlp.jl"]
Order   = [:function]
Private  = true
```

## MISOCP


```@autodocs
Modules = [GasModels]
Pages   = ["form/misocp.jl"]
Order   = [:function]
Private  = true
```

