"""
optimize
"""

export optimize!


# Return true if you set the solution


# Helper functions:
function valid_single_variable_bounds(rep)
    less = rep.less_than
    greater = rep.greater_than

    # If not empty, check if same element is everywhere in these dicts, and if not return
    common = union(values(less), values(greater))
    if !isempty(common) && length(union(values(less), values(greater))) != 1
        return false
    end
    return true
end



# Assumes algoModel or similar fields
function optimize!(model::AlgoModel, difference_constraint::DifferenceConstraints)
    rep = model.rep
    less = rep.less_than
    greater = rep.greater_than


    # Look at what requirement the variables have.
    # At this point we do not support differenet SingleVariable bounds.
    # All should be less than, or greater than, the same constant (typically zero).

    # If not empty, check if same elemnent is everywhere in these dicts, and if not return
    common = union(values(less), values(greater))
    if !isempty(common) && length(common) != 1
        set_trm_status!(model, Trm_Unknown)
        set_sln_status!(model, Sln_Unknown)
        return false
    end
    

    # See if DifferenceConstraints are recognized, if not, return false
    recognized, b, constraint_numbers = recognize(model, difference_constraint)

    if !recognized
        set_trm_status!(model, Trm_Unknown)
        set_sln_status!(model, Sln_Unknown)
        return false
    end

    # Make the constraint graph
    At = rep.At
    all_values = nonzeros(At)
    all_rows = rowvals(At)
    variable_count = rep.var_count
    constraint_count = rep.con_count

    # Indicating whether only subproblem was difference constraints, or if the whole problem was
    infeasible_test = false

    # If not all constraints are difference constraints, flag it as infeasibility test.
    number_of_edges = length(constraint_numbers)
    if constraint_count != number_of_edges
        infeasible_test = true
    end

    # Directed graph with weights
    graph = SimpleWeightedDiGraph(variable_count)


    # Add edges and distances to the graph
    # Only the recent edge is stored, so use the strictest edge!
    # Go through each constraint
    for k in constraint_numbers

        values = all_values[collect(nzrange(At, k))]
        rows = all_rows[collect(nzrange(At, k))]

        # The graph does not store zero edges, so
        # store them as a very small number.
        weight = b[k]
        weight = (weight == 0) ? eps(0.0) : weight

        # Find variable indices (row value in transpose) 
        # where the values are 1 and -1 (or plus and minus when same multiplum,
        # since only b normalized.

        i = findall(x->x<=-1, values)[1]
        i = rows[i]
        j = findall(x->x>=1, values)[1]
        j = rows[j]

        # Add edge with weight to graph if it's stricter
        if Graphs.has_edge(graph, i, j)
            old = Graphs.LinAlg.adjacency_matrix(graph)[i,j]
            weight = old < weight ? old : weight
        end

        SimpleWeightedGraphs.add_edge!(graph, i, j, weight)

    end


    # If the variables should be split around zero (or other constant),
    # add constraints for this.
    split = false
    if !isempty(greater) && !isempty(less)
        split = true
        edges = collect(Iterators.product(keys(greater), keys(less)))
        for edge in edges
            i = edge[1]
            j = edge[2]
            weight = eps(0.0)

            # Add edge with weight to graph if it's stricter
            if Graphs.has_edge(graph, i, j)
                old = Graphs.LinAlg.adjacency_matrix(graph)[i,j]
                weight = old < weight ? old : weight
            end

            SimpleWeightedGraphs.add_edge!(graph, i, j, weight)
        end
    end


        
    # Solve with adjusted Bellman-Ford
    try  
        dists = bellman_ford_adjusted(graph, Graphs.LinAlg.adjacency_matrix(graph), keys(model.rep.integer), difference_constraint.limit)

        # Adjust solution so that it fits with SingleVariable bounds
        if !isempty(common)
            min = minimum(dists)
            max = 0 # This is argued for in the paper.

            value = common[1]

            if split
                # Order the variables, and split into A and B, and move.
                #var_sol_pair = collect(zip(collect(keys(sorted_var_to_name)), dists))
                var_sol_pair = collect(zip([i for i in 1:rep.var_count], dists))

                # Remove the equal_to variables, so that we know how to split the other sets
                var_sol_pair = filter(x -> !haskey(rep.equal_to, x[1]), var_sol_pair)

                # Sort by solution
                sorted = sort(var_sol_pair, by=x->x[2])


                # Split into two sets:
                B = sorted[1:length(less)]
                A = sorted[(length(less)+1):end]


                # Check that B contains only less than, and A greater than?
                # TODO, but should not be possible.

                # Move solution, if possible.
                max_B = B[end][2]
                min_A = A[1][2]


                # It is possible to encounter an infeasible solution
                # if some variables are required to be integer and the circumstanses
                # results in having to move so that at least one of these constraints will be violated.
                if value > min_A   # Move solution up
                    delta = ceil(value - min_A)

                    # If rounding screws up and there is at least one integer, then it is infeasible.
                    # If not, move by the non-rounded version.
                    if (value - delta) < max_B
                        if !isempty(rep.integer)
                            # Infeasible
                            set_trm_status!(model, Trm_Infeasibility)
                            set_solution!(model, 
                                    Sln_Infeasible, 
                                    nothing, 
                                    nothing, 
                                    difference_constraint)
                            return true
                        end

                        delta = value - min_A
                    end

                    # Move original solution
                    dists = dists .+ delta

                elseif value < max_B   # Move solution down
                    delta = ceil(max_B - value)

                    # If rounding screws up and there is at least one integer, then it is infeasible.
                    # If not, move by the non-rounded version.
                    if (value + delta) > min_A
                        if !isempty(rep.integer)
                            # Infeasible
                            set_trm_status!(model, Trm_Infeasibility)
                            set_solution!(model, 
                                    Sln_Infeasible, 
                                    nothing, 
                                    nothing, 
                                    difference_constraint)
                            return true
                        end

                        delta = max_B - value
                    end
                    
                    # Move original solution 
                    dists = dists .- delta
                end


            elseif !isempty(greater)
                # All variables should be greater than something. Make the smallest element greater.
                if min < value
                    # Round up distance, as some variables may need to be integer
                    delta = ceil(value - min)
                    dists = dists .+ delta
                end

            else
                # All variables should be less than something. Make the greates element less.
                if max > value
                    # Round up distance, as some variables may need to be integer
                    delta = ceil(max - value)
                    dists = dists .- delta
                end
            end
        end

        # Insert equal_to variables in solution.
        # They will be isolated in the graph, since in the representation they are substituted,
        # and so they gain zero value from the original solution, and may be moved for single variable constraints.
        # We overwrite to obtain feasible solution.
        for (key, value) in rep.equal_to
            dists[key] = value
        end


        # If only a subproblem, either it fits the other constraints, and we are good, or we cannot know in an easy way
        if infeasible_test
            constraints_left = setdiff([a for a in 1:constraint_count], constraint_numbers)
            for j in constraints_left
                left_hand_side = 0
                for i in nzrange(At, j)
                    variable_index = all_rows[i]
                    left_hand_side += dists[variable_index]*all_values[i]
                end
                # If constraint does not hold, we do not know
                if left_hand_side > b[j]
                    set_trm_status!(model, Trm_Unknown)
                    set_sln_status!(model, Sln_Unknown)
                    return false
                end
            end
        end
        set_trm_status!(model, Trm_Feasibility)
        set_solution!(model, 
                    Sln_FeasiblePoint, 
                    dists, 
                    dot(model.rep.c, dists) + model.rep.obj_constant,
                    difference_constraint)

        return true

    catch error
        if isa(error, Graphs.NegativeCycleError)
            # Update no feasible solution
            set_trm_status!(model, Trm_Infeasibility)
            set_solution!(model, 
                    Sln_Infeasible, 
                    nothing, 
                    nothing, 
                    difference_constraint)

            return true
        elseif isa(error, CannotKnowError)
            set_trm_status!(model, Trm_IterationLimit)
            set_sln_status!(model, Sln_Unknown)
            return false
        else
            set_trm_status!(model, Trm_Unknown) 
            set_sln_status!(model, Sln_Unknown)
            throw(error)
            return false
        end
    end
end