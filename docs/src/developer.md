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
