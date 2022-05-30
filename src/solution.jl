export Solution
export set_solution!

mutable struct Solution
    #var_count::Union{Int64, Nothing}
    #con_count::Union{Int64, Nothing}

    primal_status::SolutionStatus
    #dual_status::SolutionStatus

    x::Union{Vector{Float64}, Nothing}
    #Ax::Union{Vector{Float64}, Nothing}

    objective_value::Union{Float64, Nothing}

    algorithm_used::Union{Algorithm, Nothing}

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


    function set_solution!(solution, primal_status, x, objective_value, algorithm_used)
        solution.primal_status = primal_status
        solution.x = x
        solution.objective_value = objective_value
        solution.algorithm_used = algorithm_used
    end