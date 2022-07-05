

export bellman_ford_adjusted

# Takes in a Graphs.SimpleWeightedDiGraph, distance matrix, and a vector of integral vertices
function bellman_ford_adjusted(graph, distmtx, integral_vertices)
    # Sources are all vertices

    nv = Graphs.nv(graph)  # Number of vertices

    # start at zero distance for each vertex, update lower bound
    classic_distances = zeros(nv) 
    integral_distances = Dict()

    for i in 1:(nv-1)
        for edge in Graphs.edges(graph)
            vi = Graphs.src(edge)
            vj = Graphs.dst(edge)

            vid = classic_distances[vi]
            vjd = classic_distances[vj]

            # Since 0-edges not stored, stores them as eps(0.0), so convert back to 0 if so.
            edge_weight = (distmtx[vi, vj] == eps(0.0)) ? 0 : distmtx[vi, vj]

            distance_via_vi = vid + edge_weight
            # Use rounding if integral head. If not, use without rounding.
            if in(vj, integral_vertices)
                relax_value = floor(distance_via_vi)
                if vjd > relax_value
                    integral_distances[vj] = relax_value
                    classic_distances[vj] = distance_via_vi
                end
            else
                relax_value = distance_via_vi
                if vjd > relax_value
                    classic_distances[vj] = distance_via_vi
                end
            end

        end
    end

    #Check for negative cycle without rounding
    for edge in Graphs.edges(graph)
        vi = Graphs.src(edge)
        vj = Graphs.dst(edge)

        vid = classic_distances[vi]
        vjd = classic_distances[vj]

        # Since 0-edges not stored, stores them as eps(0.0), so convert back to 0 if so.
        edge_weight = distmtx[vi, vj]==eps(0.0) ? 0 : distmtx[vi, vj]

        distance_via_vi = vid + edge_weight

        if vjd > distance_via_vi
            throw(Graphs.NegativeCycleError())
        end

    end

    # Add the integral distances into the result
    for (key, value) in integral_distances
        classic_distances[key] = value
    end

    return classic_distances

end