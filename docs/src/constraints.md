# Constraints

```@meta
CurrentModule = GasModels
```

## Constraint Templates
Constraint templates help simplify data wrangling across multiple Gas Flow formulations by providing an abstraction layer between the network data and network constraint definitions. The constraint template's job is to extract the required parameters from a given network data structure and pass the data as named arguments to the Gas Flow formulations.

These templates should be defined over `GenericGasModel` and should not refer to model variables. For more details, see the files: `core/constraint_template.jl` and `core/constraint.jl`.

## Junction Constraints

### Flow balance constraints

The primary constraints related to junctions ensure that mass flow is balanced at these nodes. The specifics of the constraint implementation will change if there are variable or constant injections (variable injections are denoted by `ls` in the name of the function) and if there are network design options (denoted by `\_ne` in the name of the function).

```@docs
constraint_mass_flow_balance
constraint_mass_flow_balance_ls
constraint_mass_flow_balance_ne
constraint_mass_flow_balance_ne_ls
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

The primary constraints related to pipes ensure that that pressure drop and flow across a pipe is related through the Weymouth relationships. Here, the naming convention `ne` is used to denote the form of the constraint used for expansion pipes and `directed` is used to denote the form of the constraint used when the direction of flow is constrained.

```@docs
constraint_weymouth
constraint_weymouth_ne
constraint_weymouth_directed
constraint_weymouth_ne_directed
```

### Mass flow and pressure drop constraints

Secondarily, there are constraints associated with limits on pressure drop or mass flow across pipes. These constraints also use the `ne` and `directed` naming conventions.

```@docs
constraint_pipe_mass_flow
constraint_pipe_pressure
```

### Network expansion constraints

These constraints turn on or off the association between pressure and flow for pipes desiginated as expansion options.

```@docs
constraint_pipe_ne
```

### Direction on/off constraints

The disjunctive forms of problems (where directions are controlled by on/off variables) include special (redundant) constraints which tie the direction variables together.  Examples include ensuring that ensuring that parallel pipes have flow in the same direction.

```@docs
constraint_flow_direction_choice
constraint_parallel_flow
constraint_parallel_flow_ne
```

## Compressor Constraints

### Operations Constraints

The primary constraints related to compressors ensure that that the compressors operate within the limits of their capability (boost ratio, energy consumption, etc.). These constraints use the `ne` and `directed` naming conventions to denote constraints where the compressor is an expansion option or direction of flow is fixed, respectively.

```@docs
constraint_compressor_ratios
constraint_compressor_ratios_directed
constraint_compressor_ratios_ne
constraint_compressor_ratios_ne_directed
constraint_compressor_mass_flow
```

### Direction On/off Constraints

The disjunctive forms of problems (where directions are controlled by on/off variables) include special constraints to connect direction of flow with the choice of the binary variable.

```@docs
constraint_flow_direction_choice
constraint_parallel_flow
constraint_parallel_flow_ne
```

### Network Expansion Constraints

Constraints are also used to turn on/off flow through a compressor in expansion planning formulations

```@docs
constraint_compressor_ne
```

## Control Valve Constraints

### Operations Constraints

The primary constraints related to control valves ensure that that the valves operate within the limits of their capability (pressure reduction). These constraints use the `directed` naming conventions to denote constraints where the control valve direction of flow is fixed.  The control valve also has an open/close variable to determine whether or not flow is allowed through the valve


```@docs
constraint_on_off_control_valve_mass_flow
constraint_on_off_control_valve_pressure
constraint_on_off_control_valve_mass_flow_directed
constraint_on_off_control_valve_pressure_directed
```

### Direction On/off Constraints

The disjunctive forms of problems (where directions are controlled by on/off variables) include special constraints to connect direction of flow with the choice of the binary variable.

```@docs
constraint_flow_direction_choice
constraint_parallel_flow
constraint_parallel_flow_ne
```

## Valve Constraints

### Operations Constraints

The primary function of a valve is to open or close a pipe. These constraints use the `directed` naming conventions to denote constraints where the valve direction of flow is fixed.

```@docs
constraint_on_off_valve_mass_flow
constraint_on_off_valve_pressure
```

### Direction On/off Constraints

The disjunctive forms of problems (where directions are controlled by on/off variables) include special constraints to connect direction of flow with the choice of the binary variable.

```@docs
constraint_flow_direction_choice
constraint_parallel_flow
constraint_parallel_flow_ne
```

## Short Pipes

### Pressure Constraints

Short pipes are used to model frictionless connections between junctions.  The primary constraint ensures the pressure on both sides of the short pipe are the same. These constraints use the `directed` naming conventions to denote constraints where the control valve direction of flow is fixed.

```@docs
constraint_short_pipe_pressure
constraint_short_pipe_mass_flow
cconstraint_short_pipe_mass_flow_directed
```

### Direction On/off Constraints

The disjunctive forms of problems (where directions are controlled by on/off variables) include special constraints to connect direction of flow with the choice of the binary variable.

```@docs

constraint_flow_direction_choice
constraint_parallel_flow
constraint_parallel_flow_ne
```
