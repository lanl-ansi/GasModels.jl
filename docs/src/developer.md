# Developer Documentation

## Variable, constraint and parameter naming scheme

### Suffixes

- `_ne`: used to denote a concept specific to network expansion problems
- `_directed`: used to denote a concept specific to implementations where direction of flow is pre-determined.
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

A long term development plan is to largely unify the declartion of variables and constraints which are common to both steady-state and transient model (he only difference being single vs. multi-network representations).

## Developing transient problems and formulations
