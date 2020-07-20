import XMLDict
import ZipFile


"Parses GasLib data appearing in a compressed ZIP directory."
function parse_gaslib(zip_path::Union{IO,String})
    # Read in the compressed directory and obtain file paths.
    zip_reader = ZipFile.Reader(zip_path)
    file_paths = [x.name for x in zip_reader.files]

    # Parse the topology XML file.
    fid = findfirst(x -> occursin(".net", x), file_paths)
    topology_xml = _parse_xml_file(zip_reader, fid)

    # Parse the compressor XML file.
    fid = findfirst(x -> occursin(".cs", x), file_paths)
    compressor_xml = fid != nothing ? _parse_xml_file(zip_reader, fid) : Dict()

    # Parse the nomination XML file(s).
    fids = findall(x -> occursin(".scn", x), file_paths)

    # TODO: If length(fids) > 1, treat the input as a multinetwork.
    if length(fids) > 1 # If multiple scenarios are defined.
        # Parse and use the last nominations file when sorted by name.
        nomination_path = sort(file_paths[fids])[end]
        fid = findfirst(x -> occursin(nomination_path, x), file_paths)
        nomination_xml = _parse_xml_file(zip_reader, fid)

        # Print a warning message stating that the above file is being used.
        Memento.warn(_LOGGER, "Multiple nomination file paths found " *
                     "in GasLib data. Selecting last nomination file " *
                     "(i.e., \"$(file_paths[fid])\") " *
                     "after sorting by name.")
    else # If only one nominations scenario is defined...
        # Parse and use the only nominations file available.
        nomination_xml = _parse_xml_file(zip_reader, fids[end])
    end

    # Compute bulk data from averages of network data.
    density = _compute_gaslib_density(topology_xml)
    temperature = _compute_gaslib_temperature(topology_xml)
    molar_mass = _compute_gaslib_molar_mass(topology_xml)
    sound_speed = sqrt(8.314 * temperature * inv(molar_mass))

    # Per the approximation in "Approximating Nonlinear Relationships for
    # Optimal Operation of Natural Gas Transport Networks" by Kazda and Li.
    isentropic_exponent = 1.29 - 5.8824e-4 * (temperature - 273.15)

    # Create a dictionary for all components.
    junctions = _read_gaslib_junctions(topology_xml)
    pipes = _read_gaslib_pipes(topology_xml, junctions, density)
    regulators = _read_gaslib_regulators(topology_xml, density)
    resistors = _read_gaslib_resistors(topology_xml, density)
    short_pipes = _read_gaslib_short_pipes(topology_xml, density)
    valves = _read_gaslib_valves(topology_xml, density)
    loss_resistors = _read_gaslib_loss_resistors(topology_xml, density)
    compressors = _read_gaslib_compressors(topology_xml, compressor_xml,
        temperature, 8.314 * inv(molar_mass), isentropic_exponent, density)
    deliveries = _read_gaslib_deliveries(topology_xml, nomination_xml, density)
    receipts = _read_gaslib_receipts(topology_xml, nomination_xml, density)

    # Add auxiliary nodes for bidirectional compressors.
    _add_auxiliary_junctions!(junctions, compressors, regulators)

    # Build the master data dictionary.
    data = Dict{String,Any}("compressor"=>compressors, "delivery"=>deliveries,
        "junction"=>junctions, "receipt"=>receipts, "pipe"=>pipes,
        "regulator"=>regulators, "resistor"=>resistors, "loss_resistor"=>loss_resistors,
        "short_pipe"=>short_pipes, "valve"=>valves, "is_si_units"=>true,
        "per_unit"=>false, "sound_speed"=>sound_speed)

    # Assign nodal IDs in place of string IDs.
    data = _correct_ids(data)

    # Return the dictionary.
    return data
end


function _parse_xml_file(zip_reader, path_index)
    xml_str = ZipFile.read(zip_reader.files[path_index], String)
    return XMLDict.parse_xml(xml_str)
end


