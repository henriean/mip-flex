

export AlgoModel
export add_algorithms!, add_algorithm!, set_rep!
export is_rep_set, are_algorithms_set, got_answer

mutable struct AlgoModel

    status::TerminationStatus  

    rep::Union{LPRep, Nothing}

    algorithms::Union{Vector{Algorithm}, Nothing}

    solution::Solution

    # Possibly add a struct of parameters if needed later.

end

# Constructors
AlgoModel(jump_model)  = AlgoModel(Trm_NotCalled, LPRep(jump_model), nothing, Solution())

AlgoModel(algorithm::Algorithm) = AlgoModel(Trm_NotCalled, nothing, [algorithm], Solution())

AlgoModel(algorithms::Vector) = AlgoModel(Trm_NotCalled, nothing, algorithms, Solution())

AlgoModel(jump_model, algorithm) = AlgoModel(Trm_NotCalled, LPRep(jump_model), [algorithm], Solution())

AlgoModel(jump_model, algorithms::Vector) = AlgoModel(Trm_NotCalled, LPRep(jump_model), algorithms, Solution())




# Requires model to have an algorithms field.
function add_algorithms!(algo_model, algorithms::Vector)
    
    old_algorithms = (isnothing(algo_model.algorithms) ? [] : algo_model.algorithms)

    set = setdiff(algorithms, old_algorithms)
    algo_model.algorithms = append!(old_algorithms, set)
end

add_algorithm!(algo_model, algorithm::Algorithm) = add_algorithms!(algo_model, [algorithm])


function set_rep!(algo_model, jump_model)
    algo_model.rep = LPRep(jump_model)
end


#TODO getters?, Optimize(under ), print solution

# Checks for set fields:
# Maybe not needed

function is_rep_set(algo_model)
    if !isnothing(algo_model.rep)
        return true
    end
    return false
end

function are_algorithms_set(algo_model)
    if !isnothing(algo_model.algorithms)
        return true
    end
    return false
end

function got_answer(algo_model)
    if algo_model.solution.primal_status != Sln_Unknown
        return true
    end
    return false
end





