# GasModels Network Data Format

## The Network Data Dictionary

Internally GasModels utilizes a dictionary to store network data. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The default I/O for GasModels utilizes this serialization direction as a text file.

The network data dictionary structure is roughly as follows:

```json
{
"name":<string>,        # a name for the model
"junction":{
    "1":{
      "qlmax": <float>,  # the maximum gas demand that can be added to qlfirm
      "qgmin": <float>,  # the minimum gas production that can be added to qgfirm
      "qgmax": <float>,  # the maximum gas production that can be added to qgfirm
      "qlmin": <float>,  # the minimum gas demand that can be added to qlfirm
      "qgfirm": <float>, # constant gas production
      "pmax": <float>,   # maximum pressure
      "qlfirm": <float>, # constant gas demand
      "pmin": <float>,   # minimum pressure
       ...
    },
    "2":{...},
    ...
},
"connection":{
    "1":{
      "length": <float>,       # the length of the connection
      "f_junction": <int>,     # the "from" side junction id
      "t_junction": <int>,     # the "to" side junction id
      "resistance": <float>,   # the resistance of the connection
      "diameter": <float>,     # the diameter of the connection
      "c_ratio_min": <float>,  # minimum multiplicative pressure change (compression or decompressions)
      "c_ratio_max": <float>,  # maximum multiplicative pressure change (compression or decompressions)      
      "type": <string>,        # the type of the connection. Can be "pipe", "compressor", "short_pipe", "control_valve", "valve"
        ...
    },
    "2":{...},
    ...
}
}
```

All data is assumed to have consistent units (i.e. metric, English, etc.)

The following commands can be used to explore the network data dictionary,

```julia
network_data = GasModels.parse_file("gaslib-40.json")
display(network_data)
```




