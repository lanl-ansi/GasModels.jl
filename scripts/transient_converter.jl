
""
function convert_old_transient_format(file::String)
    old_data = open(file, "r") do f
        old_data = readlines(f)
    end

    header = old_data[1]
    column_names = split(header, ',')

    data =
        [join(["timestamp", "component_type", "component_id", "parameter", "value"], ",")]

    for row in old_data[2:end]
        _timestamp = ""
        for (name, val) in zip(column_names, split(row, ','))
            if name != "timestamp"
                val = parse(Float64, val)
                val = round(val, digits = 2)
                comp_type, comp_id, param = split(name, '.')
                push!(data, join([_timestamp, comp_type, comp_id, param, val], ","))
            else
                _timestamp = string(val)
            end
        end
    end

    open("$(match(r"(.+)\.csv", file).captures[1])_new.csv", "w") do f
        write(f, join(data, "\n"))
    end
end

if isinteractive() == false
    convert_old_transient_format(ARGS[1])
end