function _correct_ids(data::Dict{String,<:Any})
    new_data = deepcopy(data)
    junction_names = keys(data["junction"])
    junction_mapping = Dict(k=>i for (i, k) in enumerate(junction_names))

    for (junction_name, junction) in data["junction"]
        i = junction_mapping[junction_name]
        new_data["junction"][string(i)] = junction
        new_data["junction"][string(i)]["id"] = i
        new_data["junction"][string(i)]["index"] = i
        delete!(new_data["junction"], junction_name)
    end

    for node_type in ["delivery", "receipt"]
        node_names = keys(data[node_type])

        for (i, node_name) in enumerate(node_names)
            new_data[node_type][string(i)] = data[node_type][node_name]
            new_data[node_type][string(i)]["id"] = i
            new_data[node_type][string(i)]["index"] = i
            new_data[node_type][string(i)]["junction_id"] = junction_mapping[node_name]
            delete!(new_data[node_type], node_name)
        end
    end

    for edge_type in ["compressor", "pipe", "resistor", "regulator", "short_pipe", "valve", "loss_resistor"]
        edge_id = 1

        for (a, edge) in data[edge_type]
            fr_junction, to_junction = edge["fr_junction"], edge["to_junction"]
            edge["fr_junction"] = junction_mapping[fr_junction]
            edge["to_junction"] = junction_mapping[to_junction]
            edge["id"] = edge["index"] = edge_id
            new_data[edge_type][string(edge_id)] = edge
            delete!(new_data[edge_type], a)
            edge_id += 1
        end
    end

    return new_data
end


function _add_auxiliary_junctions!(junctions, compressors, regulators)
    new_junctions = Dict{String,Any}()
    new_regulators = Dict{String,Any}()

    for (a, regulator) in regulators
        if regulator["bypass_required"] == 1
            fr_junction = junctions[regulator["fr_junction"]]
            to_junction = junctions[regulator["to_junction"]]

            junction_aux_name = a * "_aux_junction"
            junction_aux = deepcopy(fr_junction)

            regulator_reverse_name = a * "_reverse"
            regulator_reverse = deepcopy(regulator)
            regulator_reverse["fr_junction"] = junction_aux_name
            regulator_reverse["flow_min"] = -regulator["flow_max"]
            regulator_reverse["flow_max"] = -regulator["flow_min"]
            regulator["to_junction"] = junction_aux_name

            push!(new_junctions, junction_aux_name=>junction_aux)
            push!(new_regulators, regulator_reverse_name=>regulator_reverse)
        end
    end

    junctions = _IM.update_data!(junctions, new_junctions)
    regulators = _IM.update_data!(regulators, new_regulators)
end


function _compute_node_temperature(node::XMLDict.XMLDictElement)
    if uppercase(node["gasTemperature"][:unit]) == "CELSIUS"
        return 273.15 + parse(Float64, node["gasTemperature"][:value])
    elseif uppercase(node["gasTemperature"][:unit]) == "K"
        return parse(Float64, node["gasTemperature"][:value])
    end
end


function _compute_gaslib_density(topology::XMLDict.XMLDictElement)
    node_types = ["innode", "sink", "source"]
    node_xml = vcat([get(topology["nodes"], x, []) for x in node_types]...)
    nodes = filter(x -> "normDensity" in collect(keys(x)), node_xml)
    sum_density = sum([parse(Float64, node["normDensity"][:value]) for node in nodes])
    return sum_density * inv(length(nodes)) # Return the mean density.
end


function _compute_gaslib_temperature(topology::XMLDict.XMLDictElement)
    node_types = ["innode", "sink", "source"]
    node_xml = vcat([get(topology["nodes"], x, []) for x in node_types]...)
    nodes = filter(x -> "gasTemperature" in collect(keys(x)), node_xml)
    sum_temperature = sum([_compute_node_temperature(node) for node in nodes])
    return sum_temperature * inv(length(nodes)) # Return the mean temperature.
end


