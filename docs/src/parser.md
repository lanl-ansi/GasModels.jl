# File IO

```@meta
CurrentModule = GasModels
```

## General Data Formats

The json file format is a direct JSON serialization of GasModels internal data model. As such, the json file format is intended to be a temporary storage format. GasModels does not maintain backwards compatibility with serializations of earlier versions of the Gas Models internal data model.

```@docs
parse_file
parse_json
```

## Matgas Data Files

The following method is the main methods for parsing Matgas data files:

```@docs
parse_matgas
```

We also provide the following (internal) helper methods:

```@autodocs
Modules = [GasModels]
Pages   = ["io/matgas.jl"]
Order   = [:function]
Private  = true
```

This format was designed to have a similar look a feel to the Matlab MatPower format (in the case of GasModels, we refer to it as the MatGas format), however, it standardizes around data requirements developed by the GasModels development team. It is largely stable. Additional fields for each component in the MatGas format can be incorporated using the Matlab extensions developed in InfrastructureModels.jl.

The top of the file contains global information about the network like its name, gas temperature, etc.

```
function mgc = gaslib-40

%% required global data
mgc.gas_specific_gravity         = 0.6;
mgc.specific_heat_capacity_ratio = 1.4;  % unitless
mgc.temperature                  = 273.15;  % K
mgc.compressibility_factor       = 0.8;  % unitless
mgc.units                        = 'si';

%% optional global data (that was either provided or computed based on required global data)
mgc.gas_molar_mass               = 0.01857; % kg/mol
mgc.R                            = 8.314;  % J/(mol K)
mgc.base_length                  = 5000;  % m (non-dimensionalization value)
mgc.base_pressure                = 8101325;  % Pa (non-dimensionalization value)
mgc.base_flow                    = 604; (non-dimensionalization value)
mgc.per_unit                  = 0;
mgc.sound_speed                  = 312.8060
```

Junction data is defined with the following tabular format

```
%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon
mgc.junction = [
...
]
```

The reader is referred to [Matgas Format (.m)](@ref) for detailed description on each column in the above table.

Pipeline data is defined with the following tabular format

```
%% pipe data
% id fr_junction to_junction diameter length friction_factor p_min p_max status
mgc.pipe = [
...
]
```

The reader is referred to [Matgas Format (.m)](@ref) for detailed description on each column in the above table.

Compressor data is defined with the following tabular format

```
%% compressor data
% id fr_junction to_junction c_ratio_min c_ratio_max power_max flow_min flow_max inlet_p_min inlet_p_max outlet_p_min outlet_p_max status operating_cost directionality
mgc.compressor = [
...
```

The reader is referred to [Matgas Format (.m)](@ref) for detailed description on each column in the above table.

Receipt data is defined with the following tabular format

```
%% receipt data
% id junction_id injection_min injection_max injection_nominal is_dispatchable status
mgc.receipt = [
...
```

The reader is referred to [Matgas Format (.m)](@ref) for detailed description on each column in the above table.

Delivery data is defined with the following tabular format

```
%% delivery data
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status
mgc.delivery = [
...
```

The reader is referred to [Matgas Format (.m)](@ref) for detailed description on each column in the above table.

## Parsing Transient Data
To run the transient formulations, apart from parsing the network file [Matgas Format (.m)](@ref), a time-series [Transient Data Format (CSV)](@ref) file has to be parsed. The following method provides a way to do so:

```@docs
parse_files
```

The data dictionary returned by the above function is a multi-network data dictionary with spatial discretization performed on pipelines with length greater than `spatial_discretization` keyword argument.
