export Algorithm, DifferenceConstraints

abstract type Algorithm end

mutable struct DifferenceConstraints <: Algorithm 
    limit::Union{UInt128, Nothing}
end

DifferenceConstraints() = DifferenceConstraints(nothing)