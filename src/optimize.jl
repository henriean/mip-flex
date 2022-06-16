"""
optimize
"""

export optimize!


# Return true if you set the solution


# Helper functions:
# TODO: move to other file later



# Assumes algoModel or similar fields
function optimize!(model::AlgoModel, ::DifferenceConstraints)
    recognized, b = recognize(model, DifferenceConstraints())
    rep = model.rep


    # Look at what requirement the variables have
    # If less than zero, great. If greater than zero, move solution.
    # If split, add edges to the graph, and move solution.
    #less = rep.less_than
    #greater = rep.greater_than
    #move_to_greater = false
    #move_to_middle = false

    #if !isempty(less) && !isempty(greater)
        # If not same bound for all, not supported, set unknown and return!!!!

        # add edges

        # flag move solution to split
    #    move_to_middle = true
    #elseif !isempty(greater) 
        # flag move solution over a minimum
    #    move_to_greater
    #elseif !isempty(less)
        # flag move solution under a maximum
    #end


    if recognized
        At = rep.At
        nzval = At.nzval
        colptr = At.colptr
        rowval = At.rowval
        variable_count = rep.var_count
        constraint_count = rep.con_count

        
        # Directed graph with weights
        graph = SimpleWeightedDiGraph(variable_count)


        # Add edges and distances to the graph
        # Only the recent edge is stored, so use the strictest edge!
        # Go through each constraint
        for k in 1:constraint_count
            # Row k
            values = nzval[colptr[k]:colptr[k+1]-1]

            # The graph does not store zero edges, so
            # store them as a very small number.
            weight = b[k]
            weight = (weight == 0) ? eps(0.0) : weight

            # Find variable indices (row value in transpose) 
            # where the values are 1 and -1 (or plus and minus when same multiplum,
            # since only b normalized.

            i = findall(x->x<=-1, values)[1]
            i = rowval[colptr[k]-1 + i]
            j = findall(x->x>=1, values)[1]
            j = rowval[colptr[k]-1 + j]

            # Add edge with weight to graph if it's stricter
            if Graphs.has_edge(graph, i, j)
                old = Graphs.LinAlg.adjacency_matrix(graph)[i,j]
                weight = old < weight ? old : weight
            end

            SimpleWeightedGraphs.add_edge!(graph, i, j, weight)

        end

        
        # Solve with adjusted Bellman-Ford
        try  
            dists = bellman_ford_adjusted(graph, Graphs.LinAlg.adjacency_matrix(graph), keys(model.rep.integer))

            # TODO: Be sure not only one solution
            model.status = Trm_DualInfeasible
            set_solution!(model.solution, 
                        Sln_FeasiblePoint, 
                        dists, 
                        dot(model.rep.c, dists) + model.rep.obj_constant, 
                        DifferenceConstraints())

            return true
        catch error
            if isa(error, Graphs.NegativeCycleError)
                # Update no feasible solution
                # TODO: Not sure if dual infeasible or not. Check results?
                model.status = Trm_PrimalInfeasible
                set_solution!(model.solution, 
                        Sln_Infeasible, 
                        nothing, 
                        nothing, 
                        DifferenceConstraints())

                return true
            else
                model.status = Trm_Unknown  
                model.solution.primal_status = Sln_Unknown  
                throw(error)
                return false
            end
        end
    else
        model.status = Trm_Unknown
        model.solution.primal_status = Sln_Unknown
        return false
    end
end




