# Attributes

"""
    AbstractRecognizeAttribute

Abstract supertype for attribute objects that will be used in the recognize function
in order to specify which features of the provided model to look into.

"""

export ConstantObjective, AllIntegerVariables, AllIntegerConstraintBounds


abstract type AbstractRecognizeAttribute end


# TODO: Describe each attribute

#struct DifferenceConstraints <: AbstractRecognizeAttribute end
struct AllIntegerVariables <: AbstractRecognizeAttribute end
struct ConstantObjective <: AbstractRecognizeAttribute end
struct AllIntegerConstraintBounds <: AbstractRecognizeAttribute end



"""
    AbstractSolveAttribute

Abstract supertype for attribute objects that will be used in the solve function
in order to specify which ways to solve the model.

"""

export ShortestPath

abstract type AbstractSolveAttribute end

struct ShortestPath <: AbstractSolveAttribute end



"""
    AbstractOptimizeAttribute

Abstract supertype for attribute objects that will be used in order to specify what to do when optimizing the model.

"""

abstract type AbstractOptimizeAttribute end

