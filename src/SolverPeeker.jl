module SolverPeeker

using JuMP
using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

include("lprep.jl")
include("attributes.jl")
include("recognize.jl")
include("peek.jl")
include("solve.jl")


end
