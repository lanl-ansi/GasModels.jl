########################################################################################################
## Versions of constraints used to compute flow balance
########################################################################################################

##############################################################################################################
# Constraints that don't need a template
#############################################################################################################

"Constraint: Constraints which state a flow direction must be chosen "
constraint_flow_direction_choice(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice(gm, gm.cnw, i)

"Constraint: Constraint that states a flow direction must be chosen for expansion connections "
constraint_flow_direction_choice_ne(gm::GenericGasModel, i::Int) = constraint_flow_direction_choice_ne(gm, gm.cnw, i)

#############################################################################################################
## Constraints for modeling flow across a pipe
############################################################################################################


"Constraint: Constraints which define pressure drop across a pipe when there are on/off direction variables"
function constraint_on_off_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop1, k, @constraint(gm.model, (1-yp) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop2, k, @constraint(gm.model, pi - pj <= (1-yn)* pd_max))
end

"Constraint: Constraint on flow across a pipe when there are on/off direction variables "
function constraint_on_off_pipe_mass_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_pipe_flow1, k, @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(pd_max, abs(pd_min)))) <= f))
    add_constraint(gm, n, :on_off_pipe_flow2, k, @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(pd_max, abs(pd_min))))))
end

#############################################################################################################
## Constraints for modeling flow across a new pipe
############################################################################################################


"Constraint: constraints on pressure drop across an expansion pipe with on/off direction variables"
function constraint_on_off_pressure_drop_ne(gm::GenericGasModel{T}, n::Int, k, i, j, pd_min, pd_max) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_pressure_drop_ne1, k, @constraint(gm.model, (1-yp) * pd_min <= pi - pj))
    add_constraint(gm, n, :on_off_pressure_drop_ne2, k, @constraint(gm.model, pi - pj <= (1-yn)* pd_max))
end

"Constraint: constraints on flow across an expansion pipe with on/off direction variables "
function constraint_on_off_pipe_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, mf, pd_min, pd_max, w) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)
    f  = var(gm,n,:f_ne,k)
    add_constraint(gm, n, :on_off_pipe_flow_ne1, k, @constraint(gm.model, -(1-yp)*min(mf, sqrt(w*max(abs(pd_max), abs(pd_min)))) <= f))
    add_constraint(gm, n, :on_off_pipe_flow_ne2, k, @constraint(gm.model, f <= (1-yn)*min(mf, sqrt(w*max(abs(pd_max), abs(pd_min))))))
end

###########################################################################################
### Short pipe constriants
###########################################################################################



"Constraint: Constraints on flow across a short pipe with on/off direction variables"
function constraint_on_off_short_pipe_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_short_pipe_flow1, k, @constraint(gm.model, -mf*(1-yp) <= f))
    add_constraint(gm, n, :on_off_short_pipe_flow2, k, @constraint(gm.model, f <= mf*(1-yn)))
end

"Constraint: constraints on flow across a short pipe with on/off direction variables"
function constraint_on_off_short_pipe_flow(gm::GenericGasModel{T}, n::Int, k) where T <: AbstractMIForms
    pipe = ref(gm,n,:connection,k)
    i    = pipe["f_junction"]
    j    = pipe["t_junction"]
    mf   = ref(gm,n,:max_mass_flow)
    constraint_on_off_short_pipe_flow(gm, n, k, i, j, mf)
end
constraint_on_off_short_pipe_flow(gm::GenericGasModel, k::Int) = constraint_on_off_short_pipe_flow(gm, gm.cnw, k)

######################################################################################
# Constraints associated with flow through a compressor
######################################################################################



"Constraint: constraints on flow across a compressor with on/off direction variables "
function constraint_on_off_compressor_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    f  = var(gm,n,:f,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction1, k, @constraint(gm.model, -(1-yp)*mf <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction2, k, @constraint(gm.model, f <= (1-yn)*mf))
end

"Constraint: enforces pressure changes bounds that obey compression ratios for a compressor with on/off direction variables"
function constraint_on_off_compressor_ratios(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, j_pmin, i_pmax, i_pmin) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    add_constraint(gm, n, :on_off_compressor_ratios1, k, @constraint(gm.model, pj - max_ratio^2*pi <= (1-yp)*(j_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios2, k, @constraint(gm.model, min_ratio^2*pi - pj <= (1-yp)*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios3, k, @constraint(gm.model, pi - pj <= (1-yn)*(i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios4, k, @constraint(gm.model, pj - pi <= (1-yn)*(j_pmax^2)))
end

"Constraint: constraints on flow across compressors with on/off direction variables"
function constraint_on_off_compressor_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)
    f  = var(gm,n,:f_ne,k)
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne1, k, @constraint(gm.model, -(1-yp)*mf <= f))
    add_constraint(gm, n, :on_off_compressor_flow_direction_ne2, k, @constraint(gm.model, f <= (1-yn)*mf))
end

"Constraint: constraints on pressure drop across expansion compressors with on/off decision variables "
function constraint_on_off_compressor_ratios_ne(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, j_pmax, i_pmax) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,k)
    yn = var(gm,n,:yn_ne,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    zc = var(gm,n,:zc,k)

    # TODO these are modeled as
    add_constraint(gm, n, :on_off_compressor_ratios_ne1, k, @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-yp-zc)*j_pmax^2))
    add_constraint(gm, n, :on_off_compressor_ratios_ne2, k, @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-yp-zc)*(min_ratio^2*i_pmax^2)))
    add_constraint(gm, n, :on_off_compressor_ratios_ne3, k, @constraint(gm.model,  pi - (max_ratio^2*pj) <= (2-yn-zc)*i_pmax^2))
    add_constraint(gm, n, :on_off_compressor_ratios_ne4, k, @constraint(gm.model,  (min_ratio^2*pj) - pi <= (2-yn-zc)*(min_ratio^2*j_pmax^2)))

