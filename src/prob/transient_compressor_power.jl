"entry point for the transient model with compressor power objective"
function run_transient_compressor_power(file, model_type, optimizer; kwargs...)
    return run_model(file, model_type, optimizer, build_transient_compressor_power; ref_extensions=[ref_add_transient!], kwargs...)
end

""
function build_transient_compressor_power(pm::AbstractGasModel)
    
end


""
function ref_add_transient!(pm::AbstractGasModel)

end