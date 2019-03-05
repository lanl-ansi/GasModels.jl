# GasModels Network Data Format

## The Network Data Dictionary

Internally GasModels utilizes a dictionary to store network data. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The default I/O for GasModels utilizes this serialization as a text file. When used as serialization, the data is assumed to be in per_unit (non dimenisionalized) or SI units.

The network data dictionary structure is roughly as follows:

```json
{
"name":<string>,                   # a name for the model
"temperature":<float>,             # gas temperature. SI units are kelvin
"multinetwork":<boolean>,          # flag for whether or not this is multiple networks
"gas_molar_mass":<float>,          # molecular mass of the gas. SI units are kg/mol
"standard_density":<float>,        # Standard (nominal) density of the gas. SI units are kg/m^3
"per_unit":<boolean>,              # Whether or not the file is in per unit (non dimensional units) or SI units.  Note that the only quantities that are non-dimensionalized are pressure and flux.  
"compressibility_factor":<float>,  # Gas compressability. Non-dimensional.
"baseQ":<float>,                   # Base for non-dimensionalizing volumetric flow at standard density. SI units are m^3/s
"baseP":<float>,                   # Base for non-dimensionalizing pressure. SI units are pascal.
"junction":{
    "1":{
      "pmax": <float>,   # maximum pressure. SI units are pascals
      "pmin": <float>,   # minimum pressure. SI units are pascals
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
       ...
    },
    "2":{...},
    ...
},
"consumer":{
    "1":{
      "ql_junc": <float>,  # junction id
      "qlmax": <float>,  # the maximum volumetric gas demand at standard density that can be added to qlfirm. SI units are m^3/s.
      "qlmin": <float>,  # the minimum volumetric gas demand gas demand at standard density that can be added to qlfirm. SI units are m^3/s.
      "qlfirm": <float>, # constant volumetric gas demand gas demand at standard density. SI units are m^3/s.
      "priority": <float>, # priority for serving the variable load. High numbers reflect a higher desired to serve this load.
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
       ...
    },
    "2":{...},
    ...
},
"producer":{
    "1":{
      "qg_junc": <float>,  # junction id
      "qgmin": <float>,  # the minimum volumetric gas production at standard density that can be added to qgfirm. SI units are m^3/s.
      "qgmax": <float>,  # the maximum volumetric gas production at standard density that can be added to qgfirm. SI units are m^3/s.
      "qgfirm": <float>, # constant volumetric gas production at standard density. SI units are m^3/s.
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
       ...
    },
    "2":{...},
    ...
},
"pipe":{
    "1":{
      "length": <float>,            # the length of the connection. SI units are m.
      "f_junction": <int>,          # the "from" side junction id
      "t_junction": <int>,          # the "to" side junction id
      "friction_factor": <float>,   # the friction component of the resistance term of the pipe. Non dimensional.
      "diameter": <float>,          # the diameter of the connection. SI units are m.
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
        ...
    },
    "2":{...},
    ...
},
"compressor":{
    "1":{
      "f_junction": <int>,          # the "from" side junction id
      "t_junction": <int>,          # the "to" side junction id
      "c_ratio_min": <float>,       # minimum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
      "c_ratio_max": <float>,       # maximum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).      
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
        ...
    },
    "2":{...},
    ...
}
"short_pipe":{
    "1":{
      "f_junction": <int>,          # the "from" side junction id
      "t_junction": <int>,          # the "to" side junction id
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
        ...
    },
    "2":{...},
    ...
}
"valve":{
    "1":{
      "f_junction": <int>,          # the "from" side junction id
      "t_junction": <int>,          # the "to" side junction id
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
        ...
    },
    "2":{...},
    ...
}
"control_valve":{
    "1":{
      "f_junction": <int>,          # the "from" side junction id
      "c_ratio_min": <float>,       # minimum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
      "c_ratio_max": <float>,       # maximum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).      
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
        ...
    },
    "2":{...},
    ...
}
"resistor":{
    "1":{
      "f_junction": <int>,          # the "from" side junction id
      "t_junction": <int>,          # the "to" side junction id
      "drag": <float>,              # the drag factor of resistors. Non dimensional.
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
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
