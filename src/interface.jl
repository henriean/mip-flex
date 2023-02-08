# Interface for optimizing with possibly algorithm objects

import JuMP.optimize!

export recognize, optimize!


# TODO: Throw exceptions
# TODO: Alter add_algorithm to set_algorithm
# TODO: Make function get(algoModel, TerminationStatus())
# Could re-make model in case it is updated, every time optimize is called?
function optimize!(algo_model::AlgoModel)

    # Check if model is set
    if !is_model_set(algo_model)
        # exception
        return
    end

    # Check that representation is set
    if !is_rep_set(algo_model)
        algo_model.rep = LPRep(algo_model.jump_model)
    end

    # If problem already is inconsistent, we know it's infeasible already
    if !algo_model.rep.is_consistent
        set_trm_status!(algo_model, Trm_Infeasibility)
        set_sln_status!(algo_model, Sln_Infeasible)
        return
    end

    # Check that algorithms are set
    if !are_algorithms_set(algo_model)
        try
            optimize!(algo_model.jump_model)
            # Set TerminationStatus, and solution
            set_trm_status!(algo_model, Trm_SolverUsed)
            set_sln_status!(algo_model, Sln_SolverUsed)
            return
        catch e
            # exception that neither algorithms or optimizer set
            return
        end
    end

    if Threads.nthreads() == 1

        for algorithm in algo_model.algorithms
            # Optimize has to connect a Solution to AlgoModel if it finds an answer, 
            # and return true if came to a conclusion, and false otherwise.
            # This optimize! will be in the optimize file.

            if optimize!(algo_model, algorithm) == true
                return
            end
        end

        try
            optimize!(algo_model.jump_model)
            # Set TerminationStatus, and solution
            set_trm_status!(algo_model, Trm_SolverUsed)
            set_sln_status!(algo_model, Sln_SolverUsed)
            return
        catch e
            # set unknown
            return
        end

    # More than one thread:
    else
        Threads.@threads for algorithm in algo_model.algorithms
            if optimize!(algo_model, algorithm) == true
                return
            end
        end

        Threads.@spawn (try
            optimize!(algo_model.jump_model)
            # Set TerminationStatus, and solution
            set_trm_status!(algo_model, Trm_SolverUsed)
            set_sln_status!(algo_model, Sln_SolverUsed)
            return
        catch e
            # set unknown
            return
        end)

    end

end


# TODO: Make a method for setting no solution if LP not consistent!!!




#_____________________
# Remove following?

#function recognize(model::JuMP.Model, ::Type{T}) where T<: MOI.AbstractOptimizer
#    return true
#end

#function optimize!(model::JuMP.Model, solver_constructor::Type{T}; add_bridges::Bool = true) where T <: MOI.AbstractOptimizer
#    JuMP.set_optimizer(model, solver_constructor; add_bridges = add_bridges)
#    optimize!(model)
#end


# TODO: Fix?
#function optimize!(model::JuMP.Model, vector::AbstractVector; add_bridges::Bool = true)
#    for element in vector
#        optimize!(model, element, add_bridges = add_bridges)
#    end
#end

# Assumes rep not set, but algorithms are set
#function optimize!(model::JuMP.Model, algo_model::AlgoModel; kwargs...)
#    if !are_algorithms_set(algo_model)
#        # Set status or something
#        algo_model.status = Trm_NotCalled
#        algo_model.solution.primal_status = Sln_Unknown
#        print("\n No algorithms are specified for this model.\n")
#        return
#    end

#    set_rep!(algo_model, model)

#    optimize!(algo_model)
#end




