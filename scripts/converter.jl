using GasModels
using JSON

include("old_matlab.jl")

file = ARGS[1]

json_out_file = split(file, ".")[1] * ".json"
matgas_out_file = split(file, ".")[1] * "_matgas.m"


println("$file -> $matgas_out_file")

if endswith(file, ".json")
    data = open(file, "r") do f
        data = JSON.parse(f)
    end
else
    data = parse_old_matlab(file)
end

@show data["per_unit"]

accepted_keys = ["junction"]
for (i, junction) in data["junction"]
    junction["id"] =
        (get(junction, "junction_i", false) == true) ? Int(junction["junction_i"]) :
        parse(Int64, i)
    if (data["per_unit"] == 1)
        junction["p_min"] = junction["pmin"] * data["baseP"]
        junction["p_max"] = junction["pmax"] * data["baseP"]
        junction["p_nominal"] =
            (get(junction, "p", false) == true) ? junction["p"] * data["baseP"] :
            junction["pmin"] * data["baseP"]
    else
        junction["p_min"] = junction["pmin"]
        junction["p_max"] = junction["pmax"]
        junction["p_nominal"] =
            (get(junction, "p", false) == true) ? junction["p"] : junction["pmin"]
    end
    junction["junction_type"] =
        (get(junction, "junction_type", false) == true) ? Int(junction["junction_type"]) : 0
    junction["pipeline_name"] = split(file, ".")[1]
    junction["edi_id"] = Int(junction["id"])
    junction["lat"] = get(junction, "latitude", 0.0)
    junction["lon"] = get(junction, "longitude", 0.0)
    junction["status"] = 1

    delete!(junction, "junction_i")
    delete!(junction, "index")
    delete!(junction, "pmin")
    delete!(junction, "pmax")
    delete!(junction, "p")
    delete!(junction, "latitude")
    delete!(junction, "longitude")
end

push!(accepted_keys, "pipe")
for (i, pipe) in data["pipe"]
    pipe["id"] =
        (get(pipe, "pipline_i", false) != false) ? Int(pipe["pipline_i"]) : parse(Int64, i)
    pipe["fr_junction"] = pipe["f_junction"]
    pipe["to_junction"] = pipe["t_junction"]
    pipe["p_min"] = min(
        data["junction"][string(pipe["fr_junction"])]["p_min"],
        data["junction"][string(pipe["to_junction"])]["p_min"],
    )
    pipe["p_max"] = max(
        data["junction"][string(pipe["fr_junction"])]["p_max"],
        data["junction"][string(pipe["to_junction"])]["p_max"],
    )
    pipe["status"] = 1
    delete!(pipe, "pipline_i")
    delete!(pipe, "f_junction")
    delete!(pipe, "t_junction")
    delete!(pipe, "index")
end

push!(accepted_keys, "compressor")
for (i, compressor) in data["compressor"]
    compressor["status"] = 1
    compressor["id"] = (get(compressor, "compressor_i", false) != false) ?
        Int(compressor["compressor_i"]) : parse(Int64, i)
    compressor["fr_junction"] = Int(compressor["f_junction"])
    compressor["to_junction"] = Int(compressor["t_junction"])
    if get(compressor, "qmin", false) == false
        compressor["qmin"] = -1e4
        compressor["qmax"] = 1e4
    end
    if compressor["qmin"] == compressor["qmax"]
        compressor["qmin"] = 0.0
    end
    if data["per_unit"] == 1
        compressor["flow_min"] = compressor["qmin"] * data["baseQ"]
        compressor["flow_max"] = compressor["qmax"] * data["baseQ"]
    else
        compressor["flow_min"] = compressor["qmin"] * data["baseQ"]
        compressor["flow_max"] = compressor["qmax"] * data["baseQ"]
    end
    compressor["inlet_p_min"] = min(
        data["junction"][string(compressor["fr_junction"])]["p_min"],
        data["junction"][string(compressor["to_junction"])]["p_min"],
    )
    compressor["inlet_p_max"] = max(
        data["junction"][string(compressor["fr_junction"])]["p_max"],
        data["junction"][string(compressor["to_junction"])]["p_max"],
    )
    compressor["outlet_p_min"] = min(
        data["junction"][string(compressor["fr_junction"])]["p_min"],
        data["junction"][string(compressor["to_junction"])]["p_min"],
    )
    compressor["outlet_p_max"] = max(
        data["junction"][string(compressor["fr_junction"])]["p_max"],
        data["junction"][string(compressor["to_junction"])]["p_max"],
    )
    compressor["operating_cost"] = 10.0
    compressor["directionality"] = 2
    compressor["power_max"] = get(compressor, "power_max", 1e9)

    delete!(compressor, "compressor_i")
    delete!(compressor, "f_junction")
    delete!(compressor, "t_junction")
    delete!(compressor, "index")
    delete!(compressor, "qmin")
    delete!(compressor, "qmax")
end

