# Gas Model

```@meta
CurrentModule = GasModels
```

All methods for constructing gasmodels should be defined on the following type:

```@docs
AbstractGasModel
```

which utilizes the following (internal) functions:

```@docs
build_ref
```

When using the build_ref for transient problem formulations the following ref extension has to be added to populate the fields necessary for formulate the transient optimization problems.

```@docs
ref_add_transient!
```


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

## Supported Formulations

All formulation names refer to how underlying physics of a gas network is modeled. For example, the `LP` model uses a linear representation of natural gas physics. If a model includes valves, then the resulting mathematical optimization problems will be MIP since valve controls are discrete.

| Formulation      | Steady-State         | Transient             | Description           |
| ---------------- | -------------------- | --------------------- | --------------------- |
| NLP              |       Y              |          N            | Physics is modeled using nonlinear equations. |
| MINLP            |       Y              |          N            | Physics is modeled using nonlinear equations. Directionality of flow is modeled using discrete variables |
| MINLP            |       Y              |          N            | Physics is modeled using second order cone equations. Directionality of flow is modeled using discrete variables |
| MINLP            |       Y              |          N            | Physics is modeled using linear equations. Directionality of flow is modeled using discrete variables |
| LP               |       Y              |          N            | Physics is modeled using linear equations. |
