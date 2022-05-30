# Interface for optimizing with possibly algorithm objects

import JuMP.optimize!

export recognize, optimize!


#function recognize(model::JuMP.Model, ::Type{T}) where T<: MOI.AbstractOptimizer
#    return true
#end

function optimize!(model::JuMP.Model, solver_constructor::Type{T}; add_bridges::Bool = true) where T <: MOI.AbstractOptimizer
    JuMP.set_optimizer(model, solver_constructor; add_bridges = add_bridges)
    optimize!(model)
end

function optimize!(model::JuMP.Model, vector::AbstractVector; add_bridges::Bool = true)
    for element in vector
        optimize!(model, element, add_bridges = add_bridges)
    end
end

# Assumes rep not set, but algorithms are set
function optimize!(model::JuMP.Model, algo_model::AlgoModel; kwargs...)
    if !are_algorithms_set(algo_model)
        # Set status or something
        algo_model.status = Trm_NotCalled
        algo_model.solution.primal_status = Sln_Unknown
        print("\n No algorithms are specified for this model.\n")
        return
    end
    set_rep!(algo_model, model)

    optimize!(algo_model)
end


function optimize!(algo_model::AlgoModel)
    if !are_algorithms_set(algo_model)
        # Set status or something
        algo_model.status = Trm_NotCalled
        algo_model.solution.primal_status = Sln_Unknown
        print("\n No algorithms are specified for this model.\n")
        return
    elseif !is_rep_set(algo_model)
        algo_model.status = Trm_NotCalled
        algo_model.solution.primal_status = Sln_Unknown
        print("\n No representation is specified for this model.\n")
        return
    end

    # TODO: Check if return kills threads!
    Threads.@threads for algorithm in algo_model.algorithms
        # Optimize has to connect a Solution to AlgoModel, 
        # and return true if came to a conclusion
        optimize!(algo_model, algorithm)
        if got_answer(algo_model)
            return
        end
    end
end





