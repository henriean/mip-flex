

export bellman_ford_adjusted

# Takes in a Graphs.SimpleWeightedDiGraph, distance matrix, and a vector of integral vertices
function bellman_ford_adjusted(graph, distmtx, integral_vertices, limit)
    # Sources are all vertices

    nv = Graphs.nv(graph)  # Number of vertices

    # start at zero distance for each vertex, update lower bound
    distances = zeros(nv) 

    # Standard is nodes-1 iterations, but if a greater limit is set, use this.
    if isnothing(limit) || limit < nv-1
        limit = nv-1
    end

    # Check if it is a mixed integer problem
    if length(integral_vertices) >= 1 && length(integral_vertices) < nv
        mix = true
    else
        mix = false
    end

    for _ in 1:(limit+1)    # plus 1 so that we can check if it stabilized.
        updated = false
        for edge in Graphs.edges(graph)
            vi = Graphs.src(edge)
            vj = Graphs.dst(edge)

            vid = distances[vi]
            vjd = distances[vj]

            # Since 0-edges not stored, stores them as eps(0.0), so convert back to 0 if so.
            edge_weight = (distmtx[vi, vj] == eps(0.0)) ? 0 : distmtx[vi, vj]

            distance_via_vi = vid + edge_weight
            # Use rounding if integral head. If not, use without rounding.
            if in(vj, integral_vertices)
                relax_value = floor(distance_via_vi)
                if vjd > relax_value
                    distances[vj] = relax_value
                    updated = true
                end
            else
                relax_value = distance_via_vi
                if vjd > relax_value
                    distances[vj] = distance_via_vi
                    updated = true
                end
            end

        end
        if updated == false    # It has to have stabilized
            return distances
        end
    end

    # If got here, it never stabilized. If it was not mixed integers,
    # then there is no solution. Else we do not now.

    if !mix
        throw(Graphs.NegativeCycleError())
    else
        throw(CannotKnowError())
    end

end