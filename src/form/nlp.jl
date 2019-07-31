# This file contains implementations of functions for the nlp formulation

export
    NLPGasModel, StandardNLPForm

""
abstract type AbstractNLPForm <: AbstractGasFormulation end

""
abstract type StandardNLPForm <: AbstractNLPForm end

const NLPGasModel = GenericGasModel{StandardNLPForm} # the standard NLP model

"default NLP constructor"
NLPGasModel(data::Dict{String,Any}; kwargs...) = GenericGasModel(data, StandardNLPForm)

#######################################################################################################################
# Variables
#######################################################################################################################

"Variables needed for modeling flow in NLP models"
function variable_flow(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractNLPForm
    variable_mass_flow(gm,n; bounded=bounded)
end

"Variables needed for modeling flow in NLP models when some edges are directed"
function variable_flow_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractNLPorm
    variable_mass_flow(gm,n; bounded=bounded)
end

"Variables needed for modeling flow in NLP models"
function variable_flow_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractNLPForm
    variable_mass_flow_ne(gm,n; bounded=bounded)
end

"Variables needed for modeling flow in NLP models when some edges are directed"
function variable_flow_ne_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AbstractNLPForm
    variable_mass_flow_ne(gm,n; bounded=bounded)
end

########################################################################################################
## Versions of constraints used to compute flow balance
########################################################################################################

"Constraint for computing mass flow balance at node"
function constraint_junction_mass_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance(gm, n, i)
end

"Constraint for computing mass flow balance at a node when some edges are directed"
function constraint_junction_mass_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance(gm, n, i)
end

"Constraint for computing mass flow balance at node when injections are variables"
function constraint_junction_mass_flow_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance_ls(gm, n, i)
end

"Constraint for computing mass flow balance at node when injections are variables and some edges are directed"
function constraint_junction_mass_flow_ls_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance_ls(gm, n, i)
end

"Constraint for computing mass flow balance at node when there are expansion edges"
function constraint_junction_mass_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance_ne(gm, n, i)
end

"Constraint for computing mass flow balance at node when there are expansion edges and some edges are directed"
function constraint_junction_mass_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance_ne(gm, n, i)
end

"Constraint for computing mass flow balance at node when there are expansion edges and variable injections"
function constraint_junction_mass_flow_ne_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
end

"Constraint for computing mass flow balance at node when there are expansion edges, variable injections, and some edges are directed"
function constraint_junction_mass_flow_ne_ls_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)
end

#############################################################################################################
## Constraints for modeling flow across a pipe
############################################################################################################

"Constraints the define the pressure drop across a pipe"
function constraint_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_weymouth(gm, i)
end

"Constraints the define the pressure drop across a pipe when some pipe directions are known"
function constraint_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_pressure_drop_one_way(gm, i)
    constraint_pipe_flow_one_way(gm, i)
    constraint_weymouth_one_way(gm, i)
end

" constraints for modeling flow across an undirected pipe when there are new edges "
function constraint_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_weymouth(gm, i)
end

"Weymouth equation with absolute value "
function constraint_weymouth(gm::GenericGasModel{T}, n::Int, k, i, j, mf, w, pd_min, pd_max) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

    add_constraint(gm, n, :weymouth1, k, @NLconstraint(gm.model, w*(pi - pj) == f * abs(f)))
end

"Weymouth equation with one way direction"
function constraint_weymouth_one_way(gm::GenericGasModel{T}, n::Int, k, i, j, w, yp, yn) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f  = var(gm,n,:f,k)

    add_constraint(gm, n, :weymouth1, k, @NLconstraint(gm.model, w*(pi - pj) >= (yp-yn) * f^2))
    add_constraint(gm, n, :weymouth2, k, @NLconstraint(gm.model, w*(pi - pj) <= (yp-yn) * f^2))
end

#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################

"Constraints for an expansion pipe with undirected flow"
function constraint_new_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_on_off_pipe_ne(gm, i)
    constraint_weymouth_ne(gm, i)
end

"Constraints for an expansion pipe with undirected flow"
function constraint_new_pipe_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_pressure_drop_ne_one_way(gm, i)
    constraint_pipe_flow_ne_one_way(gm, i)
    constraint_on_off_pipe_ne(gm, i)
    constraint_weymouth_ne_one_way(gm, i)
