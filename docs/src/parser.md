# File IO

```@meta
CurrentModule = GasModels
```

## General Data Formats

The json file format is a direct JSON serialization of GasModels internal data model. As such, the json file format is intended to be a temporary storage format. GasModels does not maintain backwards
compatability with serializations of earlier versions of the Gas Models internal data model.

```@docs
parse_file
parse_json
```

## Matlab Data Files

The following method is the main methods for parsing Matlab data files:

```@docs
parse_matpower
```

We also provide the following (internal) helper methods:

```@autodocs
Modules = [GasModels]
Pages   = ["io/matpower.jl"]
Order   = [:function]
Private  = true
```

This format was designed to have a similar look a feel to the matlab MatPower format, however, it standardizes around data requirements developed by the GasModels development team. It is largely stable, though it has not yet standardized the data fields for valves, control valves, short pipes, resistors, and storage.  Such data can be incorporated using the matlab extensions developed in InfrastructureModels.jl, with standard formats expected to be introduced at a later date.

The top of the file contains global information about the network like its name, gas temperature, etc.

```
function mgc = gaslib40                       % Name of the network model

mgc.sound_speed = 312.805;                    % Speed of sound
mgc.temperature = 273.15;                     % Gas temperature
mgc.R = 8.314;                                % Universal gas constant
mgc.compressibility_factor = 0.8;             % Gas compressibility factor
mgc.gas_molar_mass = 0.0185674;               % Molar mass of the gas
mgc.gas_specific_gravity = 0.6;               % Specific gravity of the gas
mgc.specific_heat_capacity_ratio = 1.4;       % Heat capacity ratio of the gas
mgc.standard_density = 1.0;                   % Standard density value
mgc.baseP = 8101325;                          % Normalization constant for pressure
mgc.baseF = 604.167;                          % Normalization constant for flow
mgc.per_unit = true;                          % Whether or not the parameters are in per unit
```

Junction data is defined with the following tabular format

```
%% junction data
%  junction_i type pmin pmax status p
mgc.junction = [
...
]
```

where `junction_i` is the unique identifier of the junction, `type` indicates whether or not the junction can be used as a slack node ('type=1'), `pmin` is the minimum pressure, `pmax` is the maximum pressure, `status` is the 0/1 status of the junction and `p` is a nominal pressure value.

Pipeline data is defined with the following tabular format

```
%% pipeline data
% pipeline_i f_junction t_junction diameter length friction_factor status
mgc.pipe = [
...
]
```

where `pipeline_i` is the unique identifier of the pipe, `f_junction` is the identifier of the from junction, `t_junction` is the identifier of the to junction, `diameter` is the diameter of the pipe, `length` is the length of the pipe, `friction_factor` is the friction level of the pipe, and `status` is the 0/1 status of the pipe.

Compressor data is defined with the following tabular format

```
%% compressor data
% compressor_i f_junction t_junction cmin cmax power_max fmin fmax status
mgc.compressor = [
...
```

where `compressor_i` is the unique identifier of the compressor, `f_junction` is the identifier of the from junction, `t_junction` is the identifier of the to junction, `cmin` is the minimum boost ratio of the compressor, `cmax` is the maximum boost ratio of the compressor, `power_max` is the maximum power for the compressor, `fmin` is the minimum flow through the compressor, `fmax` is the minimum flow through the compressor, and `status` is the 0/1 status of the pipe.

Producer data is defined with the following tabular format

```
%% producer
% producer_i junction fgmin fgmax fg status dispatchable
mgc.producer = [
...
```

where `producer_i` is the unique identifier of the producer, `junction` is the identifier of the junction, `fgmin` is the minimum production, `fgmax` is the maximum production, `fg` is the normal production, `status` is the 0/1 status of the pipe, and `dispatchable` indicates whether or not the producer can modify its production.

Consumer data is defined with the following tabular format


```
%% consumer
% consumer_i junction fd status dispatchable
mgc.consumer = [
...
```

where `consumer_i` is the unique identifier of the consumer, `junction` is the identifier of the junction, `fd` is the normal consumption, `status` is the 0/1 status of the pipe, and `dispatchable` indicates whether or not the producer can modify its production.