end



"Constraint: Constraints on flow across valves with on/off direction variables "
function constraint_on_off_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n,:on_off_valve_flow_direction1, k, @constraint(gm.model, -mf*(1-yp) <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction2, k, @constraint(gm.model, f <= mf*(1-yn)))
    add_constraint(gm, n,:on_off_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f))
    add_constraint(gm, n,:on_off_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end

#######################################################
# Flow Constraints for control valves
#######################################################



"Constraint: Constraints on flow across control valves with on/off direction variables "
function constraint_on_off_control_valve_flow(gm::GenericGasModel{T}, n::Int, k, i, j, mf) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    f = var(gm,n,:f,k)
    v = var(gm,n,:v,k)
    add_constraint(gm, n, :on_off_control_valve_flow_direction1, k, @constraint(gm.model, -mf*(1-yp) <= f))
    add_constraint(gm, n, :on_off_control_valve_flow_direction2, k, @constraint(gm.model, f <= mf*(1-yn)))
    add_constraint(gm, n, :on_off_control_valve_flow_direction3, k, @constraint(gm.model, -mf*v <= f ))
    add_constraint(gm, n, :on_off_control_valve_flow_direction4, k, @constraint(gm.model, f <= mf*v))
end

"Constraint: Constraints on pressure drop across control valves that have on/off direction variables "
function constraint_on_off_control_valve_pressure_drop(gm::GenericGasModel{T}, n::Int, k, i, j, min_ratio, max_ratio, i_pmax, j_pmax) where T <: AbstractMIForms
    yp = var(gm,n,:yp,k)
    yn = var(gm,n,:yn,k)
    pi = var(gm,n,:p,i)
    pj = var(gm,n,:p,j)
    v  = var(gm,n,:v,k)
    add_constraint(gm, n, :on_off_control_valve_pressure_drop1, k, @constraint(gm.model,  pj - (max_ratio^2*pi) <= (2-yp-v)*j_pmax^2))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop2, k, @constraint(gm.model,  (min_ratio^2*pi) - pj <= (2-yp-v)*(i_pmax^2) ))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop3, k, @constraint(gm.model,  pj - pi <= (2-yn-v)*j_pmax^2))
    add_constraint(gm, n, :on_off_control_valve_pressure_drop4, k, @constraint(gm.model,  pi - pj <= (2-yn-v)*(i_pmax^2)))
end

######################################################################
# Constraints used for generating cuts on direction variables
#########################################################################

"Constraint: Choose one direction"
function constraint_flow_direction_choice(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    yp = var(gm,n,:yp,i)
    yn = var(gm,n,:yn,i)
    add_constraint(gm, n, :flow_direction_choice, i,  @constraint(gm.model, yp + yn == 1))
end

"Constraint: Choose one direction on expansion edges"
function constraint_flow_direction_choice_ne(gm::GenericGasModel{T}, n::Int, i) where T <: AbstractMIForms
    yp = var(gm,n,:yp_ne,i)
    yn = var(gm,n,:yn_ne,i)
    add_constraint(gm, n, :flow_direction_choice_ne, i,  @constraint(gm.model, yp + yn == 1))
end

"Constraint: Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    add_constraint(gm, n, :source_flow, i,  @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) "
function constraint_source_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIForms
    yp    = var(gm,n,:yp)
    yn    = var(gm,n,:yn)
    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)
    add_constraint(gm, n, :source_flow_ne, i, @constraint(gm.model, sum(yp[a] for a in f_branches) + sum(yn[a] for a in t_branches) + sum(yp_ne[a] for a in f_branches_ne) + sum(yn_ne[a] for a in t_branches_ne) >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    add_constraint(gm, n, :sink_flow, i, @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) >= 1))
end

"Constraint: Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) "
function constraint_sink_flow_ne(gm::GenericGasModel{T}, n::Int, i, f_branches, t_branches, f_branches_ne, t_branches_ne) where T <: AbstractMIForms
    yp    = var(gm,n,:yp)
    yn    = var(gm,n,:yn)
    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)
    add_constraint(gm, n, :sink_flow_ne, i, @constraint(gm.model, sum(yn[a] for a in f_branches) + sum(yp[a] for a in t_branches) + sum(yn_ne[a] for a in f_branches_ne) + sum(yp_ne[a] for a in t_branches_ne) >= 1))
