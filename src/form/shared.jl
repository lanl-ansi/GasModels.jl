#########
# Set of functions whose structure is shared
#########

""
AbstractMIForms = Union{AbstractMISOCPForm, AbstractMINLPForm}

""
AbstractMIDirectedForms = Union{AbstractMISOCPDirectedForm, AbstractMINLPDirectedForm}

""
function variable_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_flux(gm,n; bounded=bounded)
    variable_connection_direction(gm,n)  
end

""
function variable_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_flux(gm,n; bounded=bounded)
end

""
function variable_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_flux_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n)  
end

""
function variable_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true)
    variable_flux_ne(gm,n; bounded=bounded)
end

function constraint_junction_flow{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_flow_balance(gm, n, i)
    
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])
    qgfirm     = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0 
    qlfirm     = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0  
    
    if qgfirm > 0.0 && qlfirm == 0.0 
        constraint_source_flow(gm, n, i)
    end      
        
    if qgfirm == 0.0 && qlfirm > 0.0 
        constraint_sink_flow(gm, n, i)
    end      
                
    if qgfirm == 0.0 && qlfirm == 0.0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)           
    end   
end

function constraint_junction_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_flow_balance(gm, n, i)
end

function constraint_junction_flow_ls{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_flow_balance_ls(gm, n, i)
    
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])
    qgfirm     = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0 
    qlfirm     = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0 
    qgmax     = length(producers) > 0 ? sum(producer["qgmax"] for (j, producer) in producers) : 0 
    qlmax     = length(consumers) > 0 ? sum(consumer["qlmax"] for (j, consumer) in consumers) : 0 
    qgmin     = length(producers) > 0 ? sum(producer["qgmin"] for (j, producer) in producers) : 0 
    qlmin     = length(consumers) > 0 ? sum(consumer["qlmin"] for (j, consumer) in consumers) : 0 
                  
    if max(qgmin,qgfirm) > 0.0  && qlmin == 0.0 && qlmax == 0.0 && qlfirm == 0.0 && qgmin >= 0.0
        constraint_source_flow(gm, n, i)
    end      
        
    if qgmax == 0.0 && qgmin == 0.0 && qgfirm == 0.0 && max(qlmin,qlfirm) > 0.0 && qlmin >= 0.0
        constraint_sink_flow(gm, n, i)
    end      
                
    if qgmax == 0 && qgmin == 0 && qgfirm == 0 && qlmax == 0 && qlmin == 0 && qlfirm == 0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)
    end         
end

function constraint_junction_flow_ls{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_flow_balance_ls(gm, n, i)
end

function constraint_junction_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_flow_balance_ne(gm, n, i)
    
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])
    qgfirm     = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0 
    qlfirm     = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0 
    
    if qgfirm > 0.0 && qlfirm == 0.0
        constraint_source_flow_ne(gm, n, i) 
    end
    if qgfirm == 0.0 && qlfirm > 0.0 
        constraint_sink_flow_ne(gm, n, i)
    end              
    if qgfirm == 0.0 && qlfirm == 0.0 && junction["degree_all"] == 2
        constraint_conserve_flow_ne(gm, n, i)
    end              
end

function constraint_junction_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_flow_balance_ne(gm, n, i)
end

function constraint_junction_flow_ne_ls{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_flow_balance_ne_ls(gm, n, i)
    
    consumers = filter( (j, consumer) -> consumer["ql_junc"] == i, gm.ref[:nw][n][:consumer])
    producers = filter( (j, producer) -> producer["qg_junc"] == i, gm.ref[:nw][n][:producer])
    qgfirm     = length(producers) > 0 ? sum(producer["qgfirm"] for (j, producer) in producers) : 0 
    qlfirm     = length(consumers) > 0 ? sum(consumer["qlfirm"] for (j, consumer) in consumers) : 0 
    qgmax     = length(producers) > 0 ? sum(producer["qgmax"] for (j, producer) in producers) : 0 
    qlmax     = length(consumers) > 0 ? sum(consumer["qlmax"] for (j, consumer) in consumers) : 0 
    qgmin     = length(producers) > 0 ? sum(producer["qgmin"] for (j, producer) in producers) : 0 
    qlmin     = length(consumers) > 0 ? sum(consumer["qlmin"] for (j, consumer) in consumers) : 0 
    
    if max(qgmin,qgfirm) > 0.0  && qlmin == 0.0 && qlmax == 0.0 && qlfirm == 0.0 && qgmin >= 0.0
        constraint_source_flow_ne(gm, i) 
    end
    if qgmax == 0.0 && qgmin == 0.0 && qgfirm == 0.0 && max(qlmin,qlfirm) > 0.0 && qlmin >= 0.0
        constraint_sink_flow_ne(gm, i)
    end              
    if qgmax == 0 && qgmin == 0 && qgfirm == 0 && qlmax == 0 && qlmin == 0 && qlfirm == 0 && junction["degree_all"] == 2
        constraint_conserve_flow_ne(gm, i)
    end                     
end

function constraint_junction_flow_ne_ls{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_flow_balance_ne_ls(gm, n, i)
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

