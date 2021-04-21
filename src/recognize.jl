"""
 recognize
 """


"""
Functions for recognizing properties of the a LPModel

"""

export recognize

function recognize(::LPModel, ::AbstractRecognizeAttribute) <: Bool end

function recognize(model::LPModel, ::ObjectiveIsConstant)
    obj = objective_function(model, objective_function_type(model))
    
    return (Base.isempty(obj.terms) || all(x->x==0, values(obj.terms)))
end









# Don't need this at the moment, just keeping it until sure.
"""
#----------------------------------------------#

# Will need help with this. 1. Types are hard to get. 2. Does not seem like non-linear models are building?
# May just let the function take in type of objectibve, constraints and set types, 
# So that we utilize mjultiple dispatch (was a bit difficult!)

function recognize(model::AbstractModel, ::ObjectiveIsLinear)
    #show(objective_function_type(model))
    #print("\n")
    show(objective_function(model, objective_function_type(model)))
    print("\n")
    #print("\n")
    return objective_function_type(model) <: GenericAffExpr
end

function recognize(model::AbstractModel, ::ConstraintsAreLinear)
    for (F, S) in list_of_constraint_types(model)
        #show(F)
        #print("\n")
        #show(F)
        #print("\n")
        if !(F <: Union{GenericAffExpr, VariableRef})
            return false
        end
    end
    return true
end

#----------------------------------------------#
"""