function _compute_gaslib_molar_mass(topology::XMLDict.XMLDictElement)
    node_types = ["innode", "sink", "source"]
    node_xml = vcat([get(topology["nodes"], x, []) for x in node_types]...)
    nodes = filter(x -> "molarMass" in collect(keys(x)), node_xml)
    sum_molar_mass = sum([parse(Float64, node["molarMass"][:value]) for node in nodes])
    return 1.0e-3 * sum_molar_mass * inv(length(nodes)) # Return the mean.
end


function _get_component_dict(data)
    return data isa Array ? Dict{String,Any}(x[:id] => x for x in data) :
        Dict{String,Any}(x[:id] => x for x in [data])
end


function _get_compressor_entry(compressor, stations, T::Float64, R::Float64, kappa::Float64, density::Float64)
    fr_junction, to_junction = compressor[:from], compressor[:to]
    inlet_p_min = parse(Float64, compressor["pressureInMin"][:value]) * 1.0e5
    inlet_p_max = parse(Float64, compressor["pressureOutMax"][:value]) * 1.0e5
    outlet_p_min = parse(Float64, compressor["pressureInMin"][:value]) * 1.0e5
    outlet_p_max = parse(Float64, compressor["pressureOutMax"][:value]) * 1.0e5
    flow_min = density * parse(Float64, compressor["flowMin"][:value]) * inv(3.6)
    flow_max = density * parse(Float64, compressor["flowMax"][:value]) * inv(3.6)
    bypass_required = :internalBypassRequired in keys(compressor) ?
        parse(Int, compressor[:internalBypassRequired]) : 1

    if flow_max <= 0.0
        flow_min, flow_max = -flow_max, -flow_min
        fr_junction, to_junction = to_junction, fr_junction
    end

    flow_min = bypass_required == 1 ? -flow_max : flow_min

    if flow_min >= 0.0
        directionality, is_bidirectional = 1, 0
    elseif bypass_required == 1 && sign(flow_min) != sign(flow_max)
        directionality, is_bidirectional = 2, 1
    elseif bypass_required == 0 && sign(flow_min) != sign(flow_max)
        directionality, is_bidirectional = 1, 1
    else
        directionality, is_bidirectional = 0, 1
    end

    if "diameterIn" in keys(compressor) && "diameterOut" in keys(compressor)
        diameter_in = _parse_gaslib_length(compressor["diameterIn"])
        diameter_out = _parse_gaslib_length(compressor["diameterOut"])
        diameter = max(diameter_in, diameter_out)
    else
        diameter = nothing
    end

    c_ratio_min, c_ratio_max = 0.0, outlet_p_max * inv(inlet_p_min)
    operating_cost = 10.0 # GasLib files don't contain cost data.

    # Calculate the maximum power.
    exp = kappa * inv(kappa - 1.0)
    H_max = R * T * 1.0 * exp * (c_ratio_max^inv(exp) - 1.0)

    # Assume a worst-case efficiency of 0.1 in the computation of power_max.
    power_max = H_max * abs(flow_max) * inv(0.1)

    return Dict{String,Any}("is_per_unit"=>false, "fr_junction"=>fr_junction,
        "to_junction"=>to_junction, "inlet_p_min"=>inlet_p_min, "inlet_p_max"=>inlet_p_max,
        "outlet_p_min"=>outlet_p_min, "outlet_p_max"=>outlet_p_max, "flow_min"=>flow_min,
        "flow_max"=>flow_max, "diameter"=>diameter, "is_bidirectional"=>is_bidirectional,
        "is_per_unit"=>0, "directionality"=>directionality, "status"=>1, "is_si_units"=>1,
        "is_english_units"=>0, "c_ratio_min"=>c_ratio_min, "c_ratio_max"=>c_ratio_max,
        "power_max"=>power_max, "operating_cost"=>operating_cost)
end