push!(accepted_keys, "receipt")
data["receipt"] = Dict()
for (i, producer) in data["producer"]
    data["receipt"][i] = Dict{String,Any}()
    data["receipt"][i]["id"] =
        (get(producer, "producer_i", false) != false) ? Int(producer["producer_i"]) :
        parse(Int64, i)
    data["receipt"][i]["junction_id"] =
        (get(producer, "junction", false) != false) ? producer["junction"] :
        producer["qg_junc"]
    data["receipt"][i]["status"] =
        (get(producer, "status", false) != false) ? producer["status"] : Int(1)
    data["receipt"][i]["is_dispatchable"] = producer["dispatchable"]
    if data["per_unit"] == 1
        data["receipt"][i]["injection_min"] = producer["qgmin"] * data["baseQ"]
        data["receipt"][i]["injection_max"] = producer["qgmax"] * data["baseQ"]
        data["receipt"][i]["injection_nominal"] = producer["qg"] * data["baseQ"]
    else
        data["receipt"][i]["injection_min"] = producer["qgmin"]
        data["receipt"][i]["injection_max"] = producer["qgmax"]
        data["receipt"][i]["injection_nominal"] = producer["qg"]
    end
end
delete!(data, "producer")

push!(accepted_keys, "delivery")
data["delivery"] = Dict()
for (i, consumer) in data["consumer"]
    data["delivery"][i] = Dict{String,Any}()
    data["delivery"][i]["id"] =
        (get(consumer, "consumer_i", false) != false) ? Int(consumer["consumer_i"]) :
        parse(Int64, i)
    data["delivery"][i]["junction_id"] =
        (get(consumer, "junction", false) != false) ? consumer["junction"] :
        consumer["ql_junc"]
    data["delivery"][i]["status"] =
        (get(consumer, "status", false) != false) ? Int(consumer["status"]) : Int(1)
    data["delivery"][i]["is_dispatchable"] = consumer["dispatchable"]
    if haskey(consumer, "priority")
        data["delivery"][i]["priority"] = consumer["priority"]
    end
    if data["per_unit"] == 1
        data["delivery"][i]["withdrawal_min"] = consumer["qlmin"] * data["baseQ"]
        data["delivery"][i]["withdrawal_max"] = consumer["qlmax"] * data["baseQ"]
        data["delivery"][i]["withdrawal_nominal"] = consumer["ql"] * data["baseQ"]
    else
        data["delivery"][i]["withdrawal_min"] = consumer["qlmin"]
        data["delivery"][i]["withdrawal_max"] = consumer["qlmax"]
        data["delivery"][i]["withdrawal_nominal"] = consumer["ql"]
    end
end
delete!(data, "consumer")

push!(accepted_keys, "valve")
for (i, valve) in get(data, "valve", [])
    valve["id"] = parse(Int64, i)
    valve["fr_junction"] = valve["f_junction"]
    valve["to_junction"] = valve["t_junction"]
    valve["status"] = 1
    delete!(valve, "f_junction")
    delete!(valve, "t_junction")
end

push!(accepted_keys, "short_pipe")
for (i, short_pipe) in get(data, "short_pipe", [])
    short_pipe["id"] = parse(Int64, i)
    short_pipe["fr_junction"] = short_pipe["f_junction"]
    short_pipe["to_junction"] = short_pipe["t_junction"]
    short_pipe["status"] = 1
    short_pipe["is_bidirectional"] = 1
    delete!(short_pipe, "f_junction")
    delete!(short_pipe, "t_junction")
end

push!(accepted_keys, "resistor")
for (i, resistor) in get(data, "resistor", [])
    resistor["id"] = parse(Int64, i)
    resistor["fr_junction"] = resistor["f_junction"]
    resistor["to_junction"] = resistor["t_junction"]
    resistor["status"] = 1
    resistor["is_bidirectional"] = 1
    delete!(resistor, "f_junction")
    delete!(resistor, "t_junction")
end

push!(accepted_keys, "regulator")
data["regulator"] = Dict()
for (i, control_valve) in get(data, "control_valve", [])
    data["regulator"][i] = Dict{String,Any}()
    data["regulator"][i]["id"] = parse(Int64, i)
    data["regulator"][i]["fr_junction"] = control_valve["f_junction"]
    data["regulator"][i]["to_junction"] = control_valve["t_junction"]
    data["regulator"][i]["reduction_factor_min"] = control_valve["c_ratio_min"]
    data["regulator"][i]["reduction_factor_max"] = control_valve["c_ratio_max"]
    data["regulator"][i]["status"] = 1
    if get(control_valve, "qmin", false) == false
        control_valve["qmin"] = -1e4
        control_valve["qmax"] = 1e4
    end
    if data["per_unit"] == 1
        data["regulator"][i]["flow_min"] = control_valve["qmin"] * data["baseQ"]
        data["regulator"][i]["flow_max"] = control_valve["qmax"] * data["baseQ"]
    else
        data["regulator"][i]["flow_min"] = control_valve["qmin"]
        data["regulator"][i]["flow_max"] = control_valve["qmax"]
    end
    data["regulator"][i]["is_bidirectional"] = 1
end
if length(data["regulator"]) == 0
    delete!(data, "regulator")
end

