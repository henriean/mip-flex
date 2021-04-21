using JuMP
using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

export lprep

# Recuire the model to have only less than constraints.
# May extend to vector formulation or equalto, but not currently.
# Single variable constraints cannot be controlled by this:
# Can be EqualTo, GreaterThan, LessThan, Interval, Integer, ZeroOne, Semicontionous or Semiinteger.
MOI.Utilities.@model(
    LPModel,                            # model_name
    (),                                 # scalar_sets
    (MOI.LessThan,),                    # typed_scalar_sets
    (),                                 # vector_sets
    (),                                 # typed_vector_sets
    (),                                 # scalar_functions
    (MOI.ScalarAffineFunction,),        # typed_scalar_functions
    (),                                 # vector_functions
    (),                                 # typed_vector_functions
    false)                              # is_optimizer, Subtype of MathOptInterface.ModelLike


# Only MOI.GreaterThan{T}, MOI.ZeroOne and MOI.Integer currently allowed for constraints 
function MOI.supports_constraint(
    ::LPModel{T}, 
    ::Type{MOI.SingleVariable},
    ::Type{<:Union{MOI.EqualTo{T}, MOI.LessThan{T}, MOI.Interval{T}, MOI.Semicontinuous{T}, MOI.Semiinteger{T}}}) where T
    return false
end

# If not allowing free variables (?)
# function MOI.supports_constraint(::LPModel{T}, ::Type{VectorOfVariables}, ::Type{Reals})
#    return false
#end


# If on the right form, return it
function lprep(model::LPModel{T}) where T
    return model # Check if needed wrap model into LP-struct with other objects. Then possiby define base operations on it?
end


# Else bridge:
#TODO: Make sure and test that the mapping between old and new variables is ok.
function lprep(model::MOI.ModelLike, T::Type = Float64)
    _model = LPModel{T}()

    # Specify that any bridge can be used when using copy_to:
    
    #If all bridges:
    bridged_model = MOI.Bridges.full_bridge_optimizer(_model, Float64)

    """
    # From polyhedra
    bridged_model = MOI.Bridges.LazyBridgeOptimizer(_model)
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.GreaterToLessBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.LessToGreaterBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.NonnegToNonposBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.NonposToNonnegBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.ScalarizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.VectorizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.ScalarFunctionizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.VectorFunctionizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.SplitIntervalBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.NormInfinityBridge{T})
    """

    # Do the actual bridging into _model:
    MOI.copy_to(bridged_model, model)

    return lprep(_model)
end


# If getting JuMP.Model, use the backend MOI.ModelLike:
#TODO: Maybe do something in order to convert back to a JuMP model?
lprep(model::JuMP.Model) = lprep(backend(model))

