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
    constraint_junction_flow(gm, i)
end
    
for i in [collect(ids(gm, :pipe)); collect(ids(gm, :resistor))] 
    constraint_pipe_flow(gm, i) 
end

for i in ids(gm, :short_pipe)
    constraint_short_pipe_flow(gm, i) 
end
        
for i in ids(gm, :compressor)
    constraint_compressor_flow(gm, i) 
end
    
for i in ids(gm, :valve)
    constraint_valve_flow(gm, i) 
end
    
for i in ids(gm, :control_valve)     
    constraint_control_valve_flow(gm, i) 
end
```

## Maximum Load (LS)


### Variables

```julia
variable_flow(gm)  
variable_pressure_sqr(gm)
variable_valve_operation(gm)
variable_load(gm)
variable_production(gm)
```

### Objective

```julia
objective_max_load(gm)
```

### Constraints

```julia
for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] 
    constraint_pipe_flow(gm, i) 
end
    
for i in ids(gm, :junction)
    constraint_junction_flow_ls(gm, i)      
end
    
for i in ids(gm, :short_pipe)
    constraint_short_pipe_flow(gm, i) 
end
        
for i in ids(gm, :compressor) 
    constraint_compressor_flow(gm, i) 
end
    
for i in ids(gm, :valve)     
    constraint_valve_flow(gm, i) 
end
    
for i in ids(gm, :control_valve) 
    constraint_control_valve_flow(gm, i) 
end
```

## Expansion Planning (NE)

### Objective
```julia
objective_min_ne_cost(gm)
```

### Variables
```julia
variable_pressure_sqr(gm)
variable_flow(gm)
variable_flow_ne(gm)    
variable_valve_operation(gm)
variable_pipe_ne(gm)
variable_compressor_ne(gm)
```

### Constraints
```julia
for i in ids(gm, :junction)
    constraint_junction_flow_ne(gm, i) 
end

for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] 
    constraint_pipe_flow_ne(gm, i)
end

for i in ids(gm,:ne_pipe) 
    constraint_new_pipe_flow_ne(gm, i)
end
    
for i in ids(gm, :short_pipe) 
    constraint_short_pipe_flow_ne(gm, i)
end
    
for i in ids(gm, :compressor)
    constraint_compressor_flow_ne(gm, i)
end
    
for i in ids(gm, :ne_compressor) 
    constraint_new_compressor_flow_ne(gm, i)
end  
         
for i in ids(gm, :valve)  
    constraint_valve_flow(gm, i)       
end
    
for i in ids(gm, :control_valve)
    constraint_control_valve_flow(gm, i)       
end
    
exclusive = Dict()
for (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]
    i = min(pipe["f_junction"],pipe["t_junction"])
    j = max(pipe["f_junction"],pipe["t_junction"])
   
    if haskey(exclusive, i) == false  
        exclusive[i] = Dict()
    end  
           
    if haskey(exclusive[i], j) == false 
        constraint_exclusive_new_pipes(gm, i, j)         
        exclusive[i][j] = true
    end             
end
```
