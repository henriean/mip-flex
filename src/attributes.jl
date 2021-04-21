# Attributes

"""
    AbstractRecognizeAttribute

Abstract supertype for attribute objects that will be used in the recognize function
in order to specify which features of the provided model to look into.

"""

export ObjectiveIsConstant


abstract type AbstractRecognizeAttribute end


# TODO: Describe each attribute

struct ObjectiveIsConstant <: AbstractRecognizeAttribute end



"""
    AbstractSolveAttribute

Abstract supertype for attribute objects that will be used in the solve function
in order to specify which ways to solve the model.

"""

abstract type AbstractSolveAttribute end

struct ConstantObjective <:AbstractSolveAttribute end


"""
    AbstractPeekAttribute

Abstract supertype for attribute objects that will be used in order to specify what to do with the model.

"""

abstract type AbstractPeekAttribute end


# Run all tests for linar models, and solve if possible.
struct AllLinear <:AbstractPeekAttribute end