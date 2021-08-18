"""
 recognize

 """


"""
Functions for recognizing properties of the a LPModel

"""

export recognize

function recognize(::LPModel, ::AbstractRecognizeAttribute) <: Bool end


function recognize(lpmodel::LPModel, ::DifferenceConstraints)
    A, b = get_constraint_matrices(lpmodel)
    variable_count = size(A)[2]
    if (variable_count <= 1 || size(A)[1]==0)
        return false
    end
    compare = zeros(variable_count)
    compare[1] = 1
    compare[2] = -1
    for row in eachrow(A)
        if !issetequal(row, compare)
            return false
        end
    end
    return true
end

function recognize(lpmodel::LPModel, ::AllIntegerVariables)
    integers = get_integer_variables(lpmodel)
    # Filter out the NaNs:
    num_imntegers = length(filter(integers->!isnan(integers),integers))
    return num_imntegers == lpmodel.num_variables_created
end

function recognize(lpmodel::LPModel, ::AllIntegerConstraintBounds)
    A, b = get_constraint_matrices(lpmodel)
    # If after truncation the element is equal to itself, it is an integer:
    for element in b
        if !(trunc(Int, element) == element)
            return false
        end
    end
    return true
end



"""

function recognize(lpmodel::LPModel, ::ConstantObjective)
    c = get_objective_vector(lpmodel)
    return (c == zeros(size(c)[1]))
end"""




