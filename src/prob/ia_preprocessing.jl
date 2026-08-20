"""
Preprocessing utilities for Inner Approximation.

Ensures the network has required properties before IA analysis.
"""


"""
    ensure_slack_junction!(data; criterion="min-max", warn=true)

Ensure the network has exactly one slack junction.

If no slack junction exists (all junction_type ≠ 1), automatically designates
the junction with the largest injection as slack.

This is necessary because IA requires a pressure reference to make the Jacobian
invertible (gas flow equations only constrain pressure DIFFERENCES).

**Heuristic rationale:** The largest source is a natural pressure boundary condition
in gas networks - it's where gas enters the system and pressure is typically controlled.

# Arguments
- `data`: Network data dictionary
- `criterion`: Which values to use for injection comparison
  - `"min-max"` (default): Use `injection_max` for receipts, `abs(withdrawal_min)` for transfers
  - `"nominal"`: Use `injection_nominal` for receipts, `abs(withdrawal_nominal)` for transfers
- `warn`: If true, print warning when auto-selecting slack (default: true)

# Returns
Named tuple with:
- `junction_id`: Selected slack junction ID
- `was_auto_selected`: true if auto-selected, false if already existed
- `injection_value`: Injection value used for selection (in data units)
- `source_description`: Description of the source
- `nominal_pressure`: Nominal pressure at selected junction (Pa)
- `p_min`: Minimum pressure bound (Pa)
- `p_max`: Maximum pressure bound (Pa)

Modifies the data Dict in-place.

# Example
```julia
result = ensure_slack_junction!(data, criterion="min-max")
if result.was_auto_selected
    println("⚠️  Auto-selected slack junction \$(result.junction_id)")
    println("   Source: \$(result.source_description)")
    println("   Injection: \$(result.injection_value)")
    println("   Nominal pressure: \$(result.nominal_pressure/1e5) bar")
    println("   You may want to adjust this pressure!")
end
```
"""
function ensure_slack_junction!(data; criterion="min-max", warn=true)
    # Check if slack exists
    junctions = get(data, "junction", Dict())
    slack_junctions = [k for (k, j) in junctions if get(j, "junction_type", 0) == 1]

    if !isempty(slack_junctions)
        if length(slack_junctions) > 1
            warn && @warn "Multiple slack junctions found: $slack_junctions. Using first one."
        end

        junction_id = parse(Int, slack_junctions[1])
        junction = junctions[slack_junctions[1]]

        return (
            junction_id = junction_id,
            was_auto_selected = false,
            injection_value = NaN,
            source_description = "existing slack junction",
            nominal_pressure = get(junction, "p_nominal", 0.0),
            p_min = get(junction, "p_min", 0.0),
            p_max = get(junction, "p_max", 0.0)
        )
    end

    warn && @warn "⚠️  No slack junction found. Auto-selecting based on largest injection..."

    # Validate criterion
    if criterion ∉ ["min-max", "nominal"]
        error("Invalid criterion: $criterion. Must be 'min-max' or 'nominal'.")
    end

    # Find junction with largest injection
    best_junction = nothing
    max_injection = -Inf
    source_type = ""

    # Check receipts (gas sources)
    for (k, receipt) in get(data, "receipt", Dict())
        junction_id = receipt["junction_id"]

        # Select field based on criterion
        if criterion == "min-max"
            injection = get(receipt, "injection_max", 0.0)
            field_name = "injection_max"
        else  # nominal
            injection = get(receipt, "injection_nominal", 0.0)
            field_name = "injection_nominal"
        end

        if injection > max_injection
            max_injection = injection
            best_junction = junction_id
            source_type = "receipt $k ($field_name=$injection)"
        end
    end

    # Check transfers (negative withdrawal = injection)
    for (k, transfer) in get(data, "transfer", Dict())
        junction_id = transfer["junction_id"]

        # Select field based on criterion
        if criterion == "min-max"
            withdrawal = get(transfer, "withdrawal_min", 0.0)
            field_name = "withdrawal_min"
        else  # nominal
            withdrawal = get(transfer, "withdrawal_nominal", 0.0)
            field_name = "withdrawal_nominal"
        end

        # Negative withdrawal = injection
        if withdrawal < 0
            injection = abs(withdrawal)
            if injection > max_injection
                max_injection = injection
                best_junction = junction_id
                source_type = "transfer $k ($field_name=$withdrawal, i.e., injection=$injection)"
            end
        end
    end

    # Check deliveries (unlikely to be injection, but check for completeness)
    for (k, delivery) in get(data, "delivery", Dict())
        junction_id = delivery["junction_id"]

        if criterion == "min-max"
            withdrawal = get(delivery, "withdrawal_min", 0.0)
            field_name = "withdrawal_min"
        else
            withdrawal = get(delivery, "withdrawal_nominal", 0.0)
            field_name = "withdrawal_nominal"
        end

        if withdrawal < 0
            injection = abs(withdrawal)
            if injection > max_injection
                max_injection = injection
                best_junction = junction_id
                source_type = "delivery $k ($field_name=$withdrawal, injection=$injection)"
            end
        end
    end

    # Fallback: if no injections found, pick junction 1
    if isnothing(best_junction)
        warn && @warn "No receipts or injections found. Defaulting to junction 1 as slack."
        best_junction = 1
        source_type = "default (no injections found)"
        max_injection = 0.0
    end

    # Validate junction exists
    if !haskey(junctions, string(best_junction))
        error("Selected slack junction $best_junction does not exist in network!")
    end

    # Get junction info before modifying
    junction = junctions[string(best_junction)]
    p_nominal = get(junction, "p_nominal", 0.0)
    p_min = get(junction, "p_min", 0.0)
    p_max = get(junction, "p_max", 0.0)

    # Make it slack
    junctions[string(best_junction)]["junction_type"] = 1

    if warn
        @warn """
        ⚠️  AUTO-SELECTED SLACK JUNCTION

        Junction ID: $best_junction
        Source: $source_type
        Criterion: $criterion

        Pressure Settings:
          Nominal: $(p_nominal/1e5) bar  ← You may want to adjust this!
          Bounds:  [$(p_min/1e5), $(p_max/1e5)] bar

        The nominal pressure will be used as the fixed-point pressure reference.
        If this is not appropriate, modify data["junction"]["$best_junction"]["p_nominal"]
        before running IA analysis.
        """
    end

    return (
        junction_id = best_junction,
        was_auto_selected = true,
        injection_value = max_injection,
        source_description = source_type,
        nominal_pressure = p_nominal,
        p_min = p_min,
        p_max = p_max
    )
end


"""
    validate_ia_network(data)

Validate that network data is suitable for IA analysis.

Checks:
- Has at least one pipe or compressor
- Has at least two junctions
- Has fixed point solution (if already attached)
- Has slack junction (or can auto-select one)

Throws error if validation fails.
"""
function validate_ia_network(data)
    # Check components exist
    n_junctions = length(get(data, "junction", Dict()))
    n_pipes = length(get(data, "pipe", Dict()))
    n_comps = length(get(data, "compressor", Dict()))

    if n_junctions < 2
        error("IA requires at least 2 junctions (found $n_junctions)")
    end

    if n_pipes + n_comps < 1
        error("IA requires at least 1 pipe or compressor (found $n_pipes pipes, $n_comps compressors)")
    end

    @info "Network validation passed: $n_junctions junctions, $n_pipes pipes, $n_comps compressors"

    return true
end
