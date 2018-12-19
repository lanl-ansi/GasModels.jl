
# Generic function for parsing a file based on an extension
function parse_file(file)
  if endswith(file, ".m")
    gm_data = GasModels.parse_matlab(file)
  else
    gm_data = GasModels.parse_json(file)
  end 
  check_network_data(gm_data)
  
  return gm_data  
end

""
function check_network_data(data::Dict{String,Any})
    make_per_unit(data)
end