end

"Weymouth equation for directed expansion pipes"
function constraint_weymouth_ne_one_way(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, yp, yn) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

    if yp == 1
        add_constraint(gm, n, :weymouth_ne1, k, @NLconstraint(gm.model, w*(pi - pj) >= f^2 - zp*mf^2))
        add_constraint(gm, n, :weymouth_ne2, k, @NLconstraint(gm.model, w*(pi - pj) <= f^2 + zp*mf^2))
    else
        add_constraint(gm, n, :weymouth_ne3, k, @NLconstraint(gm.model, w*(pj - pi) >= f^2 - zp*mf^2))
        add_constraint(gm, n, :weymouth_ne4, k, @NLconstraint(gm.model, w*(pj - pi) <= f^2 + zp*mf^2))
    end
end

" Weymouth equation for an undirected expansion pipe "
function constraint_weymouth_ne(gm::GenericGasModel{T},  n::Int, k, i, j, w, mf, pd_min, pd_max) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zp = var(gm,n,:zp,k)
    f  = var(gm,n,:f_ne,k)

    add_constraint(gm, n, :weymouth_ne1, k, @NLconstraint(gm.model, w*(pi - pj) >= f * abs(f) - (1-zp)*mf^2))
    add_constraint(gm, n, :weymouth_ne2, k, @NLconstraint(gm.model, w*(pi - pj) <= f * abs(f) + (1-zp)*mf^2))
end

###########################################################################################
### Short pipe constraints
###########################################################################################

" Constraints for modeling flow on an undirected short pipe"
function constraint_short_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_short_pipe_pressure_drop(gm, i)
end

" Constraints for modeling flow on a directed short pipe"
function constraint_short_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_short_pipe_pressure_drop(gm, i)
    constraint_short_pipe_flow_one_way(gm, i)
end

#" Constraints for modeling flow on an undirected short pipe for expansion planning models"
#function constraint_short_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
#    constraint_short_pipe_pressure_drop(gm, i)
#end

######################################################################################
# Constraints associated with flow through a compressor
######################################################################################

"Constraints on flow through a compressor where the compressor is undirected"
function constraint_compressor_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_compressor_ratios(gm, i)
end

"Constraints on flow through a compressor where the compressor is directed"
function constraint_compressor_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_compressor_flow_one_way(gm, i)
    constraint_compressor_ratios_one_way(gm, i)
end

"Constraints through a new compressor that is undirected"
function constraint_new_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_compressor_ratios_ne(gm, i)
    constraint_on_off_compressor_ne(gm, i)
end

"Constraints through a new compressor that is directed"
function constraint_new_compressor_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_on_off_compressor_ne(gm, i)
    constraint_compressor_flow_ne_one_way(gm, i)
    constraint_compressor_ratios_ne_one_way(gm, i)
end

#"Constraints through a compressor that is undirected in an expansion model"
#function constraint_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
#    constraint_compressor_ratios(gm, i)
#end

#"Constraints through a compressor that is directed in an expansion model"
#function constraint_compressor_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
#    constraint_compressor_flow_one_way(gm, i)
#    constraint_compressor_ratios_one_way(gm, i)
#end

" enforces pressure changes bounds that obey compression ratios for an undirected compressor "
function constraint_compressor_ratios(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractNLPForm
    compressor     = ref(gm,n,:connection,k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]

    constraint_compressor_ratios(gm, n, k, i, j, min_ratio, max_ratio)
end
constraint_compressor_ratios(gm::GenericGasModel, k::Int) = constraint_compressor_ratios(gm, gm.cnw, k)

" enforces pressure changes bounds that obey compression ratios for an undirected compressor. "
function constraint_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio) where T <: AbstractNLPForm
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    f = var(gm,n,:yn,f)

    #TODO this constraint is only valid if min_ratio = 1
    add_constraint(gm, n, :on_off_compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= 0))
    add_constraint(gm, n, :on_off_compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= 0))
    add_constraint(gm, n, :on_off_compressor_ratios3, k, @constraint(gm.model, f * (1-pj/pi) <= 0))
end

