"""
solve
"""

function solve!(::Model, ::AbstractSolveAttribute) <: Nothing end

function solve!(model::Model, ::ConstantObjective)
    # Set optimal objective value (if legal)
    MOI.set(model, MOI.ObjectiveValue(), objective_function(model, objective_function_type(model)).constant)

    # Check if there is a legal solution for the variables, and set result status accordingly
    for (F, S) in list_of_constraint_types(model)
        for cref in all_constraints(model, F, S)
            setVariable(model, cref, F, S)
        end
    end
end



function setVariable(model::Model, ::Any, ::VariableRef, ::Union{})

    MOI.set(model, MOI.PrimalStatus(), MOI.INFEASIBLE_POINT)
    MOI.set(model, MOI.PrimalStatus(), MOI.FEASIBLE_POINT)
end