"""
 recognize

 """


"""
Functions for recognizing properties of the a LPModel

"""

export recognize

#function recognize(::SparseMatrixCSC{Float64, Int64}, ::Array{Float64,1}, ::AbstractRecognizeAttribute) <: Bool end


function recognize(At, b, ::DifferenceConstraints)
    # NB: Works on transpose of A
    nzval = At.nzval
    colptr = At.colptr
    variable_count = At.m # rows
    constraint_count = At.n # columns
    b_orig = b
    if (variable_count <= 1 || constraint_count==0)
        return (false, b_orig)
    end

    # Go through each row
    for j in 1:constraint_count
        values = nzval[colptr[j]:colptr[j+1]-1]

        # drop zeros TODO
        # Evt. hvis liten verdi
        
        # Normalize:
        for value in values
            if value != 0 && abs(value) != 1
                values = values/abs(value)
                b[j] = b[j]/abs(value)
            end
            break
        end

        # Check for difference constraint:
        difference_constraint = zeros(size(values))
        difference_constraint[1] = 1
        difference_constraint[2] = -1
        
        if !issetequal(values, difference_constraint)
            return (false, b_orig)
        end

    end
    return (true, b)
end

function recognize(lpmodel, ::AllIntegerVariables)
    integers = get_integer_variables(lpmodel)
    # Filter out the NaNs:
    num_imntegers = length(filter(integers->!isnan(integers),integers))
    return num_imntegers == lpmodel.num_variables_created
end

function recognize(b, ::AllIntegerConstraintBounds)
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




