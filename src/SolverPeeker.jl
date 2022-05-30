"""
    SolverPeeker

Wrapper for JuMP models, looking for patterns in order to find alternative solutions procedures for linear programs.

# Example
...
"""
module SolverPeeker

using JuMP
using MathOptInterface
using SparseArrays
using Memoization
const MOI = MathOptInterface
const MOIU = MOI.Utilities

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
