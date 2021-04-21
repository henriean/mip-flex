using SolverPeeker
using Test
using JuMP

"""
Initiate some models
"""
    
# Model with linear constraints and objective
model1 = Model()
@variable(model1, x >= 0, Int)
@variable(model1, y <= 5)
@variable(model1, z)
@objective(model1, Max, 3x+5y-2z)
@constraint(model1, x+2y <= 45)
@constraint(model1, z - y >= 4)
@constraint(model1, 0<= 2z <= 7)

# Model with nothging specified. Should have objective 0.
model2 = Model()

# Objective registered as 0 in model(?)
model_nl = Model()
@variable(model_nl, x, start = 0.0)
@variable(model_nl, y, start = 0.0)
@NLobjective(model_nl, Min, (1 - x)^2 + 100 * (y - x^2)^2)
@constraint(model_nl, x + y == 10)
#@NLobjective(model_nl, Min, sin(x))




@testset "recognize" begin


    """
    Constant objective test
    """

    @test recognize(model1, ObjectiveIsConstant()) == false
    
    @test recognize(model2, ObjectiveIsConstant()) == true

    # Add variable and constant objective. Should still be true:
    @variable(model2, x)
    @objective(model2, Min, 5)
    @test recognize(model2, ObjectiveIsConstant()) == true

    
    """
    Linear Objective Test
    """

    """
    @test recognize(model1, ObjectiveIsLinear()) == true
    @test recognize(model2, ObjectiveIsLinear()) == true
    #@test recognize(model_nl, ObjectiveIsLinear()) == false
    """


    """
    Linear Constraints Test
    """

    """
    @test recognize(model1, ConstraintsAreLinear()) == true
    @test recognize(model2, ConstraintsAreLinear()) == true
    #@test recognize(model_nl, ConstraintsAreLinear()) == false


   
    list = list_of_constraint_types(model1)
    #show(list)
    show(list)
    print("\n")
    show(list <: Tuple{DataType<:Union{GenericAffExpr, VariableRef}, Any})
    print("\n")
    print("\n")
    #print("\n")
    #a_c = []
    for (F, S) in list
        #show(F)
        #print("\n")
        #show(S)
        #print("\n")
        #print("\n")
        #a_c = append!(a_c, all_constraints(model1, F, S))
        #show(a_c)
        #print("\n")
        #show(typeof(a_c))
        #print("\n")
        #print("\n")
        #for cref in a_c
            #show(typeof(cref))
            #print("\n")
            #print("\n")
            #c_obj = constraint_object(cref)
            #show(c_obj.set)
            #c_obj.func
            #if !(typeof(c_obj.func) <: Union{GenericAffExpr, VariableRef})
            #    return false
            # end
        #end
    end


    #for cref in all_constraints(model, F, S)
    #    c_obj = constraint_object(cref)
        #c_obj.set
    #    if !(typeof(c_obj.func) <: Union{GenericAffExpr, VariableRef})
    #        return false
    #    end
    #end
    """

    
end