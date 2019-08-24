# Constraints

```@meta
CurrentModule = GasModels
```

## Constraint Templates
Constraint templates help simplify data wrangling across multiple Gas Flow formulations by providing an abstraction layer between the network data and network constraint definitions. The constraint template's job is to extract the required parameters from a given network data structure and pass the data as named arguments to the Gas Flow formulations.

These templates should be defined over `GenericGasModel` and should not refer to model variables. For more details, see the files: `core/constraint_template.jl` and `core/constraint.jl`.

The convention is to define a function for each constraint. Utility functions are defined to collect together sets of constraints which are associated with individual components or capabilities of a component such as flow through a pipe.

## Junction Constraints

### Flow balance constraints

```@docs
constraint_junction_mass_flow_balance
```

### Flow balance constraints with load shedding

```@docs
constraint_junction_mass_flow_balance_ls
```

### Flow balance constraints for network expansion problems

```@docs
constraint_junction_mass_flow_balance_ne
constraint_junction_mass_flow_balance_ne_ls
```

### Direction On/off Constraints

```@docs
constraint_source_flow
constraint_sink_flow
constraint_conserve_flow
constraint_source_flow_ne
constraint_sink_flow_ne
constraint_conserve_flow_ne
```

### Constraint collections

```@docs
constraint_junction_mass_flow
constraint_junction_mass_flow_directed
constraint_junction_mass_flow_ls
constraint_junction_mass_flow_ls_directed
constraint_junction_mass_flow_ne
constraint_junction_mass_flow_ne_directed
constraint_junction_mass_flow_ne_ls
constraint_junction_mass_flow_ne_ls_directed
```

## Pipe Constraints

### Weymouth's law constraints

```@docs
constraint_weymouth
```

### Direction on/off constraints

```@docs
constraint_on_off_pressure_drop
constraint_on_off_pipe_flow
constraint_flow_direction_choice
constraint_parallel_flow
```

### One way flow constraints
```@docs
  constraint_pressure_drop_directed
  constraint_pipe_flow_directed
```

### Network Expansion Constraints

```@docs
constraint_weymouth_ne
constraint_on_off_pressure_drop_ne
constraint_on_off_pipe_flow_ne
constraint_flow_direction_choice_ne
constraint_parallel_flow_ne
constraint_pressure_drop_ne_directed
constraint_pipe_flow_ne_directed
```

### Constraint collections

```@docs
constraint_pipe_flow
constraint_pipe_flow_directed
constraint_pipe_flow_ne
constraint_pipe_flow_ne_directed
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
