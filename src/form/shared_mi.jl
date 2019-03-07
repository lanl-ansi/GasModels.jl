# This file contains implementations of functions that are shared by mi formulation

AllAbstractMIForms = Union{AbstractMISOCPForm, AbstractMINLPForm, AbstractMISOCPDirectedForm, AbstractMINLPDirectedForm} # TODO rename to AbstractMIForms


#######################################################################################################################
# Common MI Variables
#######################################################################################################################

"Variables needed for modeling flow in MI models"
function variable_flow(gm::GenericGasModel, n::Int=gm.cnw; bounded::Bool = true) where T <: AllAbstractMIForms
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AllAbstractMIForms
    variable_mass_flow(gm,n; bounded=bounded)
    variable_connection_direction(gm,n;connection=gm.ref[:nw][n][:undirected_connection])
end

"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AllAbstractMIForms
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n)
end

"Variables needed for modeling flow in MI models when some edges are directed"
function variable_flow_ne_directed(gm::GenericGasModel{T}, n::Int=gm.cnw; bounded::Bool = true) where T <: AllAbstractMIForms
    variable_mass_flow_ne(gm,n; bounded=bounded)
    variable_connection_direction_ne(gm,n;ne_connection=gm.ref[:nw][n][:undirected_ne_connection])
end

########################################################################################################
## Versions of constraints used to compute flow balance
########################################################################################################

"Constraint for computing mass flow balance at node"
function constraint_junction_mass_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
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

"Constraint for computing mass flow balance at a node when some edges are directed"
function constraint_junction_mass_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_junction_mass_flow_balance(gm, n, i)

    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end

"Constraint for computing mass flow balance at node when injections are variables"
function constraint_junction_mass_flow_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
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

"Constraint for computing mass flow balance at node when injections are variables and some edges are directed"
function constraint_junction_mass_flow_ls_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_junction_mass_flow_balance_ls(gm, n, i)

    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end

"Constraint for computing mass flow balance at node when there are expansion edges"
function constraint_junction_mass_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
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

"Constraint for computing mass flow balance at node when there are expansion edges and some edges are directed"
function constraint_junction_mass_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_junction_mass_flow_balance_ne(gm, n, i)

    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end

"Constraint for computing mass flow balance at node when there are expansion edges and variable injections"
function constraint_junction_mass_flow_ne_ls(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
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

"Constraint for computing mass flow balance at node when there are expansion edges, variable injections, and some edges are directed"
function constraint_junction_mass_flow_ne_ls_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_junction_mass_flow_balance_ne_ls(gm, n, i)

    # TODO there is an analogue of constraint_source_flow, constraint_sink_flow, and constraint_conserve_flow
end


#############################################################################################################
## Constraints for modeling flow across a pipe
############################################################################################################

"Constraints the define the pressure drop across a pipe"
function constraint_pipe_flow(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow(gm, i)
end

"Constraints the define the pressure drop across a pipe when some pipe directions are known"
function constraint_pipe_flow_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_on_off_pressure_drop_directed(gm, i)
    # TODO Here
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)
end

" constraints on pressure drop across an undirected pipe"
function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AllAbstractMIForms
    yp = gm.var[:nw][n][:yp][k]
    yn = gm.var[:nw][n][:yn][k]
    constraint_on_off_pressure_drop(gm, n, k, i, j, pd_min, pd_max, yp, yn)
end

" constraints on pressure drop across an undirected pipe"
function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max, yp, yn) where T <: AllAbstractMIForms
    pi = gm.var[:nw][n][:p][i]
    pj = gm.var[:nw][n][:p][j]

    if !haskey(gm.con[:nw][n], :on_off_pressure_drop1)
        gm.con[:nw][n][:on_off_pressure_drop1] = Dict{Int,ConstraintRef}()
        gm.con[:nw][n][:on_off_pressure_drop2] = Dict{Int,ConstraintRef}()
    end
    gm.con[:nw][n][:on_off_pressure_drop1][k] = @constraint(gm.model, (1-yp) * pd_min <= pi - pj)
    gm.con[:nw][n][:on_off_pressure_drop2][k] = @constraint(gm.model, pi - pj <= (1-yn)* pd_max)
end

" constraints on pressure drop across a directed pipe"
function constraint_on_off_pressure_drop_directed(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max, yp, yn) where T <: AllAbstractMIForms
    constraint_on_off_pressure_drop(gm, n, k, i, j, pd_min, pd_max, yp, yn)
end

" constraints for modeling flow across an undirected pipe when there are new edges "
function constraint_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_on_off_pressure_drop(gm, i)
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)

    constraint_flow_direction_choice(gm, i)
    constraint_parallel_flow_ne(gm, i)
end

" constraints for modeling flow across a directed pipe when there are new edges "
function constraint_pipe_flow_ne_directed(gm::GenericGasModel{T}, n::Int, i) where T <: AllAbstractMIForms
    constraint_on_off_pressure_drop_directed(gm, i)
    # TODO Here
    constraint_on_off_pipe_flow_direction(gm, i)
    constraint_weymouth(gm, i)
end
