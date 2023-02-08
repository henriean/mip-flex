
import JuMP.solver_name, JuMP.set_optimizer

export AlgoModel
export update!, add_algorithms!, add_algorithm!, set_rep!, set_optimizer, set_trm_status!
export is_model_set, is_rep_set, are_algorithms_set, got_answer, solver_name

# TODO: Get-methods and set-methods
# TODO: Parallelism flag?
mutable struct AlgoModel

    @atomic status::TerminationStatus  

    jump_model::Union{JuMP.Model, Nothing}

    rep::Union{LPRep, Nothing}

    algorithms::Union{Vector{Algorithm}, Nothing}

    @atomic solution::Solution

    # Possibly add a struct of parameters if needed later.

end

# Constructors
AlgoModel() = AlgoModel(Trm_NotCalled, nothing, nothing, nothing, Solution()) # TODO: Test

AlgoModel(jump_model) = AlgoModel(Trm_NotCalled, jump_model, LPRep(jump_model), nothing, Solution())

AlgoModel(algorithm::Algorithm) = AlgoModel(Trm_NotCalled, nothing, nothing, [algorithm], Solution())

AlgoModel(algorithms::Vector) = AlgoModel(Trm_NotCalled, nothing, nothing, algorithms, Solution())

AlgoModel(jump_model, algorithm) = AlgoModel(Trm_NotCalled, jump_model, LPRep(jump_model), [algorithm], Solution())

AlgoModel(jump_model, algorithms::Vector) = AlgoModel(Trm_NotCalled, jump_model, LPRep(jump_model), algorithms, Solution())


# TODO: Test
function update!(algo_model)
    algo_model.rep = LPRep(jump_model)
end

# Requires model to have an algorithms field.
function add_algorithms!(algo_model, algorithms::Vector)
    
    old_algorithms = (isnothing(algo_model.algorithms) ? [] : algo_model.algorithms)

    set = setdiff(algorithms, old_algorithms)
    algo_model.algorithms = append!(old_algorithms, set)
end

add_algorithm!(algo_model, algorithm::Algorithm) = add_algorithms!(algo_model, [algorithm])


# TODO: Remove algorithm!
# Prioritetsfelt!


function set_rep!(algo_model, jump_model)
    algo_model.jump_model = jump_model
    algo_model.rep = LPRep(jump_model)
end


function set_optimizer(algo_model::AlgoModel, optimizer)
    if is_model_set(algo_model)
        set_optimizer(algo_model.jump_model, optimizer)
        return true
    else
        return false
    end
end


ok_statuses = [Trm_Optimal, Trm_PrimalInfeasible, Trm_DualInfeasible, Trm_PrimalDualInfeasible, Trm_SolverUsed]
function set_trm_status!(algo_model, status::TerminationStatus)
    # Return if already set by another thread!
    if in(algo_model.status, ok_statuses)
        return
    end
    @atomic algo_model.status = status
end


function solver_name(algo_model::AlgoModel)
    solver_name(algo_model.jump_model)
end



function is_model_set(algo_model)
    if !isnothing(algo_model.jump_model)
        return true
    end
    return false
end


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


