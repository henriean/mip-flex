module SolverPeeker

using JuMP
using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

include("lprep.jl")
include("attributes.jl")
#include("peeker.jl")
include("recognize.jl")
include("solve.jl")
include("optimize.jl")


end
