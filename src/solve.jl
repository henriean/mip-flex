using LightGraphs

"""
solve
"""

export solve!

function solve!(::LPModel, ::JuMP.Model, ::AbstractSolveAttribute) <: Bool end


# Will construct the constraint graph and find a feasible solution or deem the problem infeasible
# NB: Assumes the model to have difference constraints only!
function solve!(lpmodel::LPModel, model::JuMP.Model, ::ShortestPath)
    A, b = get_constraint_matrices(lpmodel)

    edges = fill((0,0), size(A)[1])   # Number of constraints

    num_vars = size(A)[2]
    distmx = zeros(num_vars, num_vars)

    # Get list of edges and distance matrix
    index = 1
    for row in eachrow(A)
        i = findall(x->x==-1, row)[1]
        j = findall(x->x==1, row)[1]
        edge = (i,j)
        edges[index] = edge

        distmx[i,j] = b[index]

        index += 1
    end

    # Directed graph
    digraph = SimpleDiGraph(Edge.(edges))
    # Use all vertices as sources, as we omit the starting source
    sources = collect(1:num_vars)
    
    try  
        bf = bellman_ford_shortest_paths(digraph, sources, distmx)
        distances = bf.dists
        print("\nFeasible solution found:\n")
        show(distances)
        print("\n")
        # Update to feasible unbounded solution
        return true
    catch error
        if isa(error, LightGraphs.NegativeCycleError)
            # Update no feasible solution
            print("\nInfeasible solution.\n")
            return true
        else
            throw(error)
            return false
        end
    end

end





"""
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
"""