if haskey(data, "ne_pipe")
    push!(accepted_keys, "ne_pipe")
    for (i, pipe) in data["ne_pipe"]
        pipe["id"] = (get(pipe, "pipline_i", false) != false) ? Int(pipe["pipline_i"]) :
            parse(Int64, i)
        pipe["fr_junction"] = pipe["f_junction"]
        pipe["to_junction"] = pipe["t_junction"]
        pipe["p_min"] = min(
            data["junction"][string(pipe["fr_junction"])]["p_min"],
            data["junction"][string(pipe["to_junction"])]["p_min"],
        )
        pipe["p_max"] = max(
            data["junction"][string(pipe["fr_junction"])]["p_max"],
            data["junction"][string(pipe["to_junction"])]["p_max"],
        )
        pipe["status"] = 1
        delete!(pipe, "pipline_i")
        delete!(pipe, "f_junction")
        delete!(pipe, "t_junction")
        delete!(pipe, "index")
    end
end

if haskey(data, "ne_compressor")
    push!(accepted_keys, "ne_compressor")
    for (i, compressor) in data["ne_compressor"]
        compressor["status"] = 1
        compressor["id"] = (get(compressor, "compressor_i", false) != false) ?
            Int(compressor["compressor_i"]) : parse(Int64, i)
        compressor["fr_junction"] = Int(compressor["f_junction"])
        compressor["to_junction"] = Int(compressor["t_junction"])
        if get(compressor, "qmin", false) == false
            compressor["qmin"] = 0.0
            compressor["qmax"] = 1e4
        end
        if compressor["qmin"] == compressor["qmax"]
            compressor["qmin"] = 0.0
        end
        if data["per_unit"] == 1
            compressor["flow_min"] = compressor["qmin"] * data["baseQ"]
            compressor["flow_max"] = compressor["qmax"] * data["baseQ"]
        else
            compressor["flow_min"] = compressor["qmin"] * data["baseQ"]
            compressor["flow_max"] = compressor["qmax"] * data["baseQ"]
        end
        compressor["inlet_p_min"] = min(
            data["junction"][string(compressor["fr_junction"])]["p_min"],
            data["junction"][string(compressor["to_junction"])]["p_min"],
        )
        compressor["inlet_p_max"] = max(
            data["junction"][string(compressor["fr_junction"])]["p_max"],
            data["junction"][string(compressor["to_junction"])]["p_max"],
        )
        compressor["outlet_p_min"] = min(
            data["junction"][string(compressor["fr_junction"])]["p_min"],
            data["junction"][string(compressor["to_junction"])]["p_min"],
        )
        compressor["outlet_p_max"] = max(
            data["junction"][string(compressor["fr_junction"])]["p_max"],
            data["junction"][string(compressor["to_junction"])]["p_max"],
        )
        compressor["operating_cost"] = 10.0
        compressor["directionality"] = 2
        delete!(compressor, "compressor_i")
        delete!(compressor, "f_junction")
        delete!(compressor, "t_junction")
        delete!(compressor, "index")
        delete!(compressor, "qmin")
        delete!(compressor, "qmax")
    end
end

push!(accepted_keys, "gas_specific_gravity")
push!(accepted_keys, "specific_heat_capacity_ratio")
push!(accepted_keys, "temperature")
push!(accepted_keys, "sound_speed")
push!(accepted_keys, "R")
push!(accepted_keys, "compressibility_factor")
push!(accepted_keys, "units")
push!(accepted_keys, "is_per_unit")
push!(accepted_keys, "is_si_units")
push!(accepted_keys, "is_english_units")
push!(accepted_keys, "economic_weighting")
push!(accepted_keys, "base_pressure")
push!(accepted_keys, "base_length")
push!(accepted_keys, "name")

if !haskey(data, "gas_specific_gravity")
    data["gas_specific_gravity"] = 0.6
end

if !haskey(data, "specific_heat_capacity_ratio")
    data["specific_heat_capacity_ratio"] = 1.4
end

if !haskey(data, "temperature")
    data["temperature"] = 288.7060
end

if !haskey(data, "R")
    data["R"] = 8.314
end

if !haskey(data, "compressibility_factor")
    data["compressibility_factor"] = 1.0
end

if !haskey(data, "economic_weighting")
    data["economic_weighting"] = 0.95
end

if !haskey(data, "sound_speed")
    molecular_mass = data["gas_molar_mass"] # kg/mol
    z = data["compressibility_factor"]
    T = data["temperature"] # K
    R = data["R"] # J/mol/K
    data["sound_speed"] = sqrt(z * R * T / molecular_mass)
end

data["base_pressure"] = data["baseP"]
data["base_length"] = 5000.0
data["base_flow"] = data["baseQ"]
data["is_per_unit"] = 0
data["is_si_units"] = 1
data["is_english_units"] = 0
data["units"] = "si"


if !haskey(data, "name")
    data["name"] = split(file, ".")[1]
end

for key in keys(data)
    if !(key in accepted_keys)
        delete!(data, key)
    end
end

write_matgas!(data, matgas_out_file; include_extended = true)
