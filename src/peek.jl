"""
peek
"""

function peek!(::Model, ::AbstractPeekAttribute) <: Nothing end

function peek!(model::Model, ::AllLinear)
    if !(recognize(model, ObjectiveIsLinear) && recognize(model, ConstraintsAreLinear()))
        throw(DomainError(model, "this model contains non-linear expressions"))
    end

    if recognize(model, ObjectiveIsConstant)
        solve!(model, ConstantObjective())
    end
end