function _get_delivery_entry(delivery, density::Float64)
    if delivery["flow"] isa Array
        min_id = findfirst(x -> x[:bound] == "lower", delivery["flow"])
        withdrawal_min = density * parse(Float64, delivery["flow"][min_id][:value]) * inv(3.6)
        max_id = findfirst(x -> x[:bound] == "upper", delivery["flow"])
        withdrawal_max = density * parse(Float64, delivery["flow"][max_id][:value]) * inv(3.6)
    else
        withdrawal_min = density * parse(Float64, delivery["flow"][:value]) * inv(3.6)
        withdrawal_max = density * parse(Float64, delivery["flow"][:value]) * inv(3.6)
    end

    is_dispatchable = withdrawal_min != withdrawal_max

    return Dict{String,Any}("withdrawal_min"=>withdrawal_min,
        "withdrawal_max"=>withdrawal_max, "withdrawal_nominal"=>withdrawal_max,
        "is_dispatchable"=>is_dispatchable, "is_per_unit"=>0, "status"=>1, "is_si_units"=>1,
        "is_english_units"=>0, "junction_id"=>delivery[:id])
end


function _get_junction_entry(junction)
    lat_sym = :geoWGS84Lat in keys(junction) ? :geoWGS84Lat : :x
    lat = parse(Float64, junction[lat_sym])
    lon_sym = :geoWGS84Long in keys(junction) ? :geoWGS84Long : :y
    lon = parse(Float64, junction[lon_sym])

    height = parse(Float64, junction["height"][:value])
    p_min = parse(Float64, junction["pressureMin"][:value]) * 1.0e5
    p_max = parse(Float64, junction["pressureMax"][:value]) * 1.0e5

    return Dict{String,Any}("lat"=>lat, "lon"=>lon, "p_min"=>p_min, "p_max"=>p_max,
        "height"=>height, "is_dispatchable"=>0, "status"=>1, "junction_type"=>0,
        "is_per_unit"=>0, "is_si_units"=>1, "is_english_units"=>0, "edi_id"=>junction[:id],
        "id"=>junction[:id], "index"=>junction[:id], "pipeline_id"=>"")
end


function _parse_gaslib_length(entry)
    if entry[:unit] == "m"
        return parse(Float64, entry[:value])
    elseif entry[:unit] == "km"
        return parse(Float64, entry[:value]) * 1000.0
    elseif entry[:unit] == "mm"
        return parse(Float64, entry[:value]) * inv(1000.0)
    end
end


function _get_pipe_entry(pipe, junctions, density::Float64)
    fr_junction, to_junction = pipe[:from], pipe[:to]
    p_min = min(junctions[fr_junction]["p_min"], junctions[to_junction]["p_min"])
    p_max = max(junctions[fr_junction]["p_max"], junctions[to_junction]["p_max"])

    if "pressureMin" in keys(pipe)
        p_min = max(p_min, parse(Float64, pipe["pressureMin"][:value]) * 1.0e5)
    end

    if "pressureMax" in keys(pipe)
        p_max = min(p_max, parse(Float64, pipe["pressureMax"][:value]) * 1.0e5)
    end

    diameter = _parse_gaslib_length(pipe["diameter"])
    length = _parse_gaslib_length(pipe["length"])
    roughness = _parse_gaslib_length(pipe["roughness"])
    friction_factor = (2.0 * log(3.7 * diameter * inv(roughness)))^(-2)

    # Determine bidirectionality.
    flow_min = density * parse(Float64, pipe["flowMin"][:value]) * inv(3.6)
    flow_max = density * parse(Float64, pipe["flowMax"][:value]) * inv(3.6)

    if flow_max <= 0.0
        flow_min, flow_max = -flow_max, -flow_min
        fr_junction, to_junction = to_junction, fr_junction
    end

    is_bidirectional = flow_min > 0.0 ? 0 : 1

    return Dict{String,Any}("fr_junction"=>fr_junction, "to_junction"=>to_junction,
        "diameter"=>diameter, "length"=>length, "p_min"=>p_min, "p_max"=>p_max,
        "friction_factor"=>friction_factor, "is_bidirectional"=>is_bidirectional,
        "status"=>1, "is_per_unit"=>0, "is_si_units"=>1, "is_english_units"=>0)
end


