# Developer Documentation

## Variable, constraint and parameter naming scheme

### Suffixes

- `_ne`: used to denote a concept specific to network expansion problems
- `_ls`: used to denote a concept specific to implementations where production and consumption are variables.
- `_on_off`: used to denote a concept where there are either-or choices, such is valve operations or binary direction choices.

### Pressure

- `p`: pressure squared
- `pd_min`: minimum pressure squared difference (computed value)
- `pd_max`: maximum pressure squared difference (computed value)

### Flow

- `f`: mass flow
- `fl`: mass flow consumption
- `fg`: mass flow production

## Developing steady-state problems and formulations

In the current version of `GasModels`, the supported variable space is pressure (`p`) and mass flow (`f`) for steady-state modeling. Long term there are plans to support problems specified in the variable space of density $\rho$ and mass flux $\phi$.  Generally speaking, most steady-state models use/assume the single network formulation that is not discretized in time or space. Thus, most natural gas network models are read in and directly used by steady-state specifications.

A long term development plan is to largely unify the declaration of variables and constraints which are common to both steady-state and transient model (he only difference being single vs. multi-network representations).

## Developing transient problems and formulations

A basic version of the transient optimal gas flow problem is supported with the current version of `GasModels`. It uses the multi-network feature to formulate the problem. The entry point to create and prepare the transient data is the function `parse_files()` given below:

```@docs
parse_files
```

The function, in addition to taking as input the static matgas file and time-series csv files (the formats are discussed in [File IO](@ref) section), can take additional keyword arguments that concern a transient formulation. They are: (1) `total_time` which is the total time duration of the transient formulation. It defaults to the value of `86400.0`. Note that when this is the case the .csv file should contain time series data for the full 24 hours or else trying to construct a transient formulation would result in an error. The other keyword arguments include (2) `time_step`, (3) `spatial_discretization`, and (4) `additional_time`. As mentioned in the [Transient Problem Specifications](@ref) section the transient Optimal Gas Flow problem currently can work with only time-periodic time-series data. If the data is not time-periodic, then GasModels will try to fit a time-periodic spline to the data and then run the transient optimal gas flow problem. Notice that fitting a time-periodic spline for a non-time-periodic time series data would result in deviations from the given profiles and hence the argument `additional_time` can be used to pad the `total_time` with additional time to circumvent this issue. The `parse_files` function results in a multinetwork data model with the appropriate number of time discretizations that can then be used to formulate any transient optimization problem. The details of the transient formulation can be found in the section [Transient Problem Specifications](@ref).
