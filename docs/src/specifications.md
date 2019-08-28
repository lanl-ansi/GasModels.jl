# Problem Specifications

## Gas Flow (GF)

### Variables
```julia
variable_pressure_sqr(gm)
variable_flow(gm)
variable_valve_operation(gm)
```

### Constraints
```julia
for i in ids(gm, :junction)
    constraint_set_junction_mass_flow(gm, i)
end

for i in [collect(ids(gm, :pipe)); collect(ids(gm, :resistor))]
    constraint_set_pipe_flow(gm, i)
end

for i in ids(gm, :short_pipe)
    constraint_set_short_pipe_flow(gm, i)
end

for i in ids(gm, :compressor)
    constraint_set_compressor_flow(gm, i)
end

for i in ids(gm, :valve)
    constraint_set_valve_flow(gm, i)
end

for i in ids(gm, :control_valve)
    constraint_set_control_valve_flow(gm, i)
end
```

## Maximum Load (LS)


### Variables

```julia
variable_flow(gm)
variable_pressure_sqr(gm)
variable_valve_operation(gm)
variable_load_mass_flow(gm)
variable_production_mass_flow(gm)
```

### Objective

```julia
objective_max_load(gm)
```

### Constraints

```julia
for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))]
    constraint_set_pipe_flow(gm, i)
end

for i in ids(gm, :junction)
    constraint_set_junction_mass_flow_ls(gm, i)
end

for i in ids(gm, :short_pipe)
    constraint_set_short_pipe_flow(gm, i)
end

for i in ids(gm, :compressor)
    constraint_set_compressor_flow(gm, i)
end

for i in ids(gm, :valve)
    constraint_set_valve_flow(gm, i)
end

for i in ids(gm, :control_valve)
    constraint_set_control_valve_flow(gm, i)
end
```

## Expansion Planning (NE)


### Variables
```julia
variable_pressure_sqr(gm)
variable_flow(gm)
variable_flow_ne(gm)
variable_valve_operation(gm)
variable_pipe_ne(gm)
variable_compressor_ne(gm)
```

### Objective
```julia
objective_min_ne_cost(gm)
```


### Constraints
```julia
for i in ids(gm, :junction)
    constraint_set_junction_mass_flow_ne(gm, i)
end

for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))]
    constraint_set_pipe_flow(gm, i)
end

for i in ids(gm,:ne_pipe)
    constraint_set_pipe_flow_ne(gm, i)
end

for i in ids(gm, :short_pipe)
    constraint_set_short_pipe_flow(gm, i)
end

for i in ids(gm, :compressor)
    constraint_set_compressor_flow(gm, i)
end

for i in ids(gm, :ne_compressor)
    constraint_set_compressor_flow_ne(gm, i)
end

for i in ids(gm, :valve)
    constraint_set_valve_flow(gm, i)
end

for i in ids(gm, :control_valve)
    constraint_set_control_valve_flow(gm, i)
end
```
