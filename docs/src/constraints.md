# Constraints

```@meta
CurrentModule = GasModels
```

## Constraint Templates
Constraint templates help simplify data wrangling across multiple Gas Flow formulations by providing an abstraction layer between the network data and network constraint definitions. The constraint template's job is to extract the required parameters from a given network data structure and pass the data as named arguments to the Gas Flow formulations.

These templates should be defined over `GenericGasModel` and should not refer to model variables. For more details, see the files: `core/constraint_template.jl` and `core/constraint.jl`.

## Constraint Sets

Constraint sets help simplify constraint generation by collecting together common sets of constraints that are associated with a specific components of capabilities of a component, such as flow through a pipe. See filessee the files: `core/constraint_set.jl`


## Junction Constraints

### Flow balance constraints

The primary constraints related to junctions ensure that mass flow is balanced at these nodes. The specifics of the constraint implementation will change if there are variable or constant injections (variable injections are denoted by \_ls in the name of the function) and if there are network design options (denoted by \_ne in the name of the function).

```@docs
constraint_junction_mass_flow_balance
constraint_junction_mass_flow_balance_ls
constraint_junction_mass_flow_balance_ne
constraint_junction_mass_flow_balance_ne_ls
```

### Direction On/off Constraints

The disjunctive forms of problems (where directions are controlled by on/off variables) include special (redundant) constraints which tie the direction variables together.  Examples include ensuring that ensure at least one edge of junction that has only sources of natural gas has outgoing flow.

```@docs
constraint_source_flow
constraint_sink_flow
constraint_conserve_flow
constraint_source_flow_ne
constraint_sink_flow_ne
constraint_conserve_flow_ne
```

## Pipe Constraints

### Weymouth's law constraints

The primary constraints related to pipes ensure that that pressure drop and flow across a pipe is related through the Weymouth relationships. Here, the naming convention \_ne is used to denote the form of the constraint used for expansion pipes and \_directed is used to denote the form of the constraint used when the direction of flow is constrained.

```@docs
constraint_weymouth
constraint_weymouth_ne
constraint_weymouth_directed
constraint_weymouth_ne_directed
```

### Mass flow and pressure drop constraints

Secondarily, there are constraints associated with limits on pressure drop or mass flow across pipes. These constraints also use the \_ne and \_directed naming conventions.

```@docs
constraint_pipe_mass_flow
constraint_pressure_drop_directed
constraint_pipe_flow_directed
```

### Network expansion constraints

These constraints turn on or off the association between pressure and flow for pipes desiginated as expansion options.

```@docs
constraint_pipe_ne
```

### Direction on/off constraints

The disjunctive forms of problems (where directions are controlled by on/off variables) include special (redundant) constraints which tie the direction variables together.  Examples include ensuring that ensuring that parallel pipes have flow in the same direction.

```@docs
constraint_on_off_pressure_drop
constraint_on_off_pipe_flow
constraint_flow_direction_choice
constraint_parallel_flow
```






## Compressor Constraints

### Direction On/off Constraints

```@docs
constraint_on_off_compressor_flow
constraint_on_off_compressor_ratios
```

### Network Expansion Constraints

```@docs
constraint_on_off_compressor_flow_ne
constraint_on_off_compressor_ratios_ne
```


## Control Valve Constraints

### Direction On/off Constraints

```@docs
constraint_on_off_control_valve_flow
constraint_on_off_control_valve_pressure_drop
```

## Valve Constraints

### Direction On/off Constraints

```@docs
constraint_on_off_valve_flow
constraint_valve_pressure_drop
```

## Short Pipes

### Direction On/off Constraints

```@docs
constraint_on_off_short_pipe_flow
constraint_short_pipe_pressure_drop
```

## Direction Cutting Constraints

```@docs
constraint_parallel_flow
```

### Network Expansion Constraints

```@docs
constraint_parallel_flow_ne
```
