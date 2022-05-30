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

        """ Test LPRep with wrong variable constraints (ex Semiinteger). """
        model01 = Model()
        @variable(model01, x <= 0)
        @variable(model01, y <= 0)
        @constraint(model01, y in MOI.Semiinteger(1, 5))    # Semiinteger
        @objective(model01, Max, x+5y)
        
        @test_throws TypeError get_lpmodel(model01)


        """ Test objective vector will be zero in LPRep if no objective is set """
        model02 = Model()
        @variable(model02, x <= 0)
        @variable(model02, y <= 0)
        @constraint(model02, y + x <= 6)

        @test issetequal(LPRep(model02).c, [0, 0])


        """ Test getting correct A, b and c matrix up to set equality. """
        model1 = Model()
        @variable(model1, x >= 5, Int)
        @variable(model1, y <= 3)
        @variable(model1, 0 <= z <= 50)
        @objective(model1, Max, 3x+5y-2z+2)
        @constraint(model1, x+2y <= 45)
        @constraint(model1, 3z - y >= 4)
        @constraint(model1, 5x+y+2z == 55)

        lp = LPRep(model1)
        # From model1, the A matrix, and b vector, when constraints are made less than,
        # sould be equal, up to reshuffeling of elements, to the following:
        mat = sparse([1 2 0; 0 1 -3; 5 1 2; -5 -1 -2])
        vec = [45, -4, 55, -55]
        # Objective only gives variable indices
        obj = [3 5 -2]

        @test issetequal(lp.A, mat)
        @test issetequal(lp.b, vec)
        @test issetequal(lp.c, obj)
        @test lp.obj_constant == 2

        # Add a constraint:
        @constraint(model1, 9x-7y+4-x == 3z)
        lp = LPRep(model1)
        # The constraint will be split in two, one less than or equal, one greater than or equal, 
        # and then the latter will be converted to a less than. 
        #All this after summing and moving all the variables to 1 side.
        mat = sparse([1 2 0; 0 1 -3; 5 1 2; -5 -1 -2; 8 -7 -3; -8 7 3])
        vec = [vec; -4; 4]

        @test issetequal(lp.A, mat)
        @test issetequal(lp.b, vec)
        # objective should remain the same.
        @test issetequal(lp.c, obj)
        @test lp.obj_constant == 2


        """ Test getting of variables, with correct variable indices. """
        model2 = Model()
        @variable(model2, x >= 5, Int)
        @variable(model2, y <= 3)
        @variable(model2, 0 <= z <= 50)
        @variable(model2, t == 7)
        @variable(model2, a[1:2], Bin)
        @objective(model2, Max, t+3x+5y-2z+sum(a))

        lp2 = LPRep(model2)

        # How the arrays should look like up to set equality
        # This takes into account that MOI.ZeroOne now is stored as 
        # >= 0, <= 1, and in Z.
        #greater_than = [5, NaN, 0, 0, 0]
        #less_than = [NaN, 3, 50, 1, 1]
        #integer = [true, false, false, true, true]
        #zero_one = [NaN, NaN, NaN, 1, 1]
        
        @test length(lp2.var_to_name) == 6


        for (index, name) in lp2.var_to_name
            if (name == "x")
                @test lp2.greater_than[index] == 5
                @test_throws KeyError lp2.less_than[index]
                @test lp2.integer[index]
                @test_throws KeyError lp2.equal_to[index]
                #@test isnan(lp2.zero_one[index.value])
            elseif (name == "y")
                @test_throws KeyError lp2.greater_than[index]
                @test lp2.less_than[index] == 3
                @test_throws KeyError lp2.integer[index]
                @test_throws KeyError lp2.equal_to[index]
                #@test isnan(lp2.zero_one[index.value])
            elseif (name == "z")
                @test lp2.greater_than[index] == 0
                @test lp2.less_than[index] == 50
                @test_throws KeyError lp2.integer[index]
                @test_throws KeyError lp2.equal_to[index]
                #@test isnan(lp2.zero_one[index.value])
            elseif (name == "a[1]")
                @test lp2.greater_than[index] == 0
                @test lp2.less_than[index] == 1
                @test lp2.integer[index]
                @test_throws KeyError lp2.equal_to[index]
                #@test lp2.zero_one[index.value] == 1
            elseif (name == "a[2]")
                @test lp2.greater_than[index] == 0
                @test lp2.less_than[index] == 1
                @test lp2.integer[index]
                @test_throws KeyError lp2.equal_to[index]
                #@test lp2.zero_one[index.value] == 1
            elseif (name == "t")
                @test_throws KeyError lp2.greater_than[index]
                @test_throws KeyError lp2.less_than[index]
                @test_throws KeyError lp2.integer[index]
                @test lp2.equal_to[index] == 7
            else
                @test false
            end
        end


        
        """ Test variable constraints from normal constraints, nbormalization, and correct bounds. """
        model3 = Model()
        @variable(model3, x >= 1, Int)
        @variable(model3, y >= 0)
        @objective(model3, Min, x + y)
        @constraint(model3, 2x >= 6)
        @constraint(model3, 3y >= -9)

        lp3 = LPRep(model3)

        # No constraints into A
        @test lp3.A == sparse([],[],[])
        # Updated bound on x, but not y
        for (index, name) in lp3.var_to_name
            if name == "x"
                @test lp3.greater_than[index] == 3
            elseif name == "y"
                @test lp3.greater_than[index] == 0
            else 
                @test false
            end
        end


        """ Test infeasible constraints. """
        model4 = Model()
        @variable(model4, x >= 1.1, Int)
        @variable(model4, y >= 0)
        @objective(model4, Min, x + y)
        @constraint(model4, x <= 1.9 )  # No legal integer in interval for x

        lp4 = LPRep(model4)
        @test !lp4.is_consistent

        model4 = Model()
        @variable(model4, x >= 1.1, Int)
        @variable(model4, y >= 0)
        @objective(model4, Min, x + y)
        @constraint(model4, y <= -1 )   # No legal set of values for y

        lp4 = LPRep(model4)
        @test !lp4.is_consistent


        # Test -5 
        model4 = Model()
        @variable(model4, x >= 1.1, Int)
        @variable(model4, y >= 0)
        @objective(model4, Min, x + y)
        @constraint(model4, 0y <= -5)   # Can never be true.


        lp4 = LPRep(model4)
        @test !lp4.is_consistent
        
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


        algoModel1 =AlgoModel(model1, DifferenceConstraints())
        @test size(algoModel1.algorithms) === (1,)
        @test typeof(algoModel1.algorithms[1]) == DifferenceConstraints
        @test recognize(algoModel1, DifferenceConstraints()) == (true, algoModel1.rep.b)

        # Add non-normalized constraint and get true
        @constraint(model1, -4x+4z <= 8)

        algoModel1 =AlgoModel(model1)   # Just using different instantiation
        @test algoModel1.algorithms === nothing
        
        result, b1 = recognize(algoModel1, DifferenceConstraints())
        # Add 2, since 8/4 when nbormalizing is 2:
        b_true = [3,-5,-7,2,-3,2]
        @test result == true
        @test issetequal(b1, b_true)

        # Add a non-difference constraint, and get false
        @constraint(model1, x+z <= -3)

        algoModel1 =AlgoModel(model1, DifferenceConstraints())
        @test recognize(algoModel1, DifferenceConstraints()) === (false, nothing)


        # Test that model with only one variable will return false
        model2 = Model()
        @variable(model2, x)
        @objective(model2, Max, x+2)
        @constraint(model2, x-4 <= 9)

        algoModel2 = AlgoModel(model2)
        @test recognize(algoModel2, DifferenceConstraints()) === (false, nothing)

        # Test if no constraints return false
        model3 = Model()
        @variable(model3, x)
        @variable(model3, y, Int)
        @variable(model3, z, Int)
        @objective(model3, Max, x+y+z)

        algoModel3 = AlgoModel(model3)
        @test recognize(algoModel3, DifferenceConstraints()) === (false, nothing)



        """ Test AllIntegerVariables """

        #@test recognize(lp1, AllIntegerVariables()) == true
        #@test recognize(lp2, AllIntegerVariables()) == false
        #@test recognize(lp3, AllIntegerVariables()) == false

        """ Test AllIntegerConstraintBounds """

        #@test recognize(b1, AllIntegerConstraintBounds()) == true
        #@test recognize(b2, AllIntegerConstraintBounds()) == true

        #model4 = Model()
        #@variable(model4, x)
        #@variable(model4, y, Int)
        #@variable(model4, z, Int)
        #@objective(model4, Max, x+y+z)
        #@constraint(model4, x-z <= 4.6)

        #lp4 = get_lpmodel(model4)
        #print("\n")
        #print("\n")
        #print(lp4)
        #print("\n")
        #print("\n")
        #A, b = get_constraint_matrices(lp4)
        #@test recognize(b, AllIntegerConstraintBounds()) == false



    end

    @testset "interface.jl" begin
        # TODO: Test solved with regular optimizer



        model1 = Model()
        @variable(model1, x)
        @variable(model1, y, Int)
        @variable(model1, z, Int)
        @constraint(model1, 3x+y <= 5)
        @objective(model1, Max, x+y+z)


        # Test no representation set, or no algorithm set.
        algoModel1 = AlgoModel(model1)
        @test !are_algorithms_set(algoModel1)
        SolverPeeker.optimize!(algoModel1)
        @test algoModel1.status == TerminationStatus(0)
        @test !got_answer(algoModel1)

        # Same if optimize together with model
        SolverPeeker.optimize!(model1, algoModel1)
        @test algoModel1.status == TerminationStatus(0)
        @test !got_answer(algoModel1)

        # Add algorithm and check termination, unknown. 
        # Also check no double addition of algorithm
        add_algorithm!(algoModel1, DifferenceConstraints())
        add_algorithms!(algoModel1, [DifferenceConstraints()])
        @test algoModel1.algorithms == [DifferenceConstraints()]
        @test are_algorithms_set(algoModel1)
        SolverPeeker.optimize!(algoModel1)
        @test algoModel1.status == TerminationStatus(1)
        @test !got_answer(algoModel1)
    
        
        # Nothing happens if no model is set either
        algoModel2 = AlgoModel(DifferenceConstraints())
        @test !is_rep_set(algoModel2)
        SolverPeeker.optimize!(algoModel2)
        @test algoModel2.status == TerminationStatus(0)
        @test !got_answer(algoModel2)

        set_rep!(algoModel2, model1)
        @test is_rep_set(algoModel2)
        SolverPeeker.optimize!(algoModel2)
        @test algoModel1.status == TerminationStatus(1)
        @test !got_answer(algoModel1)


    end


    @testset "optimize.jl" begin
        # Test feasible unbounded
        model1 = Model()
        @variable(model1, x1, Int)
        @variable(model1, x2, Int)
        @variable(model1, x3, Int)
        @variable(model1, x4, Int)
        @variable(model1, x5, Int)
        @objective(model1, Min, x1+x2-5x3+2x4+6x5+4)
        @constraint(model1, x1-x2 <= 0)
        @constraint(model1, x1-x5 <= -1)
        @constraint(model1, x2-x5 <= 1)
        @constraint(model1, x3-x1 <= 5)
        @constraint(model1, x4-x1 <= 4)
        @constraint(model1, x4-x3 <= -1)
        @constraint(model1, x5-x3 <= -3)
        @constraint(model1, x5-x4 <= -3)

        algoModel1 = AlgoModel(model1)
        # Test comes to a decision:
        @test SolverPeeker.optimize!(algoModel1, DifferenceConstraints()) == true
        @test algoModel1.status == TerminationStatus(4)
        # Test correct solution
        solution = algoModel1.solution
        sol = [-5, -3, 0, -1, -4]
        @test solution.primal_status == SolutionStatus(2)
        @test issetequal(solution.x, sol)
        @test solution.objective_value == -30
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())

        # Test mapping between variable names and values. 
        name_to_var = Dict(value => key for (key, value) in algoModel1.rep.var_to_name)
        x = solution.x
        @test x[name_to_var["x1"]] == -5
        @test x[name_to_var["x2"]] == -3
        @test x[name_to_var["x3"]] == 0
        @test x[name_to_var["x4"]] == -1
        @test x[name_to_var["x5"]] == -4


        # Test infeasible
        model2 = Model()
        @variable(model2, x>=0, Int)
        @variable(model2, y, Int)
        @variable(model2, z, Int)
        @objective(model2, Min, x-2y-z)
        @constraint(model2, x-y <= 3)
        @constraint(model2, -z+y >= -5)
        @constraint(model2, x-y >= 7)
        @constraint(model2, z-x <= 2)
        @constraint(model2, x-z <= -3)

        algoModel2 = AlgoModel(model2)

        # Test comes to a decision:
        @test SolverPeeker.optimize!(algoModel2, DifferenceConstraints()) == true
        @test algoModel2.status == TerminationStatus(3)

        solution = algoModel2.solution
        @test solution.primal_status == SolutionStatus(3)
        @test isnothing(solution.x)
        @test isnothing(solution.objective_value)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())


        # Test not recognizeable
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
        @constraint(model3, z >= 0)

        algoModel3 = AlgoModel(model3)

        @test SolverPeeker.optimize!(algoModel3, DifferenceConstraints()) == false
        @test algoModel3.status == TerminationStatus(1)

        solution = algoModel3.solution
        @test solution.primal_status == SolutionStatus(0)
        @test isnothing(solution.x)
        @test isnothing(solution.objective_value)
        @test isnothing(solution.algorithm_used)

        #TODO: Test big problem?

    end



end