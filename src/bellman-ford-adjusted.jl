

export bellman_ford_adjusted

# Takes in a Graphs.SimpleWeightedDiGraph, distance matrix, and a vector of integral vertices
function bellman_ford_adjusted(graph, distmtx, integral_vertices)
    # Sources are all vertices

    nv = Graphs.nv(graph)  # Number of vertices

    # start at zero distance for each vertex, update lower bound
    distances = zeros(nv) 

    for i in 1:(nv-1)
        for edge in Graphs.edges(graph)
            vi = Graphs.src(edge)
            vj = Graphs.dst(edge)

            vid = distances[vi]
            vjd = distances[vj]

            # Since 0-edges not stored, stores them as eps(0.0), so convert back to 0 if so.
            edge_weight = (distmtx[vi, vj] == eps(0.0)) ? 0 : distmtx[vi, vj]

            distance_via_vi = vid + edge_weight
            # Use rounding if integral head, and fractional tail of edge. If not, use without rounding.
            relax_value = (in(vj, integral_vertices)) ? floor(distance_via_vi) : distance_via_vi

            # Update upper bound on vj if the new estimate is better
            distances[vj] = (vjd > relax_value ? relax_value : vjd)

        end
    end

    #Check for negative cycle
    for edge in Graphs.edges(graph)
        vi = Graphs.src(edge)
        vj = Graphs.dst(edge)

        vid = distances[vi]
        vjd = distances[vj]

        # Since 0-edges not stored, stores them as eps(0.0), so convert back to 0 if so.
        edge_weight = distmtx[vi, vj]==eps(0.0) ? 0 : distmtx[vi, vj]

        distance_via_vi = vid + edge_weight
        # Use rounding if integral head, and fractional tail of edge. If not, use without rounding.
        check_value = (in(vj, integral_vertices) && !in(vi, integral_vertices)) ? floor(distance_via_vi) : distance_via_vi

        if vjd > check_value
            throw(Graphs.NegativeCycleError())
        end

    end

    return distances

end