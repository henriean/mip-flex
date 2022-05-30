using LightGraphs
using Graphs, SimpleWeightedGraphs
using LinearAlgebra

"""
optimize
"""

export optimize!


# Return true if you set the solution?
# For ::DifferenceConstraints
#TODO: Register solution.
#TODO: Sjekke hvordan enkeltvariabler blir registrert!
#TODO: Implementer det nyeste jeg har skrevet om i oppgaven. 
function optimize!(model, ::DifferenceConstraints)
    recognized, b = recognize(model, DifferenceConstraints())
    rep = model.rep
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
        # Go through each constraint
        for k in 1:constraint_count
            values = nzval[colptr[k]:colptr[k+1]-1]

            if b[k] == 0
                b[k] = eps(0.0)
            end

            # Find variable indices (row value in transpose) 
            # where the values are 1 and -1 (or plus and minus when same multiplum,
            # since only b normalized.
            i = findall(x->x<=-1, values)[1]
            i = rowval[colptr[k]-1 + i]
            j = findall(x->x>=1, values)[1]
            j = rowval[colptr[k]-1 + j]

            # Add edge with weight to graph
            SimpleWeightedGraphs.add_edge!(graph, i, j, b[k])

        end

        # Use all vertices as sources, as we omit the starting source
        sources = collect(1:variable_count)

        try  
            bf = Graphs.bellman_ford_shortest_paths(graph, sources, Graphs.weights(graph))

            # TODO: Be sure not only one solution
            # TODO: Stop other threads
            model.status = Trm_DualInfeasible
            set_solution!(model.solution, 
                        Sln_FeasiblePoint, 
                        bf.dists, 
                        dot(model.rep.c, bf.dists) + model.rep.obj_constant, 
                        DifferenceConstraints())

            return true
        catch error
            if isa(error, Graphs.NegativeCycleError)
                # Update no feasible solution
                # TODO: Not sure if dual infeasible or not. Check results?
                # TODO: Stop other threads
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




