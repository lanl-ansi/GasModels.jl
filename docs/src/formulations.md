# Network Formulations

## Type Hierarchy
We begin with the top of the hierarchy, where we can distinguish between gas flow models. Currently, there are two variations
of the weymouth equations, one where the directions of flux are known and one where they are unknown.
```julia
AbstractDirectedGasFormulation <: AbstractGasFormulation
AbstractUndirectedGasFormulation <: AbstractGasFormulation
```
Each of these have a disjunctive form of the weymouth equations: The full non convex formulation and its conic relaxation.
```julia
AbstractMINLPForm <: AbstractGasFormulation
AbstractMISOCPForm <: AbstractGasFormulation
```

## Gas Models
Each of these forms can be used as the type parameter for a GasModel, i.e.:
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
## Directed Models

```@autodocs
Modules = [GasModels]
Pages   = ["form/directed.jl"]
Order   = [:function]
Private  = true
```

## Undirected Models

```@autodocs
Modules = [GasModels]
Pages   = ["form/undirected.jl"]
Order   = [:function]
Private  = true
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