function _get_loss_resistor_entry(loss_resistor, density::Float64)
    fr_junction, to_junction = loss_resistor[:from], loss_resistor[:to]
    flow_min = density * parse(Float64, loss_resistor["flowMin"][:value]) * inv(3.6)
    flow_max = density * parse(Float64, loss_resistor["flowMax"][:value]) * inv(3.6)

    if flow_max <= 0.0
        flow_min, flow_max = -flow_max, -flow_min
        fr_junction, to_junction = to_junction, fr_junction
    end

    p_loss = parse(Float64, loss_resistor["pressureLoss"][:value]) * 1.0e5
    is_bidirectional = flow_min > 0.0 ? 0 : 1

    return Dict{String,Any}("fr_junction"=>fr_junction, "to_junction"=>to_junction,
        "flow_min"=>flow_min, "flow_max"=>flow_max, "p_loss"=>p_loss, "is_per_unit"=>0,
        "status"=>1, "is_si_units"=>1, "is_english_units"=>0,
        "is_bidirectional"=>is_bidirectional)
end


function _get_short_pipe_entry(short_pipe, density::Float64)
    fr_junction, to_junction = short_pipe[:from], short_pipe[:to]
    flow_min = density * parse(Float64, short_pipe["flowMin"][:value]) * inv(3.6)
    flow_max = density * parse(Float64, short_pipe["flowMax"][:value]) * inv(3.6)

    if flow_max <= 0.0
        flow_min, flow_max = -flow_max, -flow_min
        fr_junction, to_junction = to_junction, fr_junction
    end

    is_bidirectional = flow_min > 0.0 ? 0 : 1

    return Dict{String,Any}("fr_junction"=>fr_junction, "to_junction"=>to_junction,
        "is_bidirectional"=>is_bidirectional, "is_per_unit"=>0, "status"=>1,
        "is_si_units"=>1, "is_english_units"=>0)
end


function _get_receipt_entry(receipt, density::Float64)
    if receipt["flow"] isa Array
        min_id = findfirst(x -> x[:bound] == "lower", receipt["flow"])
        injection_min = density * parse(Float64, receipt["flow"][min_id][:value]) * inv(3.6)
        max_id = findfirst(x -> x[:bound] == "upper", receipt["flow"])
        injection_max = density * parse(Float64, receipt["flow"][max_id][:value]) * inv(3.6)
    else
        injection_min = density * parse(Float64, receipt["flow"][:value]) * inv(3.6)
        injection_max = density * parse(Float64, receipt["flow"][:value]) * inv(3.6)
    end

    is_dispatchable = injection_min != injection_max

    return Dict{String,Any}("injection_min"=>injection_min, "injection_max"=>injection_max,
        "injection_nominal"=>injection_max, "is_dispatchable"=>is_dispatchable,
        "is_per_unit"=>0, "status"=>1, "is_si_units"=>1, "is_english_units"=>0,
        "junction_id"=>receipt[:id])
end


function _get_resistor_entry(resistor, density::Float64)
    fr_junction, to_junction = resistor[:from], resistor[:to]
    flow_min = density * parse(Float64, resistor["flowMin"][:value]) * inv(3.6)
    flow_max = density * parse(Float64, resistor["flowMax"][:value]) * inv(3.6)

    if flow_max <= 0.0
        flow_min, flow_max = -flow_max, -flow_min
        fr_junction, to_junction = to_junction, fr_junction
    end

    diameter = _parse_gaslib_length(resistor["diameter"])
    drag = parse(Float64, resistor["dragFactor"][:value])
    is_bidirectional = flow_min > 0.0 ? 0 : 1

    return Dict{String,Any}("fr_junction"=>fr_junction, "to_junction"=>to_junction,
        "flow_min"=>flow_min, "flow_max"=>flow_max, "drag"=>drag, "diameter"=>diameter,
        "is_per_unit"=>0, "status"=>1, "is_si_units"=>1, "is_english_units"=>0,
        "is_bidirectional"=>is_bidirectional)
end


