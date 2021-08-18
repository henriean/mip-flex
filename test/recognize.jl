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
    """
    @test recognize(model1, ObjectiveIsConstant()) == false
    
    @test recognize(model2, ObjectiveIsConstant()) == true

    # Add variable and constant objective. Should still be true:
    @variable(model2, x)
    @objective(model2, Min, 5)
    @test recognize(model2, ObjectiveIsConstant()) == true
    """

    
   
end