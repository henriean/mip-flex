export Algorithm, DifferenceConstraints

abstract type Algorithm end

mutable struct DifferenceConstraints <: Algorithm 
    @memoize DifferenceConstraints() = new()
end


