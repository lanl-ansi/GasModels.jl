#########
# Set of functions whose structure is shared
#########

""
AbstractMIForms = Union{AbstractMISOCPForm, AbstractMINLPForm}

""
AbstractMIDirectedForms = Union{AbstractMISOCPDirectedForm, AbstractMINLPDirectedForm}

""
function variable_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n)  
end

""
function variable_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow(gm,n; bounded=bounded)
end

""
function variable_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n)  
end

""
function variable_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_mass_flow_ne(gm,n; bounded=bounded)
end

function constraint_junction_mass_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_mass_flow_balance(gm, n, i)

    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)
    fgfirm     = length(producers) > 0 ? sum(calc_fgfirm(gm.data, producer) for (j, producer) in producers) : 0 
    flfirm     = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer) for (j, consumer) in consumers) : 0  
    
    if fgfirm > 0.0 && flfirm == 0.0 
        constraint_source_flow(gm, n, i)
    end      
        
    if fgfirm == 0.0 && flfirm > 0.0 
        constraint_sink_flow(gm, n, i)
    end      
                
    if fgfirm == 0.0 && flfirm == 0.0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)           
    end   
end

function constraint_junction_mass_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_mass_flow_balance(gm, n, i)
end

function constraint_junction_mass_flow_ls{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_mass_flow_balance_ls(gm, n, i)

    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)
    fgfirm    = length(producers) > 0 ? sum(calc_fgfirm(gm.data, producer) for (j, producer) in producers) : 0 
    flfirm    = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer) for (j, consumer) in consumers) : 0 
    fgmax     = length(producers) > 0 ? sum(calc_fgmax(gm.data, producer) for (j, producer) in producers) : 0 
    flmax     = length(consumers) > 0 ? sum(calc_flmax(gm.data, consumer) for (j, consumer) in consumers) : 0 
    fgmin     = length(producers) > 0 ? sum(calc_fgmin(gm.data, producer) for (j, producer) in producers) : 0 
    flmin     = length(consumers) > 0 ? sum(calc_flmin(gm.data, consumer) for (j, consumer) in consumers) : 0 
                  
    if max(fgmin,fgfirm) > 0.0  && flmin == 0.0 && flmax == 0.0 && flfirm == 0.0 && fgmin >= 0.0
        constraint_source_flow(gm, n, i)
    end      
        
    if fgmax == 0.0 && fgmin == 0.0 && fgfirm == 0.0 && max(flmin,flfirm) > 0.0 && flmin >= 0.0
        constraint_sink_flow(gm, n, i)
    end      
                
    if fgmax == 0 && fgmin == 0 && fgfirm == 0 && flmax == 0 && flmin == 0 && flfirm == 0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)
    end         
end

function constraint_junction_mass_flow_ls{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_mass_flow_balance_ls(gm, n, i)
end

function constraint_junction_mass_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_mass_flow_balance_ne(gm, n, i)

    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)
    fgfirm     = length(producers) > 0 ? sum(calc_fgfirm(gm.data, producer) for (j, producer) in producers) : 0 
    flfirm     = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer) for (j, consumer) in consumers) : 0 
    
    if fgfirm > 0.0 && flfirm == 0.0
        constraint_source_flow_ne(gm, n, i) 
    end
    if fgfirm == 0.0 && flfirm > 0.0 
        constraint_sink_flow_ne(gm, n, i)
    end              
    if fgfirm == 0.0 && flfirm == 0.0 && junction["degree_all"] == 2
        constraint_conserve_flow_ne(gm, n, i)
    end              
end

function constraint_junction_mass_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_mass_flow_balance_ne(gm, n, i)
end

