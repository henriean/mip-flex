"""
optimize
"""

export optimize!

#function optimize!(::JuMP.Model, ::AbstractOptimizeAttribute) <: Bool end
#function optimize!(::JuMP.Model) <: Bool end


# Will use all available methods for recognizion, and solving if recognized.
# Else use the provided solver if any is attatched.
# NB, cannot change model while solving.
function optimize!(model::JuMP.Model)

    lpmodel = get_lpmodel(model)
    A, b, At = get_constraint_matrices(lpmodel)

    recognized, b = recognize(At, b, DifferenceConstraints())
    if recognized && recognize(b, AllIntegerConstraintBounds())
        if solve!(At, b, model, ShortestPath()) 
            print("\nProgram solved with Bellman-Ford shortest path.\n")
            return true     # Replace with status
        end
    else
        print("\nDid not reccognize any faster solutions.\n")
    end

    if !(isnothing(model.moi_backend.optimizer))
        print("\nUsing the attatched optimizer...\n")
        JuMP.optimize!(model)
        return false
    else
        print("\nThe model cannot be solved without an attatched solver.\n")
        return false
    end

end
