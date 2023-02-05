export Solution
export set_sln_status!

mutable struct Solution
    #var_count::Union{Int64, Nothing}
    #con_count::Union{Int64, Nothing}

    @atomic primal_status::SolutionStatus
    #dual_status::SolutionStatus

    @atomic x::Union{Vector{Float64}, Nothing}
    #Ax::Union{Vector{Float64}, Nothing}

    @atomic objective_value::Union{Float64, Nothing}

    @atomic algorithm_used::Union{Algorithm, Nothing}

end


#Solution(var_count, con_count) = Solution(
#        var_count, con_count,
#        Sln_Unknown,
#        #Sln_Unknown,
#        nothing,
#        #nothing,
#        nothing,
#        nothing
#    )

Solution() = Solution(
        #nothing, nothing,
        Sln_Unknown,
        #Sln_Unknown,
        nothing,
        #nothing,
        nothing,
        nothing
    )


function set_solution!(model, primal_status, x, objective_value, algorithm_used)
    # Return if already set by another thread!
    if model.solution.primal_status != Sln_Unknown
        return
    end
    @atomic model.solution.primal_status = primal_status
    @atomic model.solution.x = x
    if !isnothing(objective_value) 
        @atomic model.solution.objective_value = objective_value
    end
    @atomic model.solution.objective_value = objective_value
    @atomic model.solution.algorithm_used = algorithm_used
end

# TODO, test this. Update also if better solution?
function set_sln_status!(model, primal_status)
    # Return if already set by another thread.
    if (model.solution.primal_status != Sln_Unknown)
        return
    end
    @atomic model.solution.primal_status = primal_status
end
