using LightGraphs

"""
Solve
"""

export solve!

#function solve!(::LPModel, ::JuMP.Model, ::AbstractSolveAttribute) <: Bool end


""" Will construct the constraint graph and find a feasible solution or deem the problem infeasible
 NB: Assumes the model to have difference constraints only! """
function solve!(At, b, model::JuMP.Model, ::ShortestPath)
    # NB: Works on transpose of A
    nzval = At.nzval
    colptr = At.colptr
    rowval = At.rowval
    variable_count = At.m # rows
    constraint_count = At.n # columns

    edges = fill((0,0), constraint_count)   # Number of constraints

    distmx = zeros(variable_count, variable_count)

    # Get list of edges and distance matrix
    # Go through each constraint
    index = 1
    for k in 1:constraint_count
        values = nzval[colptr[k]:colptr[k+1]-1]
        
        # Find constraint index (row value in transpose) where the values are 1 and -1
        i = findall(x->x==-1, values)[1]
        i = rowval[colptr[k]-1 + i]
        j = findall(x->x==1, values)[1]
        j = rowval[colptr[k]-1 + j]

        edge = (i,j)
        edges[index] = edge

        distmx[i,j] = b[index]

        index += 1
    end

    # Directed graph
    digraph = SimpleDiGraph(Edge.(edges))
    # Use all vertices as sources, as we omit the starting source
    sources = collect(1:variable_count)
    
    try  
        bf = SolverPeeker.bellman_ford_shortest_paths(digraph, sources, distmx)
        distances = bf.dists
        print("\nFeasible solution found:\n")
        show(distances)
        print("\n")
        # Check if solution + constant alter solution, and then report if unique or unbounded solution?
        return true
    catch error
        if isa(error, NegativeCycleError)
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