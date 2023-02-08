# Interface for optimizing with possibly algorithm objects

import JuMP.optimize!

export recognize, optimize!


# TODO: Throw exceptions
# TODO: Alter add_algorithm name to set_algorithm for consistency
# TODO: Make function get-ers?
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




