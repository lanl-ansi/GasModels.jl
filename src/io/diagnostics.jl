
"Output the constraints"
function print_constraints(f::IO, gm::GenericGasModel, i = gm.cnw)     
    count = 0
    for (key, component) in sort(gm.con[:nw][i])
        count = count + length(component)        
        for (key2, constraint) in sort(component)
            println(f, constraint)
        end      
    end
    print(f, "Number of Constraints: ")
    println(f, count)
end

"Output the variables"
function print_variables(f::IO, gm::GenericGasModel, i = gm.cnw)   
    for (key, variable) in sort(gm.var[:nw][i])
        println(f, "lower bound")
        println(f, getlowerbound(variable))
        println(f, "upper bound")
        println(f, getupperbound(variable))                  
    end
end