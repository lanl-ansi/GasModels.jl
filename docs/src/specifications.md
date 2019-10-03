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
    constraint_mass_flow_balance(gm, i)
end

for i in ids(gm, :pipe)
    constraint_pipe_pressure(gm, i)
    constraint_pipe_mass_flow(gm,i)
    constraint_pipe_weymouth(gm,i)
end

for i in ids(gm, :resistor)
    constraint_resistor_pressure(gm, i)
    constraint_resistor_mass_flow(gm,i)
    constraint_resistor_weymouth(gm,i)
end

for i in ids(gm, :short_pipe)
  constraint_short_pipe_pressure(gm, i)
  constraint_short_pipe_mass_flow(gm, i)
end

for i in ids(gm, :compressor)
    constraint_compressor_mass_flow(gm, i)
    constraint_compressor_ratio(gm, i)
end

for i in ids(gm, :valve)
  constraint_on_off_valve_mass_flow(gm, i)
  constraint_on_off_valve_pressure(gm, i)
end

for i in ids(gm, :control_valve)
  constraint_on_off_control_valve_mass_flow(gm, i)
  constraint_on_off_control_valve_pressure(gm, i)
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
for i in ids(gm,:pipe)
    constraint_pipe_pressure(gm, i)
    constraint_pipe_mass_flow(gm,i)
    constraint_pipe_weymouth(gm,i)
end

for i in ids(gm,:resistor)
    constraint_resistor_pressure(gm, i)
    constraint_resistor_mass_flow(gm,i)
    constraint_resistor_weymouth(gm,i)
end

for i in ids(gm, :junction)
    constraint_mass_flow_balance(gm, i)
end

for i in ids(gm, :short_pipe)
  constraint_short_pipe_pressure(gm, i)
  constraint_short_pipe_mass_flow(gm, i)
end

for i in ids(gm, :compressor)
    constraint_compressor_mass_flow(gm, i)
    constraint_compressor_ratio(gm, i)
end

for i in ids(gm, :valve)
  constraint_on_off_valve_mass_flow(gm, i)
  constraint_on_off_valve_pressure(gm, i)
end

for i in ids(gm, :control_valve)
  constraint_on_off_control_valve_mass_flow(gm, i)
  constraint_on_off_control_valve_pressure(gm, i)
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
    constraint_mass_flow_balance_ne(gm, i)
end

for i in ids(gm,:pipe)
    constraint_pipe_pressure(gm, i)
    constraint_pipe_mass_flow(gm,i)
    constraint_pipe_weymouth(gm,i)
end

for i in ids(gm,:resistor)
    constraint_resistor_pressure(gm, i)
    constraint_resistor_mass_flow(gm,i)
    constraint_resistor_weymouth(gm,i)
end

for i in ids(gm,:ne_pipe)
    constraint_pipe_pressure(gm, i)
    constraint_pipe_mass_flow(gm,i)
    constraint_weymouth(gm,i)
end

for i in ids(gm, :short_pipe)
  constraint_short_pipe_pressure(gm, i)
  constraint_short_pipe_mass_flow(gm, i)
end

for i in ids(gm, :compressor)
    constraint_compressor_mass_flow(gm, i)
    constraint_compressor_ratio(gm, i)
end

for i in ids(gm, :ne_compressor)
    constraint_compressor_ratios_ne(gm, i)
    constraint_compressor_ne(gm, i)
    constraint_compressor_mass_flow_ne(gm, i)
end

for i in ids(gm, :valve)
  constraint_on_off_valve_mass_flow(gm, i)
  constraint_on_off_valve_pressure(gm, i)
end

for i in ids(gm, :control_valve)
  constraint_on_off_control_valve_mass_flow(gm, i)
  constraint_on_off_control_valve_pressure(gm, i)
end
```
