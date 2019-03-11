#########
# Set of functions whose structure is shared
#########

#TODO renamed shared_mi.jl

""
AbstractMIForms = Union{AbstractMISOCPForm, AbstractMINLPForm}

#TODO get rid of these forms
""
AbstractMIDirectedForms = Union{AbstractMISOCPDirectedForm, AbstractMINLPDirectedForm}

function constraint_compressor_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

function constraint_compressor_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIDirectedForms
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)
end

function constraint_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

function constraint_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIDirectedForms
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)
end

function constraint_control_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

function constraint_control_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIDirectedForms
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)
end

function constraint_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

function constraint_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIDirectedForms
    constraint_on_off_compressor_flow_direction(gm, i)
    constraint_on_off_compressor_ratios(gm, i)
end

function constraint_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

function constraint_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIDirectedForms
    constraint_on_off_valve_flow_direction(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)
end

function constraint_control_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

function constraint_control_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIDirectedForms
    constraint_on_off_control_valve_flow_direction(gm, i)
    constraint_on_off_control_valve_pressure_drop(gm, i)
end

function constraint_new_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_compressor_flow_direction_ne(gm, i)
    constraint_on_off_compressor_ratios_ne(gm, i)
    constraint_on_off_compressor_flow_ne(gm, i)

    constraint_flow_direction_choice_ne(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

function constraint_new_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIDirectedForms
    constraint_on_off_compressor_flow_ne(gm, i)
    constraint_on_off_compressor_flow_direction_ne(gm, i)
    constraint_on_off_compressor_ratios_ne(gm, i)
end
