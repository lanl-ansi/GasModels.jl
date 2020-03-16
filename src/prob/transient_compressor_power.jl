"entry point for the transient model with compressor power objective"
function run_transient_compressor_power(data, model_type, optimizer; kwargs...)
    @assert InfrastructureModels.ismultinetwork(data) == true 
    return run_model(data, model_type, optimizer, build_transient_compressor_power; ref_extensions=[ref_add_transient!], multinetwork=true, kwargs...)
end

""
function build_transient_compressor_power(pm::AbstractNLPModel)
    println("in build ")
    exit()
end


""
function ref_add_transient!(pm::AbstractGasModel)
    for key in keys(pm.data)
        @show key 
    end 
    
end

