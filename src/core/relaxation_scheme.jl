
# general relaxation of a square term
function relaxation_sqr(m, x, y)
    c1 = @constraint(m, y >= x^2)
    c2 = @constraint(m, y <= (getupperbound(x)+getlowerbound(x))*x - getupperbound(x)*getlowerbound(x))
    return Set([c1, c2])
end


# general relaxation of binlinear term (McCormick)
function relaxation_product(m, x, y, z)
    x_ub = getupperbound(x)
    x_lb = getlowerbound(x)
    y_ub = getupperbound(y)
    y_lb = getlowerbound(y)

    c1 = @constraint(m, z >= x_lb*y + y_lb*x - x_lb*y_lb)
    c2 = @constraint(m, z >= x_ub*y + y_ub*x - x_ub*y_ub)
    c3 = @constraint(m, z <= x_lb*y + y_ub*x - x_lb*y_ub)
    c4 = @constraint(m, z <= x_ub*y + y_lb*x - x_ub*y_lb)

    return Set([c1, c2, c3, c4])
end


