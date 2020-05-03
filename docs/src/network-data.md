# GasModels Network Data Format

## The Network Data Dictionary

Internally GasModels utilizes a dictionary to store network data. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. GasModels can utilize this serialization as a text file, however GasModels does not support backwards compatibility for such serializations. When used as serialization, the data is assumed to be in per_unit (non dimenisionalized) or SI units.

The network data dictionary structure is roughly as follows:

```json
{
"name":<string>,                         # a name for the model
"temperature":<float>,                   # gas temperature. SI units are kelvin
"is_per_units":<int>,                    # Whether or not the file is in per unit (non dimensional units) or SI units.
"is_english_units":<int>,                # Whether or not the file is in english units
"gas_molar_mass":<float>,                # molecular mass of the gas. SI units are kg/mol
"gas_specific_gravity":<float>,          # the specific gravity of the gas. Non-dimensional.
"multinetwork":<boolean>,                # flag for whether or not this is multiple networks
"base_length":<float>,                   # Base for non-dimensionalizing space (length). Si units are m
"base_flow":<float>,                     # Base for non-dimensionalizing mass flow. SI units are kg/s
"base_pressure":<float>,                 # Base for non-dimensionalizing pressure. SI units are pascal
"base_time":<float>,                     # Base for non-dimensionalizing time. SI units are s
"compressibility_factor":<float>,        # Gas compressability. Non-dimensional.
"specific_heat_capacity_ratio":<float>,  # Gas compressability. Non-dimensional.
"sound_speed":<float>,                   # Speed of sound through the gas. SI units are m/s.
"R":<float>,                             # Universal Gas constant. SI units are J/mol/K.
"junction":{
    "1":{
      "p_max": <float>,    # maximum pressure. SI units are pascals
      "p_min": <float>,    # minimum pressure. SI units are pascals
      "p_nominal": <float>,  # nominal pressure. SI units are pascals
      "status": <int>,    # status of the component (0 = off, 1 = on). Default is 1.
      "lat":<float>, # latitude position of the junction (optional)
      "lon":<float>, # latitude position of the junction (optional)
       ...
    },
    "2":{...},
    ...
},
"delivery":{
    "1":{
      "junction_id": <float>,  # junction id
      "withdrawal_max": <float>,  # the maximum mass flow demand. SI units are kg/s.
      "withdrawal_min": <float>,  # the minimum mass flow demand. SI units are kg/s.
      "withdrawal_nominal": <float>, # nominal mass flow demand. SI units are kg/s.
      "priority": <float>, # priority for serving the variable load. High numbers reflect a higher desired to serve this load.
      "bid_price": <float>, # price for buying gas at the delivery.
      "is_dispatchable": <int>,  # whether or not the unit is dispatchable (0 = delivery should consume withdrawl_nominal, 1 = delivery can consume between withdrawal_min and withdrawal_max).
      "status": <int>,   # status of the component (0 = off, 1 = on). Default is 1.
       ...
    },
    "2":{...},
    ...
},
"receipt":{
    "1":{
      "junction_id": <float>,         # junction id
      "injection_min": <float>,       # the minimum mass flow gas production. SI units are kg/s.
      "injection_max": <float>,       # the maximum mass flow gas production. SI units are kg/s.
      "injection_nominal": <float>,   # nominal mass flow production at standard density. SI units are kg/s.
      "dispatchable": <int>,          # whether or not the unit is dispatchable (0 = receipt should produce injection_nominal, 1 = receipt can produce between injection_min and injection_max).
      "offer_price": <float>,         # price for selling gas at the receipt.
      "status": <int>,                # status of the component (0 = off, 1 = on). Default is 1.
       ...
    },
    "2":{...},
    ...
},
"pipe":{
    "1":{
      "length": <float>,            # the length of the connection. SI units are m.
      "fr_junction": <int>,         # the "from" side junction id
      "to_junction": <int>,         # the "to" side junction id
      "friction_factor": <float>,   # the friction component of the resistance term of the pipe. Non dimensional.
      "diameter": <float>,          # the diameter of the connection. SI units are m.
      "status": <int>,              # status of the component (0 = off, 1 = on). Default is 1.
      "p_max": <float>,             # maximum pressure. SI units are pascals
      "p_min": <float>,             # minimum pressure. SI units are pascals
      "is_bidirectional": <int>,    # flag for whether or not flow can go in both directions
        ...
    },
    "2":{...},
    ...
},
"compressor":{
    "1":{
      "fr_junction": <int>,         # the "from" side junction id
      "to_junction": <int>,         # the "to" side junction id
      "c_ratio_min": <float>,       # minimum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
      "c_ratio_max": <float>,       # maximum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
      "status": <int>,              # status of the component (0 = off, 1 = on). Default is 1.
      "operating_cost": <float>,    # The cost per W of running the compressor
      "power_max": <float>,         # Maximum power consumed by the compressor. SI units is W
      "type": <int>,                # type of the compressor (two way compression or not, one way flow or not, etc.)
        ...
    },
    "2":{...},
    ...
}
"short_pipe":{
    "1":{
      "fr_junction": <int>,          # the "from" side junction id
      "to_junction": <int>,          # the "to" side junction id
      "status": <int>,              # status of the component (0 = off, 1 = on). Default is 1.
      "is_bidirectional": <int>,    # flag for whether or not flow can go in both directions
        ...
    },
    "2":{...},
    ...
}
"valve":{
    "1":{
      "fr_junction": <int>,          # the "from" side junction id
      "to_junction": <int>,          # the "to" side junction id
      "status": <int>,              # status of the component (0 = off, 1 = on). Default is 1.
      "is_bidirectional": <int>,    # flag for whether or not flow can go in both directions
        ...
    },
    "2":{...},
    ...
}
"regulator":{
    "1":{
      "fr_junction": <int>,          # the "from" side junction id
      "to_junction": <int>,          # the "to" side junction id
      "c_ratio_min": <float>,       # minimum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
      "c_ratio_max": <float>,       # maximum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
      "status": <int>,              # status of the component (0 = off, 1 = on). Default is 1.
      "is_bidirectional": <int>,    # flag for whether or not flow can go in both directions
        ...
    },
    "2":{...},
    ...
}
"resistor":{
    "1":{
      "fr_junction": <int>,          # the "from" side junction id
      "to_junction": <int>,          # the "to" side junction id
      "drag": <float>,              # the drag factor of resistors. Non dimensional.
      "status": <int>,              # status of the component (0 = off, 1 = on). Default is 1.
      "is_bidirectional": <int>,    # flag for whether or not flow can go in both directions
        ...
    },
    "2":{...},
    ...
}
}
```

All data is assumed to have consistent units (i.e. SI units or non-dimensionalized units)

The following commands can be used to explore the network data dictionary,

```julia
network_data = GasModels.parse_file("gaslib-40.m")
display(network_data)
```