function constraint_junction_mass_flow_ne_ls{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
    
    consumers = Dict(x for x in gm.ref[:nw][n][:consumer] if x.second["ql_junc"] == i)
    producers = Dict(x for x in gm.ref[:nw][n][:producer] if x.second["qg_junc"] == i)
    fgfirm    = length(producers) > 0 ? sum(calc_fgfirm(gm.data, producer) for (j, producer) in producers) : 0 
    flfirm    = length(consumers) > 0 ? sum(calc_flfirm(gm.data, consumer) for (j, consumer) in consumers) : 0 
    fgmax     = length(producers) > 0 ? sum(calc_fgmax(gm.data, producer) for (j, producer) in producers) : 0 
    flmax     = length(consumers) > 0 ? sum(calc_flmax(gm.data, consumer) for (j, consumer) in consumers) : 0 
    fgmin     = length(producers) > 0 ? sum(calc_fgmin(gm.data, producer) for (j, producer) in producers) : 0 
    flmin     = length(consumers) > 0 ? sum(calc_flmin(gm.data, consumer) for (j, consumer) in consumers) : 0 
    
    if max(fgmin,fgfirm) > 0.0  && flmin == 0.0 && flmax == 0.0 && flfirm == 0.0 && fgmin >= 0.0
        constraint_source_flow_ne(gm, i) 
    end
    if fgmax == 0.0 && fgmin == 0.0 && fgfirm == 0.0 && max(flmin,flfirm) > 0.0 && flmin >= 0.0
        constraint_sink_flow_ne(gm, i)
    end              
    if fgmax == 0 && fgmin == 0 && fgfirm == 0 && flmax == 0 && flmin == 0 && flfirm == 0 && junction["degree_all"] == 2
        constraint_conserve_flow_ne(gm, i)
    end                     
end

function constraint_junction_mass_flow_ne_ls{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
end

function constraint_pipe_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)        
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

function constraint_pipe_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)        
end

function constraint_short_pipe_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_on_off_short_pipe_flow_direction(gm, i)      
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)        
end

function constraint_short_pipe_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_on_off_short_pipe_flow_direction(gm, i)      
end

function constraint_compressor_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)    
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)        
end

function constraint_compressor_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)    
end

function constraint_valve_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)  
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)          
end

function constraint_valve_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)          
end

function constraint_control_valve_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)  
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)        
end

function constraint_control_valve_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)          
end

function constraint_pipe_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)        
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

function constraint_pipe_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)        
end

function constraint_short_pipe_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_on_off_short_pipe_flow_direction(gm, i)      
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)        
end

function constraint_short_pipe_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_on_off_short_pipe_flow_direction(gm, i)      
end

function constraint_compressor_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)    
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)        
end

function constraint_compressor_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)    
end

function constraint_valve_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)  
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)          
end

function constraint_valve_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)          
end

function constraint_control_valve_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)  
        
    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)        
end

function constraint_control_valve_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)          
end

function constraint_new_pipe_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_pressure_drop_ne(gm, i) 
    constraint_on_off_pipe_flow_direction_ne(gm, i) 
    constraint_on_off_pipe_flow_ne(gm, i) 
    constraint_weymouth_ne(gm, i) 
        
    constraint_flow_direction_choice_ne(gm, i) 
    constraint_parallel_flow_ne(gm, i)    
end

function constraint_new_pipe_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_pressure_drop_ne(gm, i) 
    constraint_on_off_pipe_flow_direction_ne(gm, i) 
    constraint_on_off_pipe_flow_ne(gm, i) 
    constraint_weymouth_ne(gm, i) 
end

function constraint_new_compressor_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_compressor_flow_direction_ne(gm, i) 
    constraint_on_off_compressor_ratios_ne(gm, i) 
    constraint_on_off_compressor_flow_ne(gm, i)
            
    constraint_flow_direction_choice_ne(gm, i) 
    constraint_parallel_flow_ne(gm, i)  
end

function constraint_new_compressor_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_compressor_flow_ne(gm, i)  
    constraint_on_off_compressor_flow_direction_ne(gm, i) 
    constraint_on_off_compressor_ratios_ne(gm, i) 
end

