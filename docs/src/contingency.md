# Gas Contingency

## Overview

Gas contingencies modify the network data dictionary before solving the optimization problem. These modifications simulate:

* Component failures (e.g., pipes or compressors going offline)

* Compressor power outages (reduced compression capability)

The contingency system is designed to:

1. Mutate the case data dictionary in-place

2. Return structured success/failure results

## Core Types
### `Contingency` (Abstract Type)
```abstract type Contingency end```

Base type for all contingency types.

### ```FailedComponentContingency```
```
Base.@kwdef struct FailedComponentContingency <: Contingency
    asset_type::String
    asset_id::String
end
```

Represents a complete outage of a network asset.

Effect on data dictionary:

asset["status"] = 0

The asset is disabled and excluded from the optimization model.

### `PowerOutageContingency`
```
Base.@kwdef struct PowerOutageContingency <: Contingency
    asset_type::String
    asset_id::String
    available_power_fraction::Float64
end
```

Represents a compressor operating at reduced power.

Constraints:

0.0 ≤ available_power_fraction ≤ 1.0

Currently only supports "compressor" asset type

Effect on data dictionary:

Compressor maximum compression ratio is scaled:

`new_max=min+(max−min)×available_power_fraction`

This preserves feasibility while restricting compression capability.

### `ContingencyScenario`
```
Base.@kwdef struct ContingencyScenario
    name::String
    description::String = ""
    contingencies::Vector{<:Contingency}
end
```

Container for multiple contingencies applied together.

### `ContingencyResult`
```
struct ContingencyResult
    contingency::Contingency
    success::Bool
    message::String
end
```

Returned for each applied contingency.

Helper utilities:

```
all_applied(results)
summarize_results(results)
```
### Applying a Contingency
Main Entry Point

`apply_contingency!(case::AbstractDict, scenario::ContingencyScenario)`

Mutates the case dictionary in-place

Returns `Vector{ContingencyResult}`

Example:

```julia
scenario = ContingencyScenario(
    name = "Winter Storm",
    description = "Two pipes frozen, one compressor at reduced power",
    contingencies = [
        FailedComponentContingency(asset_type="pipe", asset_id="1"),
        FailedComponentContingency(asset_type="pipe", asset_id="2"),
        PowerOutageContingency(asset_type="compressor", asset_id="1", available_power_fraction=0.3),
    ]
)

results = apply_contingency!(case, scenario)
```