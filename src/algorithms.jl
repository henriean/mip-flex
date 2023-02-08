export Algorithm, DifferenceConstraints

abstract type Algorithm end

struct DifferenceConstraints <: Algorithm 
    limit::Union{UInt128, Nothing}
end
DifferenceConstraints() = DifferenceConstraints(nothing)

struct TestAlgorithm <: Algorithm end