"Variables needed for modeling flow in MI models"
function variable_flow(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMIForms
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMIForms
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n;connection=ref(gm,n,:undirected_connection))
end

"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMIForms
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_ne_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractMIForms
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n;ne_connection=ref(gm,n,:undirected_ne_connection))
end
