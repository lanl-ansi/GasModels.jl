# Constraints

```@meta
CurrentModule = GasModels
```

## Constraint Templates
Constraint templates help simplify data wrangling across multiple Gas Flow formulations by providing an abstraction layer between the network data and network constraint definitions. The constraint template's job is to extract the required parameters from a given network data structure and pass the data as named arguments to the Gas Flow formulations.

These templates should be defined over `GenericGasModel` and should not refer to model variables. For more details, see the files: `core/constraint_template.jl` and `core/constraint.jl`.

## Junction Constraints

### Flow Balance Constraints

```@docs
constraint_junction_flow_balance
```

### Load Shedding Constraints

```@docs
constraint_junction_flow_balance_ls
```

### Network Expansion Constraints

```@docs
constraint_junction_flow_balance_ne
constraint_junction_flow_balance_ne_ls
```


## Pipe Constraints

### Weymouth's Law Constraints

```@docs
constraint_weymouth
```

### Direction On/off Constraints

```@docs
constraint_on_off_pressure_drop
constraint_on_off_pipe_flow
```

### Network Expansion Constraints

```@docs
constraint_weymouth_ne
constraint_on_off_pressure_drop_ne
constraint_on_off_pipe_flow_ne
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
constraint_on_off_valve_pressure_drop
```

## Short Pipes

### Direction On/off Constraints

```@docs
constraint_on_off_short_pipe_flow
constraint_short_pipe_pressure_drop
```

## Direction Cutting Constraints

```@docs
constraint_source_flow
constraint_sink_flow
constraint_conserve_flow
constraint_parallel_flow
```

### Network Expansion Constraints

```@docs
constraint_source_flow_ne
constraint_sink_flow_ne
constraint_conserve_flow_ne
constraint_parallel_flow_ne
```
