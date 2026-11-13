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

### `DirectionalFlowLimitContingency`
```
Base.@kwdef struct DirectionalFlowLimitContingency <: Contingency
    asset_type::String     # pipe, compressor, short_pipe, resistor, loss_resistor, valve, regulator
    asset_id::String
    direction::String      # "north", "south", "east", or "west"
    max_mass_flow::Float64 # kg/s
end
```

Limits the mass flow through an edge when the gas travels in a given compass direction. Use this, for example, for a maintenance posting that caps a compressor station at different northbound and southbound capacities. To limit both directions, use two contingencies.

**Coordinates are required.** The direction is mapped onto the edge's `fr_junction` → `to_junction` orientation using the great-circle bearing between the two junctions' `lat`/`lon`. If the forward bearing has a positive component in `direction`, forward flow is capped (`flow_max`); if it is negative, reverse flow is capped (`flow_min`). The contingency is not applied (returns `success = false`) if either junction lacks coordinates, or if the edge runs exactly perpendicular to `direction`. A diagonal edge counts as travelling in both of its compass components. For example, a north-east edge is limited by both a `"north"` and an `"east"` contingency.

Effect on data dictionary:

`flow_max = min(flow_max, cap)` or `flow_min = max(flow_min, -cap)`, where `cap` is `max_mass_flow` converted to the case's units (per-unit, SI, or English).

Bounds are only ever tightened. Apply after `parse_file`, since parsing recomputes flow bounds. This is respected by all steady-state formulations:

* **Continuous (WP, CWP, LRWP)**: the bound is a box bound on the flow variable. The problem stays continuous.
* **Discrete (DWP, CRDWP, LRDWP)**: the bound also appears in the direction on/off constraints `(1-y)·f_min ≤ f ≤ y·f_max`, which tightens the relaxation. A cap of `0` fixes the direction binary.

Transient formulations do not read `flow_min`/`flow_max` and ignore this contingency.

#### Converting energy-based capacity
Pipeline postings usually give capacity in Dth/d. `dth_per_day_to_kgps(dth_per_day, data; heating_value = 1037.0)` converts these to kg/s. It assumes a heating value in Btu/scf (default 1037, the approximate U.S. pipeline average) and uses the network's gas properties for standard density. See the function docstring for the full set of assumptions.

```julia
case = parse_file("network.m")
scenario = ContingencyScenario(
    name = "Compressor maintenance",
    contingencies = [
        DirectionalFlowLimitContingency(asset_type="compressor", asset_id="7", direction="north",
                                        max_mass_flow=dth_per_day_to_kgps(255_000, case)),
        DirectionalFlowLimitContingency(asset_type="compressor", asset_id="7", direction="south",
                                        max_mass_flow=dth_per_day_to_kgps(285_000, case)),
    ]
)
results = apply_contingency!(case, scenario)
```

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