# GasModels Result Data Format

## The Result Data Dictionary

GasModels utilizes a dictionary to organize the results of a run command. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange.
The data dictionary organization is designed to be consistent with the GasModels [The Network Data Dictionary](@ref).

At the top level the results data dictionary is structured as follows:

```json
{
"solver":<string>,       # name of the Julia class used to solve the model
"status":<julia symbol>, # solver status at termination
"solve_time":<float>,    # reported solve time (seconds)
"objective":<float>,     # the final evaluation of the objective function
"objective_lb":<float>,  # the final lower bound of the objective function (if available)
"machine":{...},         # computer hardware information (details below)
"data":{...},            # test case information (details below)
"solution":{...}         # complete solution information (details below)
}
```

### Machine Data

This object provides basic information about the hardware that was 
used when the run command was called.

```json
{
"cpu":<string>,    # CPU product name
"memory":<string>  # the amount of system memory (units given)
}
```

### Case Data

This object provides basic information about the network cases that was 
used when the run command was called.

```json
{
"name":<string>,      # the name from the network data structure
"junction_count":<int>,    # the number of nodes in the network data structure
"connection_count":<int>  # the number of edges in the network data structure
}
```

### Solution Data

The solution object provides detailed information about the solution 
produced by the run command.  The solution is organized similarly to 
[The Network Data Dictionary](@ref) with the same nested structure and 
parameter names, when available.  A network solution most often only includes
a small subset of the data included in the network data.

For example the data for a junction, `data["junction"]["1"]` is structured as follows,

```
{
"pmin": 14000.0,
"pmax": 80000.0,
...
}
```

A solution specifying a pressure for the same case, i.e. `result["solution"]["junction"]["1"]`, would result in,

```
{
"p":50.5,
}
```

Because the data dictionary and the solution dictionary have the same structure 
InfrastructureModels `update_data!` helper function can be used to 
update a data dictionary with the values from a solution as follows,

```
InfrastructureModels.update_data!(data, result["solution"])
```

By default, all results are reported in per-unit (non-dimenionalized). Below are common outputs of implemented optimization models

```json
{
"junction":{
    "1":{
      "p": <float>,      # pressure. Non-dimensional quantity. Multiply by baseP to get pascals
      "psqr": <float>,   # pressure squared. Non-dimensional quantity. Multiply by baseP^2 to get pascals^2      
       ...
    },
    "2":{...},
    ...
},
"consumer":{
    "1":{
      "fl": <float>,  # variable mass flow consumed. Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. 
      "ql": <float>,  # the varible volumetric gas demand at standard density. Non-dimensional quantity. Multiply by baseQ to get m^3/s. 
       ...
    },
    "2":{...},
    ...
},
"producer":{
    "1":{
      "fg": <float>,  # variable mass flow produced. Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. 
      "qg": <float>,  # the varible volumetric gas produced at standard density. Non-dimensional quantity. Multiply by baseQ to get m^3/s.        ...
    },
    "2":{...},
    ...
},
"connection":{
    "1":{
      "f": <float>,                 # mass flow through the pipe.  Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. Mass flux is obtained through division of the cross-sectional area (A) of the pipe. A= (pi*diameter^2)/4
      "yp": <int>,                  # 1 if flux flows from f_junction. 0 otherwise
      "yn": <int>,                  # 1 if flux flows from t_junction. 0 otherwise
      "v": <int>,                   # 1 if valve is open. 0 otherwise      
      "ratio": <float>,             # multiplicative (de)compression ratio
        ...
    },
    "2":{...},
    ...
},
"ne_connection":{
    "1":{
      "f": <float>,                 # mass flow through the pipe.  Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. Mass flux is obtained through division of the cross-sectional area (A) of the pipe. A= (pi*diameter^2)/4
      "yp": <int>,                  # 1 if flux flows from f_junction. 0 otherwise
      "yn": <int>,                  # 1 if flux flows from t_junction. 0 otherwise
      "v": <int>,                   # 1 if valve is open. 0 otherwise      
      "ratio": <float>,             # multiplicative (de)compression ratio
      "built_zp": <float>,          # 1 if the pipe was built. 0 otherwise.
      "built_zc": <float>,          # 1 if compressor was built. 0 otherwise.      
        ...
    },
    "2":{...},
    ...
}
}
```

