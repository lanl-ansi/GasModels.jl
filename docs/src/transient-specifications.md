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
variable_c_ratio
variable_compressor_power

variable_pipe_flux_avg
variable_pipe_flux_neg

variable_injection
variable_withdrawal
variable_transfer_flow
        
variable_storage_flow
variable_storage_c_ratio
variable_reservoir_density
variable_well_density
variable_well_flux_avg
variable_well_flux_neg
```

### Expressions 

The following linear and non-linear expressions are created by the formulation for ease of formulating the constraints

```@docs 
variable_pipe_flux_fr
variable_pipe_flux_to
variable_well_flux_fr
variable_well_flux_to
expression_density_derivative
expression_net_nodal_injection
expression_net_nodal_edge_out_flow
expression_compressor_power
expression_well_density_derivative
expression_reservoir_density_derivative
```

## Constraints and Constraint Templates

```@docs 
constraint_slack_junction_density
constraint_nodal_balance
constraint_nodal_balance
constraint_pipe_mass_balance
constraint_pipe_momentum_balance
constraint_compressor_physics
constraint_compressor_power
constraint_storage_compressor_regulator
constraint_storage_well_momentum_balance
constraint_storage_well_mass_balance
constraint_storage_well_nodal_balance
constraint_storage_bottom_hole_reservoir_density
constraint_storage_reservoir_physics
```

## Objective 

Three types of objectives are supported by the transient OGF problem (i) a load shedding objective, (ii) a compressor power objective, and (iii)  a linear combination of both controlled by the optional argument `economic_weighting` in the Matlab static file. 

```@docs 
objective_min_transient_load_shed
objective_min_transient_compressor_power
objective_min_transient_economic_costs
```