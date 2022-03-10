using SolverPeeker
using Test
using JuMP
using MathOptInterface
using SparseArrays
const MOI = MathOptInterface
using GLPK

# Start writing tests here, then divide into seperate files


@testset "main" begin

    @testset "lprep.jl" begin

        """ Test not able to conbvert to lp from non-linear constraint. """
        model0 = Model()
        @variable(model0, x >= 0)
        @variable(model0, y >= 0)
        @objective(model0, Max, 3x+5y+2)
        @constraint(model0, x^2+2y*x-y <= 180)

        @test_throws MOI.UnsupportedConstraint get_lpmodel(model0)



        """ Test getting correct A, b and c matrix up to set equality. """
        model1 = Model()
        @variable(model1, x >= 5, Int)
        @variable(model1, y <= 3)
        @variable(model1, 0 <= z <= 50)
        @objective(model1, Max, 3x+5y-2z+2)
        @constraint(model1, x+2y <= 45)
        @constraint(model1, 3z - y >= 4)
        @constraint(model1, 5x+y+2z <= 55)

        lp = get_lpmodel(model1)
        A, b = get_constraint_matrices(lp)
        c = get_objective_vector(lp)
        # From model1, the A matrix, and b vector, when constraints are made less than,
        # sould be equal, up to reshuffeling of elements, to the following:
        mat = sparse([1 2 0; 0 1 -3; 5 1 2])
        vec = [45, -4, 55]
        # Objective only gives variable indices
        obj = [3 5 -2]

        @test issetequal(A, mat)
        @test issetequal(b, vec)
        @test issetequal(c, obj)
        @test lp.objective.constant == 2

        # Add a constraint:
        @constraint(model1, 9x-7y+4-x == 3z)
        lp = get_lpmodel(model1)
        A, b = get_constraint_matrices(lp)
        # The constraint will be split in two, one less than or equal, one greater than or equal, 
        # and then the latter will be converted to a less then. 
        #All this after summing and moving all the variables to 1 side.
        mat = sparse([1 2 0; 0 1 -3; 5 1 2; 8 -7 -3; -8 7 3])
        vec = [b; -4; 4]

        @test issetequal(A, mat)
        @test issetequal(b, vec)
        # objective should remain the same.
        @test issetequal(c, obj)
        @test lp.objective.constant == 2


        """ Test getting of variables, with correct variable indices. """
        model2 = Model()
        @variable(model2, x >= 5, Int)
        @variable(model2, y <= 3)
        @variable(model2, 0 <= z <= 50)
        @variable(model2, a[1:2], Bin)
        @objective(model2, Max, 3x+5y-2z+sum(a))

        lp2 = get_lpmodel(model2)

        # How the arrays should look like up to set equality
        #greater_than = [5, NaN, 0, NaN, NaN]
        #less_than = [NaN, 3, 50, NaN, NaN]
        #integer = [1, NaN, NaN, NaN, NaN]
        #zero_one = [NaN, NaN, NaN, 1, 1]

        greater_than = get_greater_than_variables(lp2)
        less_than = get_less_than_variables(lp2)
        integer = get_integer_variables(lp2)
        zero_one = get_zero_one_variables(lp2)


        for (index, name) in lp2.var_to_name
            if (name == "x")
                @test greater_than[index.value] == 5
                @test isnan(less_than[index.value])
                @test integer[index.value] == 1
                @test isnan(zero_one[index.value])
            elseif (name == "y")
                @test isnan(greater_than[index.value])
                @test less_than[index.value] == 3
                @test isnan(integer[index.value])
                @test isnan(zero_one[index.value])
            elseif (name == "z")
                @test greater_than[index.value] == 0
                @test less_than[index.value] == 50
                @test isnan(integer[index.value])
                @test isnan(zero_one[index.value])
            elseif (name == "a[1]")
                @test isnan(greater_than[index.value])
                @test isnan(less_than[index.value])
                @test isnan(integer[index.value])
                @test zero_one[index.value] == 1
            elseif (name == "a[2]")
                @test isnan(greater_than[index.value])
                @test isnan(less_than[index.value])
                @test isnan(integer[index.value])
                @test zero_one[index.value] == 1
            else
                # No other names should exist in the model
                @test false
            end
        end

        




        
    end


    @testset "recognize.jl" begin

        """ Test difference constraints """

        # Test that only difference constraints return true
        model1 = Model()
        @variable(model1, x>=0, Int)
        @variable(model1, y, Int)
        @variable(model1, z, Int)
        @objective(model1, Min, x-2y-z)
        @constraint(model1, x-y <= 3)
        @constraint(model1, -z+y <= -5)
        @constraint(model1, x-y >= 7)
        @constraint(model1, z-x <= 2)
        @constraint(model1, x-z <= -3)


        lp1 = get_lpmodel(model1)
        A1, b1, A1t = get_constraint_matrices(lp1)
        @test recognize(A1t, b1, DifferenceConstraints()) == (true, b1)

        # Add non-normalized constraint and get true
        @constraint(model1, -4x+4z <= 8)
        lp1 = get_lpmodel(model1)
        A1, b1, A1t = get_constraint_matrices(lp1)
        result, b1 = recognize(A1t, b1, DifferenceConstraints())
        # Add 2, since 8/4 when nbormalizing is 2:
        b_true = [3,-5,-7,2,-3,2]
        
        @test result == true
        @test issetequal(b1, b_true)

        # Add a non-difference constraint, and get false
        @constraint(model1, x+z <= -3)

        lp1 = get_lpmodel(model1)
        A1, b1, A1t = get_constraint_matrices(lp1)
        @test recognize(A1t, b1, DifferenceConstraints()) == (false, b1)


        # Test that model with only one variable will return false
        model2 = Model()
        @variable(model2, x)
        @objective(model2, Max, x+2)
        @constraint(model2, x-4 <= 9)

        lp2 = get_lpmodel(model2)
        A2, b2, A2t = get_constraint_matrices(lp2)
        @test recognize(A2t, b2, DifferenceConstraints()) == (false, b2)

        # Test if no constraints return false
        model3 = Model()
        @variable(model3, x, Bin)
        @variable(model3, y, Int)
        @variable(model3, z, Int)
        @objective(model3, Max, x+y+z)

        lp3 = get_lpmodel(model3)
        A3, b3, A3t = get_constraint_matrices(lp3)
        @test recognize(A3t, b3, DifferenceConstraints()) == (false, b3)


        """ Test AllIntegerVariables """

        @test recognize(lp1, AllIntegerVariables()) == true
        @test recognize(lp2, AllIntegerVariables()) == false
        @test recognize(lp3, AllIntegerVariables()) == false

        """ Test AllIntegerConstraintBounds """

        @test recognize(b1, AllIntegerConstraintBounds()) == true
        @test recognize(b2, AllIntegerConstraintBounds()) == true

        model4 = Model()
        @variable(model4, x)
        @variable(model4, y, Int)
        @variable(model4, z, Int)
        @objective(model4, Max, x+y+z)
        @constraint(model4, x-z <= 4.6)

        lp4 = get_lpmodel(model4)
        A, b = get_constraint_matrices(lp4)
        @test recognize(b, AllIntegerConstraintBounds()) == false



    end


    @testset "solve.jl" begin

        model1 = Model()
        @variable(model1, x1, Int)
        @variable(model1, x2, Int)
        @variable(model1, x3, Int)
        @variable(model1, x4, Int)
        @variable(model1, x5, Int)
        @objective(model1, Min, x1+x2-5x3+2x4+6x5)
        @constraint(model1, x1-x2 <= 0)
        @constraint(model1, x1-x5 <= -1)
        @constraint(model1, x2-x5 <= 1)
        @constraint(model1, x3-x1 <= 5)
        @constraint(model1, x4-x1 <= 4)
        @constraint(model1, x4-x3 <= -1)
        @constraint(model1, x5-x3 <= -3)
        @constraint(model1, x5-x4 <= -3)


        lp1 = get_lpmodel(model1)
        A1, b1, A1t = get_constraint_matrices(lp1)

        # TODO: Test return status
        solve!(A1t, b1, model1, ShortestPath())


    end

    @testset "optimize.jl" begin
        # TODO: Attatch status return and test correct
        # Test feasible unbounded
        model1 = Model()
        @variable(model1, x1, Int)
        @variable(model1, x2, Int)
        @variable(model1, x3, Int)
        @variable(model1, x4, Int)
        @variable(model1, x5, Int)
        @objective(model1, Min, x1+x2-5x3+2x4+6x5)
        @constraint(model1, x1-x2 <= 0)
        @constraint(model1, x1-x5 <= -1)
        @constraint(model1, x2-x5 <= 1)
        @constraint(model1, x3-x1 <= 5)
        @constraint(model1, x4-x1 <= 4)
        @constraint(model1, x4-x3 <= -1)
        @constraint(model1, x5-x3 <= -3)
        @constraint(model1, x5-x4 <= -3)

        @test SolverPeeker.optimize!(model1) == true

        # Test infeasible
        model2 = Model()
        @variable(model2, x>=0, Int)
        @variable(model2, y, Int)
        @variable(model2, z, Int)
        @objective(model2, Min, x-2y-z)
        @constraint(model2, x-y <= 3)
        @constraint(model2, -z+y <= -5)
        @constraint(model2, x-y >= 7)
        @constraint(model2, z-x <= 2)
        @constraint(model2, x-z <= -3)
        #TODO: FIX!
        #@test SolverPeeker.optimize!(model2) == false

        # TODO: Test not recognizeable, no solver attatched
        model3 = Model()
        @variable(model3, x>=0)
        @variable(model3, y)
        @variable(model3, z)
        @objective(model3, Min, x-2y-z)
        @constraint(model3, x-y <= 3)
        @constraint(model3, -z+y <= -5)
        @constraint(model3, x-y >= 7)
        @constraint(model3, z-x <= 2)
        @constraint(model3, 2x-z <= -3)
        
        @test SolverPeeker.optimize!(model3) == false

        # TODO: Test optimizer is used
        set_optimizer(model3, GLPK.Optimizer)

        @test SolverPeeker.optimize!(model3) == false


    end



end



#include("lprep.jl")
#include("recognize.jl")