function _get_valve_entry(valve, density::Float64)
    fr_junction, to_junction = valve[:from], valve[:to]
    flow_min = density * parse(Float64, valve["flowMin"][:value]) * inv(3.6)
    flow_max = density * parse(Float64, valve["flowMax"][:value]) * inv(3.6)

    if flow_max <= 0.0
        flow_min, flow_max = -flow_max, -flow_min
        fr_junction, to_junction = to_junction, fr_junction
    end

    return Dict{String,Any}("fr_junction"=>fr_junction, "is_english_units"=>0,
        "to_junction"=>to_junction, "flow_min"=>flow_min, "flow_max"=>flow_max, "status"=>1,
        "directionality"=>1, "is_per_unit"=>0, "is_si_units"=>1)
end


function _get_regulator_entry(regulator, density::Float64)
    fr_junction, to_junction = regulator[:from], regulator[:to]
    flow_min = density * parse(Float64, regulator["flowMin"][:value]) * inv(3.6)
    flow_max = density * parse(Float64, regulator["flowMax"][:value]) * inv(3.6)

    if flow_max <= 0.0
        flow_min, flow_max = -flow_max, -flow_min
        fr_junction, to_junction = to_junction, fr_junction
    end

    bypass_required = :internalBypassRequired in keys(regulator) ?
        parse(Int, regulator[:internalBypassRequired]) : 1

    flow_min = bypass_required == 1 ? -flow_max : flow_min
    reduction_factor_min, reduction_factor_max = 0.0, 1.0
    is_bidirectional = flow_min > 0.0 ? 0 : 1
    bypass_required = bypass_required

    return Dict{String,Any}("fr_junction"=>fr_junction, "is_english_units"=>0,
        "to_junction"=>to_junction, "flow_min"=>flow_min, "is_si_units"=>1,
        "flow_max"=>flow_max, "reduction_factor_min"=>reduction_factor_min,
        "reduction_factor_max"=>reduction_factor_max, "status"=>1,
        "is_bidirectional"=>is_bidirectional, "is_per_unit"=>0,
        "bypass_required"=>bypass_required)
end


function _read_gaslib_compressors(topology, compressor_stations, T::Float64, R::Float64, kappa::Float64, density::Float64)
    if "compressorStation" in keys(topology["connections"])
        compressors = _get_component_dict(topology["connections"]["compressorStation"])
        stations = "compressorStation" in keys(compressor_stations) ? compressor_stations["compressorStation"] : nothing
        return Dict{String,Any}(i => _get_compressor_entry(x, stations, T, R, kappa, density) for (i, x) in compressors)
    else
        return Dict{String,Any}()
    end
end


function _read_gaslib_deliveries(topology::XMLDict.XMLDictElement, nominations::XMLDict.XMLDictElement, density::Float64)
    node_xml = _get_component_dict(get(nominations["scenario"], "node", []))

    # Collect source nodes with negative injections.
    source_ids = [x[:id] for x in get(topology["nodes"], "source", [])]
    source_xml = filter(x -> x.second[:id] in source_ids, node_xml)
    source_data = Dict{String,Any}(i => _get_delivery_entry(x, density) for (i, x) in source_xml)
    source_data = filter(x -> x.second["withdrawal_max"] < 0.0, source_data)

    # Collect sink nodes with positive withdrawals.
    sink_ids = [x[:id] for x in get(topology["nodes"], "sink", [])]
    sink_xml = filter(x -> x.second[:id] in sink_ids, node_xml)
    sink_data = Dict{String,Any}(i => _get_delivery_entry(x, density) for (i, x) in sink_xml)
    sink_data = filter(x -> x.second["withdrawal_min"] > 0.0, sink_data)

    # For sink nodes with negative injections, negate the values.
    for (i, source) in source_data
        source["withdrawal_min"] *= -1.0
        source["withdrawal_max"] *= -1.0
        source["withdrawal_nominal"] *= -1.0
    end

    return merge(source_data, sink_data)
end


function _read_gaslib_junctions(topology::XMLDict.XMLDictElement)
    node_types = ["innode", "sink", "source"]
    node_xml = vcat([get(topology["nodes"], x, []) for x in node_types]...)
    return Dict{String,Any}(x[:id] => _get_junction_entry(x) for x in node_xml)
end


