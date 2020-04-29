# Transient Problem Specifications

```@meta
CurrentModule = GasModels
```

## Optimal Gas Flow 

The transient optimal gas flow problem optimizes a linear combination of the total compressor power and the total load shed in the system subject to the time-varying pipeline dynamics modeled as ordinary-differential equations (ODEs), discretized using Backward Euler scheme. The readers are referred to [this paper](https://ieeexplore.ieee.org/abstract/document/8412133/) or its ([arxiv version](https://arxiv.org/pdf/1803.07156)) for a derivation of the ODEs. Also, note that the Optimal Gas Flow problem currently can work with only time-periodic time-series data. If the data is not time-periodic, then GasModels will try to fit a time-periodic spline to the data and then run the transient optimal gas flow problem.

## Model 

```@docs 
build_transient_ogf
```

## Variables 

```@docs 
variable_density
variable_compressor_flow
variable_pipe_flux
variable_c_ratio
variable_injection
variable_withdrawal
variable_transfer_flow
```

### Expressions 

The following linear and non-linear expressions are created by the formulation for ease of formulating the constraints

```@docs 
expression_density_derivative
expression_net_nodal_injection
expression_net_nodal_edge_out_flow
expression_non_slack_affine_derivative
expression_compressor_power
```

## Constraints and Constraint Templates

```@docs 
constraint_slack_junction_density
constraint_slack_junction_mass_balance
constraint_non_slack_junction_mass_balance
constraint_pipe_physics_ideal
constraint_compressor_physics
constraint_compressor_power
constraint_transfer_separation
```

## Objective 

Three types of objectives are supported by the transient OGF problem (i) a load shedding objective, (ii) a compressor power objective, and (iii)  a linear combination of both controlled by the optional argument `economic_weighting` in the Matlab static file. 

```@docs 
objective_min_transient_load_shed
objective_min_transient_compressor_power
objective_min_transient_economic_costs
```