" constraints on pressure drop across an undirected compressor "
function constraint_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractNLPForm
    compressor = ref(gm,n,:ne_connection, k)
    i              = compressor["f_junction"]
    j              = compressor["t_junction"]
    max_ratio      = compressor["c_ratio_max"]
    min_ratio      = compressor["c_ratio_min"]
    j_pmax         = ref(gm,n,:junction,j)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmax"]
    i_pmax         = ref(gm,n,:junction,i)["pmin"]
    mf       = ref(gm,n,:max_mass_flow)

    constraint_compressor_ratios_ne(gm, n, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax)
end
constraint_compressor_ratios_ne(gm::GenericGasModel, k::Int) = constraint_compressor_ratios_ne(gm, gm.cnw, k)

" constraints on pressure drop across a compressor "
function constraint_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, mf, j_pmax, i_pmin, i_pmax) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)

    #TODO this constraint is only valid if min_ratio = 1
    add_constraint(gm, n, :on_off_compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-zc)*j_pmax^2))
    add_constraint(gm, n, :on_off_compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-zc)*(min_ratio*i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios3, k, @constraint(gm.model, f * (1-pj/pi) <= (1-zc) * mf * (1-j_pmax^2/i_pmin^2)))
end

######################################################################################
## Constraints associated with valves
######################################################################################

" constraints on a valve that is undirected"
function constraint_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_on_off_valve_flow(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)
end

" constraints on a valve that is directed"
function constraint_valve_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_valve_flow_one_way(gm, i)
    constraint_on_off_valve_pressure_drop(gm, i)
end

#" constraints on flow across an undirected valve in an expansion planning model"
#function constraint_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
#    constraint_on_off_valve_flow(gm, i)
#    constraint_valve_pressure_drop(gm, i)
#end

#" constraints on flow across a directed valve in an expansion planning model"
#function constraint_valve_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
#    constraint_on_off_valve_flow_one_way(gm, i)
#    constraint_on_off_valve_pressure_drop(gm, i)
#end

" constraints on flow across undirected valves "
function constraint_on_off_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractNLPForm
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n,:on_off_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end

##########################################################################################################
# Constraints on control valves
##########################################################################################################

" constraints on flow an undirected control valve"
function constraint_control_valve_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
    constraint_on_off_control_valve_flow(gm, i)
    constraint_control_valve_pressure_drop(gm, i)
end

" constraints on flow an directed control valve"
function constraint_control_valve_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    constraint_on_off_control_valve_flow_one_way(gm, i)
    constraint_control_valve_pressure_drop_one_way(gm, i)
end

#"constraints on undirected control value flows for expansion planning"
#function constraint_control_valve_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
#    constraint_on_off_control_valve_flow(gm, i)
#    constraint_control_valve_pressure_drop(gm, i)
#end

#"constraints on directed control value flows for expansion planning"
#function constraint_control_valve_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractNLPForm
#    constraint_control_valve_flow_one_way(gm, i)
#    constraint_control_valve_pressure_drop_one_way(gm, i)
#end

" constraints on flow across control valves that are undirected "
function constraint_on_off_control_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractNLPForm
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n,:on_off_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end

" enforces pressure changes bounds that obey decompression ratios for an undirected control valve "
function constraint_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractNLPForm
    control_valve     = ref(gm,n,:control_valve,k)
    i              = control_valve["f_junction"]
    j              = control_valve["t_junction"]
    max_ratio      = control_valve["c_ratio_max"]
    min_ratio      = control_valve["c_ratio_min"]

    constraint_control_valve_pressure_drop(gm, n, k, i, j, min_ratio, max_ratio)
end
constraint_control_valve_pressure_drop(gm::GenericGasModel, k::Int) = constraint_control_valve_pressure_drop(gm, gm.cnw, k)

" constraints on pressure drop across control valves that are undirected "
function constraint_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractNLPForm
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v = var(gm,n,:v,k)

    #TODO this constraint is only valid if max_ratio = 1
    add_constraint(gm, n, :control_valve_pressure_drop1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-v)*j_pmax^2))
    add_constraint(gm, n, :control_valve_pressure_drop2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-v)*(min_ratio*i_pmax^2)))
    add_constraint(gm, n, :control_valve_pressure_drop3, k, @constraint(gm.model, f * (1-pj/pi) >= (1-zc) * mf * (1-j_pmax^2/i_pmin^2)))
end
