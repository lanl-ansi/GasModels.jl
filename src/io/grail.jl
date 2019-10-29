"""
Loads a Grail json document and converts it into the GasModels data structure
"""
function parse_grail(network_file::AbstractString, time_series_file::AbstractString; time_point = 1, slack_producers = false)
    network_data = open(network_file, "r") do io
        JSON.parse(io)
    end

    profile_data = open(time_series_file, "r") do io
        JSON.parse(io)
    end

    @assert length(profile_data["time_points"]) >= time_point

    g_nodes = Dict([(node["index"], node) for node in network_data["node"]])
    g_edges = Dict([(edge["index"], edge) for edge in network_data["edge"]])
    g_compressors = Dict([(compressor["index"], compressor) for compressor in network_data["compressor"]])

    g_node_withdrawal = Dict{Int,Any}()
    for (i, withdrawal) in enumerate(profile_data["withdrawal"])
        # based on connectivity, this appears to be node index keys (not node id keys)
        junction_id = withdrawal["node_index"]
        withdrawal_value = withdrawal["withdrawal"][time_point]

        # FOLLOW UP: make sure this is the correct interpretation of multiple withdrawal
        if withdrawal_value != 0.0
            if !haskey(g_node_withdrawal, junction_id)
                g_node_withdrawal[junction_id] = [withdrawal_value]
            else
                push!(g_node_withdrawal[junction_id], withdrawal_value)
            end
        end
    end

    gm_junctions = Dict{String,Any}()
    gm_producers = Dict{String,Any}()
    gm_consumers = Dict{String,Any}()

    producer_count = 1
    consumer_count = 1

    node_id_to_junction_id = Dict{Int,Int}()
    for (i, node) in g_nodes
        node_id_to_junction_id[node["index"]] = node["node"]

        junction_id = node["node"]

        gm_junction = Dict{String,Any}(
            "index" => junction_id,
            "pmax" => node["pmax"],
            "pmin" =>  node["pmin"],
            "latitude" => node["lat"],
            "longitude" => node["lon"],
            # other stuff from grail data format
            #"qmax" => node["qmax"],
            #"qmin" => node["qmin"],
            "isslack" => node["isslack"]
        )

        junction_index = "$(gm_junction["index"])"
        @assert !haskey(gm_junctions, junction_index)
        gm_junctions[junction_index] = gm_junction

        if haskey(g_node_withdrawal, node["index"])
            for withdrawal in g_node_withdrawal[node["index"]]
                if withdrawal > 0
                    #=
                    gm_consumer = Dict{String,Any}(
                        "index" => consumer_count,
                        "ql_junc" => junction_id,
                        "qlmax" => 0.0,
                        "qlmin" => 0.0,
                        "ql" => withdrawal
                    )
                    =#

                    gm_consumer = Dict{String,Any}(
                        "index" => consumer_count,
                        "ql_junc" => junction_id,
                        "qlmax" => withdrawal,
                        "qlmin" => 0.0,
                        "ql" => 0.0
                    )


                    consumer_index = "$(gm_consumer["index"])"
                    @assert !haskey(gm_consumers, consumer_index)
                    gm_consumers[consumer_index] = gm_consumer
                    consumer_count += 1
                else
                    #=
                    gm_producer = Dict{String,Any}(
                        "index" => producer_count,
                        "qg_junc" => junction_id,
                        "qgmax" => 0.0,
                        "qgmin" => 0.0,
                        "qg" => -withdrawal
                    )
                    =#

                    gm_producer = Dict{String,Any}(
                        "index" => producer_count,
                        "qg_junc" => junction_id,
                        "qgmax" => -withdrawal,
                        "qgmin" => 0.0,
                        "qg" => 0.0
                    )

                    producer_index = "$(gm_producer["index"])"
                    @assert !haskey(gm_producers, producer_index)
                    gm_producers[producer_index] = gm_producer
                    producer_count += 1
                end
            end
        end

        if node["isslack"] != 0 && slack_producers
            Memento.warn(_LOGGER,"adding producer at junction $(junction_id) to model slack capacity")

            gm_producer = Dict{String,Any}(
                "index" => producer_count,
                "qg_junc" => junction_id,
                "qgmax" => node["qmax"],
                "qgmin" => node["qmin"],
                "qg" => 0.0
            )

            producer_index = "$(gm_producer["index"])"
            @assert !haskey(gm_producers, producer_index)
            gm_producers[producer_index] = gm_producer
            producer_count += 1
        end

    end

    #println(length(gm_junctions))
    #println(length(gm_producers))
    #println(length(gm_consumers))

    gm_connections = Dict{String,Any}()
    for (i, edge) in g_edges
        @assert edge["fr_node"] == node_id_to_junction_id[edge["f_id"]]
        @assert edge["to_node"] == node_id_to_junction_id[edge["t_id"]]

        # assume diameter units in inches, convert to meters
        # assume length units is in degrees, convert to meters
        a = 343.0 # speed of sound constant
        #a = 1.0

        length = max(edge["length"], 0.1) # to be robust to zero values
        c = 96.074830e-15            # Gas relative constant
        L = length*54.0*1.6  # length of the pipe [km]
        D = edge["diameter"]*25.4    # interior diameter of the pipe [mm]
        T = 281.15                   # gas temperature [K]
        epsilon = 0.05               # absolute rugosity of pipe [mm]
        delta = 0.6106               # density of the gas relative to air [-]
        z = 0.8                      # gas compressibility factor [-]
        B = 3.6*D/epsilon
        lambda = 1/((2*log10(B))^2)
        resistance = c*(D^5/(lambda*z*T*L*delta));

        resistance = max(resistance, 0.01) # to have numerical robustness

        gm_connection = Dict{String,Any}(
            "index" => edge["index"],
            "f_junction" => edge["fr_node"],
            "t_junction" =>  edge["to_node"],
            "length" => L,
            "diameter" => D,
            "friction_factor" => edge["friction_factor"],
            "resistance" => resistance,
            "type" => "pipe"
        )

        if gm_connection["friction_factor"] == 0.0
            gm_connection["type"] = "short_pipe"
        end

        connection_index = "$(gm_connection["index"])"
        @assert !haskey(gm_connections, connection_index)
        gm_connections[connection_index] = gm_connection
    end

    #println(length(gm_connections))


    max_junction_id = maximum([junction["index"] for (i,junction) in gm_junctions])
    junction_id_offset = trunc(Int, 10^ceil(log10(max_junction_id)))
    #println(max_junction_id)
    #println(junction_id_offset)

    compressor_offset = maximum(connection["index"] for (i,connection) in gm_connections)
    compressor_count = 1
    for (i, compressor) in g_compressors
        @assert compressor["node"] == node_id_to_junction_id[compressor["node_id"]]

        # prepare a new junction for the pipe-connecting compressor
        fr_junction = gm_junctions["$(compressor["node"])"]
        to_junction_index = junction_id_offset + fr_junction["index"]

        Memento.warn(_LOGGER,"adding junction $(to_junction_index) to capture both sides of a compressor")

        gm_junction = Dict{String,Any}(
            "index" => to_junction_index,
            "pmax" => fr_junction["pmax"],
            "pmin" =>  fr_junction["pmin"],
            "latitude" => fr_junction["latitude"],
            "longitude" => fr_junction["longitude"],
        )

        junction_index = "$(gm_junction["index"])"
        @assert !haskey(gm_junctions, junction_index)
        gm_junctions[junction_index] = gm_junction

        # update pipe to point to new junction
        pipe = gm_connections["$(compressor["edge_id"])"]
        @assert pipe["type"] == "pipe"
        @assert pipe["t_junction"] == compressor["node"] || pipe["f_junction"] == compressor["node"]

        # FOLLOW UP: this could be an indication of a compressor orientation issue
        if pipe["f_junction"] == compressor["node"]
            pipe["f_junction"] = to_junction_index
        else
            pipe["t_junction"] = to_junction_index
        end

        compressor_index = compressor_offset + compressor_count
        gm_connection = Dict{String,Any}(
            "index" => compressor_index,
            "f_junction" => compressor["node"],
            "t_junction" => to_junction_index,
            "c_ratio_max" => compressor["cmax"],
            "c_ratio_min" => compressor["cmin"],
            "type" => "compressor",
            # other stuff from grail data format
            "hpmax" => compressor["hpmax"]
        )

        @assert compressor["cmin"] >= 1.0

        connection_index = "$(gm_connection["index"])"
        @assert !haskey(gm_connections, connection_index)
        gm_connections[connection_index] = gm_connection

        compressor_count += 1
    end

    gm_network = Dict{String,Any}(
        "name" => split(network_file,'.')[1],
        "multinetwork" => false,
        "junction" => gm_junctions,
        "producer" => gm_producers,
        "consumer" => gm_consumers,
        "connection" => gm_connections
    )

    #println("total production = $(sum([producer["qg"] for (i,producer) in gm_producers]))")
    #println("total consumption = $(sum([consumer["qlfirm"] for (i,consumer) in gm_consumers]))")

    return gm_network
end
