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
