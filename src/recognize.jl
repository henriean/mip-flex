"""
 recognize

 """


"""
Functions for recognizing properties of the a LPModel

"""

export recognize

# TODO. If x1 - x2 <= 0
# And x2 - x1 <= 0,
# Then set x1 == x2.
# Thus. x1 and x2 can be reduced to one variable with strictest bound.

# Works on AlgoModel.
function recognize(model, ::DifferenceConstraints)
    # NB: Works on transpose of A
    lp = model.rep
    At = lp.At 
    all_values = nonzeros(At)
    b = lp.b

    # Constraints being difference constraints:
    diff_consts = Dict()

    # If less than 2 variables, or there are no constraints, 
    # its not a difference_constraint problem.
    if (lp.var_count < 2 || lp.con_count == 0)
        return (false, nothing, nothing)
    end

    # A difference constraint to check equality against:
    difference_constraint = [1, -1]

    # Go through each row
    for j in 1:lp.con_count
        values = all_values[collect(nzrange(At, j))]

        # If more than two non-zero variables, it's not difference constraints,
        # Less than 2 does not appear since it's filtered to single variable vectors at construction of LPRep.
        if size(values)[1] > 2
            continue
        elseif size(values)[1] == 2
            # Normalize values and b
            # If they are a multiple of each other, dividing by the first element should suffice.
            # TODO: Dropzero should prevent dividing by zero, though a very small number could cause problems?
            v = abs(values[1])
            values = values/v

            if !issetequal(values, difference_constraint)
                continue
            end

            b[j] = b[j]/v

            diff_consts[j] = true

        else    # Should never get here.
            return (false, nothing, nothing)
        end
    end

    # If some constraints passed, then return true and the corresponding constraints as a vector
    # Else, not recognized, so return false and nothing
    if length(diff_consts) >= 1
        constraint_numbers = [key for (key, _) in diff_consts]
        return (true, b, constraint_numbers)
    else
        return (false, nothing, nothing)
    end
end
