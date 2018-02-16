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
      
    if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0 
        constraint_source_flow(gm, n, i)
    end      
        
    if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
        constraint_sink_flow(gm, n, i)
    end      
                
    if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)           
    end   
end

function constraint_junction_flow{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_flow_balance(gm, n, i)
end

function constraint_junction_flow_ls{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_flow_balance_ls(gm, n, i)
      
    if max(junction["qgmin"],junction["qgfirm"]) > 0.0  && junction["qlmin"] == 0.0 && junction["qlmax"] == 0.0 && junction["qlfirm"] == 0.0 && junction["qgmin"] >= 0.0
        constraint_source_flow(gm, n, i)
    end      
        
    if junction["qgmax"] == 0.0 && junction["qgmin"] == 0.0 && junction["qgfirm"] == 0.0 && max(junction["qlmin"],junction["qlfirm"]) > 0.0 && junction["qlmin"] >= 0.0
        constraint_sink_flow(gm, n, i)
    end      
                
    if junction["qgmax"] == 0 && junction["qgmin"] == 0 && junction["qgfirm"] == 0 && junction["qlmax"] == 0 && junction["qlmin"] == 0 && junction["qlfirm"] == 0 && junction["degree"] == 2
        constraint_conserve_flow(gm, n, i)
    end         
end

function constraint_junction_flow_ls{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_flow_balance_ls(gm, n, i)
end

function constraint_junction_flow_ne{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_flow_balance_ne(gm, n, i)
    if junction["qgfirm"] > 0.0 && junction["qlfirm"] == 0.0
        constraint_source_flow_ne(gm, n, i) 
    end
    if junction["qgfirm"] == 0.0 && junction["qlfirm"] > 0.0 
        constraint_sink_flow_ne(gm, n, i)
    end              
    if junction["qgfirm"] == 0.0 && junction["qlfirm"] == 0.0 && junction["degree_all"] == 2
        constraint_conserve_flow_ne(gm, n, i)
    end              
end

function constraint_junction_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_junction_flow_balance_ne(gm, n, i)
end

function constraint_junction_flow_ne_ls{T <: AbstractMIForms}(gm::GenericGasModel{T}, n::Int, i)
    junction = ref(gm,n,:junction,i)  
    constraint_junction_flow_balance_ne_ls(gm, n, i)
    if max(junction["qgmin"],junction["qgfirm"]) > 0.0  && junction["qlmin"] == 0.0 && junction["qlmax"] == 0.0 && junction["qlfirm"] == 0.0 && junction["qgmin"] >= 0.0
        constraint_source_flow_ne(gm, i) 
    end
    if junction["qgmax"] == 0.0 && junction["qgmin"] == 0.0 && junction["qgfirm"] == 0.0 && max(junction["qlmin"],junction["qlfirm"]) > 0.0 && junction["qlmin"] >= 0.0
        constraint_sink_flow_ne(gm, i)
    end              
    if junction["qgmax"] == 0 && junction["qgmin"] == 0 && junction["qgfirm"] == 0 && junction["qlmax"] == 0 && junction["qlmin"] == 0 && junction["qlfirm"] == 0 && junction["degree_all"] == 2
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
        
    constraint_flow_direction_choice_ne(gm, i) 
    constraint_parallel_flow_ne(gm, i)  
end

function constraint_new_compressor_flow_ne{T <: AbstractMIDirectedForms}(gm::GenericGasModel{T}, n::Int, i)
    constraint_on_off_compressor_flow_direction_ne(gm, i) 
    constraint_on_off_compressor_ratios_ne(gm, i) 
end

