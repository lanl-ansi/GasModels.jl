import XMLDict
import ZipFile

function _read_gaslib_file(gaslib_zip, extension::String)
    index = findfirst(x -> occursin(extension, x.name), gaslib_zip.files)
    subdata_xml = ZipFile.read(gaslib_zip.files[index], String)
    return XMLDict.xml_dict(subdata_xml)
end

function _get_compressor_entry(compressor)
    return Dict{String,Any}("withdrawal_min"=>0.0, "injection_max"=>0.0,
        "withdrawal_nominal"=>0.0, "is_dispatchable"=>0, "is_per_unit"=>0,
        "status"=>1, "is_si_units"=>1, "is_english_units"=>0,
        "compressor_id"=>compressor[:id])
end

function _get_delivery_entry(delivery)
    injection_max = parse(Float64, delivery["flow"][:value]) * inv(3.6)
    return Dict{String,Any}("withdrawal_min"=>0.0, "injection_max"=>injection_max,
        "withdrawal_nominal"=>injection_max, "is_dispatchable"=>0, "is_per_unit"=>0,
        "status"=>1, "is_si_units"=>1, "is_english_units"=>0, "junction_id"=>delivery[:id])
end

function _get_junction_entry(junction)
    lat, lon = junction[:geoWGS84Lat], junction[:geoWGS84Long]
    pmin = parse(Float64, junction["pressureMin"][:value]) * 1.0e5
    pmax = parse(Float64, junction["pressureMax"][:value]) * 1.0e5

    return Dict("lat"=>lat, "lon"=>lon, "pmin"=>pmin, "pmax"=>pmax,
                "is_dispatchable"=>0, "is_per_unit"=>0, "status"=>1,
                "is_si_units"=>1, "is_english_units"=>0, "edi_id"=>junction[:id],
                "id"=>junction[:id], "index"=>junction[:id], "pipeline_id"=>"")
end

function _get_pipe_entry(pipe)
    fr_junction = pipe[:from]
    to_junction = pipe[:to]
    p_max = parse(Float64, pipe["pressureMax"][:value]) * 1.0e5
    diameter = parse(Float64, pipe["diameter"][:value]) * inv(1000.0)
    length = parse(Float64, pipe["length"][:value]) * 1000.0

    return Dict{String,Any}("fr_junction"=>fr_junction, "to_junction"=>to_junction,
        "diameter"=>diameter, "length"=>length, "is_per_unit"=>0, "status"=>1,
        "is_si_units"=>1, "is_english_units"=>0, "junction_id"=>pipe[:id],
        "p_max"=>p_max)
end

function _get_receipt_entry(receipt)
    injection_max = parse(Float64, receipt["flow"][:value]) * inv(3.6)
    return Dict{String,Any}("injection_min"=>0.0, "injection_max"=>injection_max,
        "injection_nominal"=>injection_max, "is_dispatchable"=>0, "is_per_unit"=>0,
        "status"=>1, "is_si_units"=>1, "is_english_units"=>0, "junction_id"=>receipt[:id])
end

function _get_gaslib_compressors(topology, compressor_stations)
    compressors = topology["network"]["connections"]["compressorStation"]
    compressors = Dict(x[:id] => x for x in compressors)
    return Dict(i => _get_compressor_entry(x) for (i, x) in compressors)
end

function _get_gaslib_deliveries(topology, nomination)
    ids = [x[:id] for x in topology["network"]["nodes"]["sink"]]
    scenario = nomination["boundaryValue"]["scenario"]
    deliveries = Dict(x[:id] => x for x in scenario["node"] if x[:id] in ids)
    return Dict(i => _get_delivery_entry(x) for (i, x) in deliveries)
end

function _get_gaslib_junctions(topology)
    nodes = topology["network"]["nodes"]["innode"]
    nodes = vcat(nodes, topology["network"]["nodes"]["sink"])
    nodes = vcat(nodes, topology["network"]["nodes"]["source"])
    junctions = Dict(x[:id] => x for x in nodes)
    return Dict(i => _get_junction_entry(x) for (i, x) in junctions)
end

function _get_gaslib_pipes(topology)
    pipes = topology["network"]["connections"]["pipe"]
    pipes = Dict(x[:id] => x for x in pipes)
    return Dict(i => _get_pipe_entry(x) for (i, x) in pipes)
end

function _get_gaslib_receipts(topology, nomination)
    ids = [x[:id] for x in topology["network"]["nodes"]["source"]]
    scenario = nomination["boundaryValue"]["scenario"]
    receipts = Dict(x[:id] => x for x in scenario["node"] if x[:id] in ids)
    return Dict(i => _get_receipt_entry(x) for (i, x) in receipts)
end

function parse_gaslib(zip_path::Union{IO, String})
    # Read in the relevant data files as dictionaries.
    gaslib_zip = ZipFile.Reader(zip_path)
    topology = _read_gaslib_file(gaslib_zip, ".net")
    nominations = _read_gaslib_file(gaslib_zip, ".scn")
    compressor_stations = _read_gaslib_file(gaslib_zip, ".cs")

    # Create a dictionary for receipt components.
    compressors = _get_gaslib_compressors(topology, compressor_stations)
    deliveries = _get_gaslib_deliveries(topology, nominations)
    junctions = _get_gaslib_junctions(topology)
    receipts = _get_gaslib_receipts(topology, nominations)
    pipes = _get_gaslib_pipes(topology)

    return Dict{String,Any}("compressor"=>compressors, "delivery"=>deliveries,
        "junction"=>junctions, "receipt"=>receipts, "pipe"=>pipes)
end
