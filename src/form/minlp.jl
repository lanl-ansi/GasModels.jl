# Define MINLP implementations of Gas Models

"Variables needed for modeling flow in MI models"
function variable_flow(gm::AbstractMINLPModel, n::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow(gm, n; bounded=bounded, report=report)
    variable_connection_direction(gm, n; report=report)
end


"Variables needed for modeling flow in MI models"
function variable_flow_ne(gm::AbstractMINLPModel, n::Int=gm.cnw; bounded::Bool=true, report::Bool=true)
    variable_mass_flow_ne(gm, n; bounded=bounded, report=report)
    variable_connection_direction_ne(gm, n; report=report)
end


"Weymouth equation with discrete direction variables"
function constraint_pipe_weymouth(gm::AbstractMINLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_pipe, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_pipe, k)

    # when y = 1, the first two equations say w*(pi - pj) == f^2.
    # This implies the third equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from i -> j, the largest value is f_max^2. This will make the RHS <= 0.  To then go sufficently below 0
    # we then need to subtract out pd_min
    # The fourth equation staets -f^2 <= f^2 which is always true.

    # when y = 0, the last two equations say w*(pj - pi) == f^2.
    # This implies the first equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from j -> i, the largest value is f_min^2. This will make the RHS <= 0.  To then go sufficently below 0
    # we then need to subtract out pd_max
    # The second equation staets -f^2 <= f^2 which is always true.

    _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w*(pi - pj) >= f^2 - (1-y) * (f_min^2 - w*pd_min)))
    _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w*(pi - pj) <= f^2))
    _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w*(pj - pi) >= f^2 - y * (f_max^2 + w*pd_max)))
    _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w*(pj - pi) <= f^2))
end


"Weymouth equation with discrete direction variables"
function constraint_resistor_weymouth(gm::AbstractMINLPModel, n::Int, k, i, j, f_min, f_max, w, pd_min, pd_max)
    y = var(gm, n, :y_resistor, k)
    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    f  = var(gm, n, :f_resistor, k)

    # when y = 1, first two constraints hold with equality. By definition, LHS of constraint 4 is negative, so it will always be true when y = 1
    # In order to deactivaate constraint 3, we need to cancel out f^2 (f_max^2) and then go sufficiently below 0 so that w(pj-pi) is always bigger (-pd_max)
    # when y = 0, first two constraints need to be deactivated with large enough big M. By definition, w*(pi-pj) <= 0,
    # so second constraint is deactivated. To deactive constraint 1, we need to big enough to get rid of f^2 and always be less than w(pi-pj).
    # The last two constraints hold with equality
    _add_constraint!(gm, n, :weymouth1, k, JuMP.@constraint(gm.model, w*(pi - pj) >= f^2 - (1-y) * (f_min^2 - w*pd_min)))
    _add_constraint!(gm, n, :weymouth2, k, JuMP.@constraint(gm.model, w*(pi - pj) <= f^2))
    _add_constraint!(gm, n, :weymouth3, k, JuMP.@constraint(gm.model, w*(pj - pi) >= f^2 - y * (f_max^2 + w*pd_max)))
    _add_constraint!(gm, n, :weymouth4, k, JuMP.@constraint(gm.model, w*(pj - pi) <= f^2))
end


"Weymouth equation for an expansion pipe"
function constraint_pipe_weymouth_ne(gm::AbstractMINLPModel,  n::Int, k, i, j, w, f_min, f_max, pd_min, pd_max)
    y = var(gm, n, :y_ne_pipe, k)

    pi = var(gm, n, :psqr, i)
    pj = var(gm, n, :psqr, j)
    zp = var(gm, n, :zp, k)
    f  = var(gm, n, :f_ne_pipe, k)

    # when zp = 0, then f = 0 and pd_min and pd_max provide sufficiently large bounds (constraints 2 and 4)
    # when zp = 1, then we have two euqations of the form w*(pi - pj) = +/- f^2 and w*(pj - pj) = -f^2

    # when y = 1, the first two equations say w*(pi - pj) == f^2.
    # This implies the third equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from i -> j, the largest value is f_max^2. Thus 2*f_max^2 is sufficient to subtract enough from f^2 to get a value < -f^2.
    # The fourth equation staets -f^2 <= f^2 which is always true.

    # when y = 0, the last two equations say w*(pj - pi) == f^2.
    # This implies the first equation is -f^2 >= f^2 + sufficiently large M to drop the rhs below the smallest valye of -f^2.
    # Given that flow is from j -> i, the largest value is f_min^2. Thus 2*f_min^2 is sufficient to subtract enough from f^2 to get a value < -f^2.
    # The second equation staets -f^2 <= f^2 which is always true.


    _add_constraint!(gm, n, :weymouth_ne1, k, JuMP.@constraint(gm.model, w*(pi - pj) >= f^2 + (1-zp)*w*pd_min - (1-y)*2*f_min^2))
    _add_constraint!(gm, n, :weymouth_ne2, k, JuMP.@constraint(gm.model, w*(pi - pj) <= f^2 + (1-zp)*w*pd_max) )
    _add_constraint!(gm, n, :weymouth_ne3, k, JuMP.@constraint(gm.model, w*(pj - pi) >= f^2 - (1-zp)*w*pd_max - y*2*f_max^2))
    _add_constraint!(gm, n, :weymouth_ne4, k, JuMP.@constraint(gm.model, w*(pj - pi) <= f^2 - (1-zp)*w*pd_min) )
end


"Constraint: constrains the ratio to be ``p_i \\cdot \\alpha = p_j``"
function constraint_compressor_ratio_value(gm::AbstractMINLPModel, n::Int, k, i, j)
    pi    = var(gm, n, :psqr, i)
    pj    = var(gm, n, :psqr, j)
    r = var(gm, n, :rsqr, k)
    _add_constraint!(gm, n, :compressor_ratio_value1, k, JuMP.@NLconstraint(gm.model, r^2 * pi <= pj))
    _add_constraint!(gm, n, :compressor_ratio_value2, k, JuMP.@NLconstraint(gm.model, r^2 * pi >= pj))
end


"Constraint: constrains the energy of the compressor"
function constraint_compressor_energy(gm::AbstractMINLPModel, n::Int, k, power_max, work)
end
