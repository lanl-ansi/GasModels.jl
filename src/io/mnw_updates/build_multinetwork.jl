
function build_multinetwork(static_file::AbstractString, transient_file::AbstractString;)
    static_filetype = split(lowercase(static_file), '.')[end]

    open(static_file, "r") do static_io
        open(transient_file, "r") do transient_io
            return build_multinetwork(static_io, transient_io;)
        end
    end
end

function build_multinetwork(static_io::IO, transient_io::IO)
    static_data = parse_file(static_io) #this includes data correction
    mnw_data = parse_csv(transient_io)
    static_data["multinetwork"] = true
    return out = merge(static_data, mnw_data) #append nw dict to the static data
end