end

"Constraint: This constraint is intended to ensure that flow is one direction through a node with degree 2 and no production or consumption "
function constraint_conserve_flow(gm::GenericGasModel{T}, n::Int, i, yp_first, yn_first, yp_last, yn_last) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)

    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yn[i1]  == yp[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yp[i1]  == yn[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yn[i1] + yn[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yp[i1] + yp[i2] == 1))
            end
        end
    end

    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yn[i1] == yn[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yp[i1] == yp[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yn[i1] + yp[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yp[i1] + yn[i2] == 1))
            end
        end
    end

    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yp[i1]  == yp[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yn[i1]  == yn[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yp[i1] + yn[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yn[i1] + yp[i2] == 1))
            end
        end
    end

    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                add_constraint(gm, n, :conserve_flow1, i, @constraint(gm.model, yp[i1] == yn[i2]))
                add_constraint(gm, n, :conserve_flow2, i, @constraint(gm.model, yn[i1] == yp[i2]))
                add_constraint(gm, n, :conserve_flow3, i, @constraint(gm.model, yp[i1] + yp[i2] == 1))
                add_constraint(gm, n, :conserve_flow4, i, @constraint(gm.model, yn[i1] + yn[i2] == 1))
            end
        end
    end
end

"Constraint: This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption for a node with expansion edges"
function constraint_conserve_flow_ne(gm::GenericGasModel{T}, n::Int, idx, yp_first, yn_first, yp_last, yn_last) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)

    if length(yn_first) > 0 && length(yp_last) > 0
        for i1 in yn_first
            for i2 in yp_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yn1  == yp2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yp1  == yn2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yn1 + yn2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yp1 + yp2 == 1))
            end
        end
    end

    if length(yn_first) > 0 && length(yn_last) > 0
        for i1 in yn_first
            for i2 in yn_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yn1 == yn2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yp1 == yp2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yn1 + yp2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yp1 + yn2 == 1))

            end
        end
    end

    if length(yp_first) > 0 && length(yp_last) > 0
        for i1 in yp_first
            for i2 in yp_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yp1 == yp2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yn1 == yn2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yp1 + yn2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yn1 + yp2 == 1))

            end
        end
    end

    if length(yp_first) > 0 && length(yn_last) > 0
        for i1 in yp_first
            for i2 in yn_last
                yn1 = haskey(ref(gm,n,:connection),i1) ? yn[i1] : yn_ne[i1]
                yn2 = haskey(ref(gm,n,:connection),i2) ? yn[i2] : yn_ne[i2]
                yp1 = haskey(ref(gm,n,:connection),i1) ? yp[i1] : yp_ne[i1]
                yp2 = haskey(ref(gm,n,:connection),i2) ? yp[i2] : yp_ne[i2]

                add_constraint(gm, n, :conserve_flow_ne1, idx, @constraint(gm.model, yp1 == yn2))
                add_constraint(gm, n, :conserve_flow_ne2, idx, @constraint(gm.model, yn1 == yp2))
                add_constraint(gm, n, :conserve_flow_ne3, idx, @constraint(gm.model, yp1 + yp2 == 1))
                add_constraint(gm, n, :conserve_flow_ne4, idx, @constraint(gm.model, yn1 + yn2 == 1))
            end
        end
    end
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    add_constraint(gm, n, :parallel_flow1, k, @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) == yp[k] * length(ref(gm,n,:parallel_connections,(i,j)))))
end

"Constraint: ensures that parallel lines have flow in the same direction "
function constraint_parallel_flow_ne(gm::GenericGasModel{T}, n::Int, k, i, j, f_connections, t_connections, f_connections_ne, t_connections_ne) where T <: AbstractMIForms
    yp = var(gm,n,:yp)
    yn = var(gm,n,:yn)
    yp_ne = var(gm,n,:yp_ne)
    yn_ne = var(gm,n,:yn_ne)
    yp_k = haskey(ref(gm,n,:connection), k) ? yp[k] : yp_ne[k]
    yn_k = haskey(ref(gm,n,:connection), k) ? yn[k] : yn_ne[k]

    add_constraint(gm, n, :parallel_flow_ne1, k, @constraint(gm.model, sum(yp[i] for i in f_connections) + sum(yn[i] for i in t_connections) + sum(yp_ne[i] for i in f_connections_ne) + sum(yn_ne[i] for i in t_connections_ne) == yp_k * length(ref(gm,n,:all_parallel_connections,(i,j)))))
    add_constraint(gm, n, :parallel_flow_ne2, k, @constraint(gm.model, sum(yn[i] for i in f_connections) + sum(yp[i] for i in t_connections) + sum(yn_ne[i] for i in f_connections_ne) + sum(yp_ne[i] for i in t_connections_ne) == yn_k * length(ref(gm,n,:all_parallel_connections,(i,j)))))
end
