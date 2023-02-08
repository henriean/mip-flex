"""
    MipFlex

Wrapper for JuMP models, looking for patterns in order to find alternative solutions procedures for linear programs.

# Example
...
"""

# TODO: An example with sending in heuristic or flag?
# TODO: Time limit?

module MipFlex

using JuMP
using MathOptInterface
using SparseArrays
using LightGraphs
using Graphs, SimpleWeightedGraphs
using LinearAlgebra
const MOI = MathOptInterface
const MOIU = MOI.Utilities

include("exceptions.jl")
include("status.jl")
include("algorithms.jl")
include("lprep.jl")
include("solution.jl")
include("algoModel.jl")
include("interface.jl")
include("bellman-ford-adjusted.jl")
include("attributes.jl")
include("recognize.jl")
include("optimize.jl")

end