function _read_gaslib_pipes(topology::XMLDict.XMLDictElement, junctions::Dict{String,<:Any}, density::Float64)
    pipe_xml = _get_component_dict(get(topology["connections"], "pipe", []))
    return Dict{String,Any}(i => _get_pipe_entry(x, junctions, density) for (i, x) in pipe_xml)
end


function _read_gaslib_loss_resistors(topology::XMLDict.XMLDictElement, density::Float64)
    loss_resistor_xml = _get_component_dict(get(topology["connections"], "resistor", []))
    loss_resistor_xml = filter(x -> "pressureLoss" in collect(keys(x.second)), loss_resistor_xml)
    return Dict{String,Any}(i => _get_loss_resistor_entry(x, density) for (i, x) in loss_resistor_xml)
end


function _read_gaslib_receipts(topology::XMLDict.XMLDictElement, nominations::XMLDict.XMLDictElement, density::Float64)
    node_xml = _get_component_dict(get(nominations["scenario"], "node", []))

    # Collect source nodes with positive injections.
    source_ids = [x[:id] for x in get(topology["nodes"], "source", [])]
    source_xml = filter(x -> x.second[:id] in source_ids, node_xml)
    source_data = Dict{String,Any}(i => _get_receipt_entry(x, density) for (i, x) in source_xml)
    source_data = filter(x -> x.second["injection_min"] > 0.0, source_data)

    # Collect sink nodes with negative withdrawals.
    sink_ids = [x[:id] for x in get(topology["nodes"], "sink", [])]
    sink_xml = filter(x -> x.second[:id] in sink_ids, node_xml)
    sink_data = Dict{String,Any}(i => _get_receipt_entry(x, density) for (i, x) in sink_xml)
    sink_data = filter(x -> x.second["injection_max"] < 0.0, sink_data)

    # For sink nodes with negative withdrawals, negate the values.
    for (i, sink) in sink_data
        sink["injection_min"] *= -1.0
        sink["injection_max"] *= -1.0
        sink["injection_nominal"] *= -1.0
    end

    return merge(source_data, sink_data)
end


function _read_gaslib_regulators(topology::XMLDict.XMLDictElement, density::Float64)
    regulator_xml = _get_component_dict(get(topology["connections"], "controlValve", []))
    return Dict{String,Any}(i => _get_regulator_entry(x, density) for (i, x) in regulator_xml)
end


function _read_gaslib_resistors(topology::XMLDict.XMLDictElement, density::Float64)
    resistor_xml = _get_component_dict(get(topology["connections"], "resistor", []))
    resistor_xml = filter(x -> "dragFactor" in collect(keys(x.second)), resistor_xml)
    resistor_xml = filter(x -> parse(Float64, x.second["dragFactor"][:value]) > 0.0, resistor_xml)
    return Dict{String,Any}(i => _get_resistor_entry(x, density) for (i, x) in resistor_xml)
end


function _read_gaslib_short_pipes(topology::XMLDict.XMLDictElement, density::Float64)
    # Parse all short pipes in the network.
    short_pipe_xml = _get_component_dict(get(topology["connections"], "shortPipe", []))
    short_pipes = Dict{String,Any}(i => _get_short_pipe_entry(x, density) for (i, x) in short_pipe_xml)

    # Resistors with drag equal to zero should also be considered short pipes.
    resistor_xml = _get_component_dict(get(topology["connections"], "resistor", []))
    resistor_xml = filter(x -> "dragFactor" in collect(keys(x.second)), resistor_xml)
    resistor_xml = filter(x -> parse(Float64, x.second["dragFactor"][:value]) <= 0.0, resistor_xml)
    resistors = Dict{String,Any}(i => _get_short_pipe_entry(x, density) for (i, x) in resistor_xml)

    # Return the merged dictionary of short pipes and resistors.
    return merge(short_pipes, resistors)
end


function _read_gaslib_valves(topology::XMLDict.XMLDictElement, density::Float64)
    valve_xml = _get_component_dict(get(topology["connections"], "valve", []))
    return Dict{String,Any}(i => _get_valve_entry(x, density) for (i, x) in valve_xml)
end
