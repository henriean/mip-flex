using SolverPeeker
using Test
using JuMP
using MathOptInterface
using SparseArrays
const MOI = MathOptInterface
using GLPK
using LinearAlgebra

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
        @constraint(model2, t <= 7)
        @constraint(model2, t >= 7)
        @variable(model2, u <= 8)
        @constraint(model2, u >= 3)
        @constraint(model2, u >= 8)
        @variable(model2, v == -4)
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
        
        @test length(lp2.var_to_name) == 8


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
            elseif (name == "u")
                @test_throws KeyError lp2.greater_than[index]
                @test_throws KeyError lp2.less_than[index]
                @test_throws KeyError lp2.integer[index]
                @test lp2.equal_to[index] == 8
            elseif (name == "v")
                @test_throws KeyError lp2.greater_than[index]
                @test_throws KeyError lp2.less_than[index]
                @test_throws KeyError lp2.integer[index]
                @test lp2.equal_to[index] == -4
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

        # First an ok model.
        model4 = Model()
        @variable(model4, x >= 1.1, Int)
        @variable(model4, y >= 0)
        @objective(model4, Min, x + y)
        
        lp4 = LPRep(model4)
        @test lp4.is_consistent


        # Add non-consisten constraint
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


        # Test two different equal_to
        model4 = Model()
        @variable(model4, x == 1, Int)
        @constraint(model4, x <= 0)
        @constraint(model4, x >= 0)
        # x cannot be equal to both 1 and 0

        lp4 = LPRep(model4)
        @test !lp4.is_consistent

        # Test equal to, and less/greater than which rules that out.
        model4 = Model()
        @variable(model4, x == 1, Int)
        @constraint(model4, x <= 0)

        lp4 = LPRep(model4)
        @test !lp4.is_consistent


        model4 = Model()
        @variable(model4, x == 1, Int)
        @constraint(model4, x >= 2)

        lp4 = LPRep(model4)
        @test !lp4.is_consistent


        # Test that optimize on an AlgoModel with inconsistency updated correctly
        algoModel4 = AlgoModel(model4)
        optimize!(algoModel4)
        @test algoModel4.status == TerminationStatus(3)
        @test algoModel4.solution.primal_status == SolutionStatus(3)
        @test isnothing(algoModel4.solution.algorithm_used)


        # Test consistency_check results
        model5 = Model()
        @variable(model5, x <= 5, Int)
        @constraint(model5, x >= 5)
        @constraint(model5, x <= 6)
        @constraint(model5, x >= -3)
        # After this, x should be equal to 5, and no  matrix A

        lp5 = LPRep(model5)
        @test isempty(lp5.A)
        @test isempty(lp5.At)
        @test isempty(lp5.b)
        name_to_var = Dict(value => key for (key, value) in lp5.var_to_name)
        @test lp5.equal_to[name_to_var["x"]] == 5
        @test lp5.var_count == 1
        @test lp5.con_count == 0
        @test isempty(lp5.greater_than)
        @test isempty(lp5.less_than)

        """ Test different equal_to substitution with different layers """
        #
        @variable(model5, z == -2)
        @variable(model5, y)
        @constraint(model5, x+y+z <= 1)
        @constraint(model5, -2x+3z <= 5)
        @constraint(model5, 5y + z <= -3)

        # All rows should be removed, 
        # and y should be less than -2, and less than -1/5, so -2 is strictest
        lp5 = LPRep(model5)
        @test isempty(lp5.b)
        @test isempty(lp5.A)
        @test isempty(lp5.At)
        name_to_var = Dict(value => key for (key, value) in lp5.var_to_name)
        @test lp5.less_than[name_to_var["y"]] == -2
        @test lp5.is_consistent



        # Let us do a 2-step reduction matrix; that is, one equality 
        # results in a constraint that, together with an existing one, makes another variable
        # equal to something, and so it will substitute once more.
        # TODO: Make it 3-steps to be sure
        model6 = Model()
        @variable(model6, x <= 5, Int)
        @variable(model6, y <= 11, Int)
        @variable(model6, z == 3, Int)
        @variable(model6, a, Int)

        @constraint(model6, -y+4z <= 1)
        @constraint(model6, 3x+2y+z+2a <= 3)
        @constraint(model6, x-2y+5z+0.3a <= -4)
        @constraint(model6, 4x+9y-2z <= 0)

        lp6 = LPRep(model6)
        name_to_var = Dict(value => key for (key, value) in lp6.var_to_name)
        @test lp6.is_consistent
        @test lp6.equal_to[name_to_var["y"]] == 11
        @test !haskey(lp6.greater_than, name_to_var["y"])
        @test !haskey(lp6.less_than, name_to_var["y"])
        @test lp6.less_than[name_to_var["x"]] == -23.25
        @test !haskey(lp6.greater_than, name_to_var["x"])
        @test !haskey(lp6.equal_to, name_to_var["x"])
        @test issetequal(lp6.b, [-22, 3])
        A = sparse([1,1,2,2], [1,4,1,4], [3,2,1,0.3])
        @test issetequal(lp6.A, A)
        At = sparse([1,4,1,4], [1,1,2,2], [3,2,1,0.3])
        @test issetequal(lp6.At, At)
        @test length(lp6.integer) == 4


        # Another test with three layers
        model6 = Model()
        @variable(model6, a >= 2)
        @variable(model6, b)
        @variable(model6, c)
        @variable(model6, d)
        @variable(model6, e)
        @variable(model6, f == -2)

        @constraint(model6, a  +  b + c + d +  e     <=  1)
        @constraint(model6, a  + 2b   +   d + 2e     <=  0)
        @constraint(model6, 2a        +           f  <=  2)
        @constraint(model6,       b   +           f  <=  3)
        @constraint(model6, 2a  - b                  <= -1)

        lp6 = LPRep(model6)
        name_to_var = Dict(value => key for (key, value) in lp6.var_to_name)
        @test lp6.is_consistent
        @test lp6.equal_to[name_to_var["a"]] == 2
        @test !haskey(lp6.greater_than, name_to_var["a"])
        @test !haskey(lp6.less_than, name_to_var["a"])
        @test lp6.equal_to[name_to_var["b"]] == 5
        @test !haskey(lp6.greater_than, name_to_var["b"])
        @test !haskey(lp6.less_than, name_to_var["b"])
        @test issetequal(lp6.b, [-6, -12])
        A = sparse([1,1,1,1,2,2,2], [1,3,4,5,4,5,6], [0,1,1,1,1,2,0])
        dropzeros!(A)
        @test issetequal(lp6.A, A)
        At = sparse([1,3,4,5,4,5,6], [1,1,1,1,2,2,2], [0,1,1,1,1,2,0])
        dropzeros!(At)
        @test issetequal(lp6.At, At)


        # Test that if the matrix gets empty on the second pass, there's no errors this time either
        model6 = Model()
        @variable(model6, a >= 2)
        @variable(model6, b)
        @variable(model6, c)
        @variable(model6, d)
        @variable(model6, e)
        @variable(model6, f == -2)

        @constraint(model6, 2a        +           f  <=  2)
        @constraint(model6,       b   +           f  <=  3)
        @constraint(model6, 2a  - b                  <= -1)

        lp6 = LPRep(model6)
        name_to_var = Dict(value => key for (key, value) in lp6.var_to_name)
        @test lp6.is_consistent
        @test lp6.equal_to[name_to_var["a"]] == 2
        @test !haskey(lp6.greater_than, name_to_var["a"])
        @test !haskey(lp6.less_than, name_to_var["a"])
        @test lp6.equal_to[name_to_var["b"]] == 5
        @test !haskey(lp6.greater_than, name_to_var["b"])
        @test !haskey(lp6.less_than, name_to_var["b"])
        @test isempty(lp6.b)
        @test isempty(lp6.A)
        @test isempty(lp6.At)
    

        # Test with putting in inconsistency
        # With 0 <= -something, and contradicting inequalities

        model6 = Model()
        @variable(model6, a >= 2)
        @variable(model6, b)
        @variable(model6, c)
        @variable(model6, d)
        @variable(model6, e)
        @variable(model6, f == -2)

        @constraint(model6, a  +  b                  <=  1) # this will end up whith 0 <= -6
        @constraint(model6, a  + 2b   +   d + 2e     <=  0)
        @constraint(model6, 2a        +           f  <=  2)
        @constraint(model6,       b   +           f  <=  3)
        @constraint(model6, 2a  - b                  <= -1)

        # It should be inconsistent
        lp6 = LPRep(model6)
        @test !lp6.is_consistent

        # Now test with a integer and >= 2.9, and getting a <= 2.1
        model6 = Model()
        @variable(model6, a >= 2.9, Int)
        @variable(model6, b)
        @variable(model6, c)
        @variable(model6, d)
        @variable(model6, e)
        @variable(model6, f == -2)

        @constraint(model6, a  +  b + c + d +  e     <=  1)
        @constraint(model6, a  + 2b   +   d + 2e     <=  0)
        @constraint(model6, 2a        +           f  <=  2.1)
        @constraint(model6,       b   +           f  <=  3)
        @constraint(model6, 2a  - b                  <= -1)

        lp6 = LPRep(model6)
        @test !lp6.is_consistent


        # Test when variables are not in A
        


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
        # TODO: Test solved with regular optimizer and a vector of different elements
        # for vector, we will perhaps need to group algorithms together and return an AlgoModel,
        # or just decide that the user has to create an AlgoModel object.


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


        """ DifferenceConstraints """
        # Test feasible unbounded
        model1 = Model()
        @variable(model1, x1, Int)
        @variable(model1, x2)
        @variable(model1, x3, Int)
        @variable(model1, x4, Int)
        @variable(model1, x5, Int)
        @objective(model1, Min, x1+x2-5x3+2x4+6x5+4)
        @constraint(model1, x1-x2 <= 0)
        @constraint(model1, x1-x5 <= -1)
        @constraint(model1, x2-x5 <= -1) 
        @constraint(model1, x2-x5 <= -1.3) # Add stricter and check that this is used in the algorithm
        @constraint(model1, x2-x5 <= -0.5) # Add less strict, and check that this is not used in the algorithm
        @constraint(model1, 2x3-2x1 <= 14)
        @constraint(model1, x4-x1 <= 6)
        @constraint(model1, 2x4-2x3 <= -2)
        @constraint(model1, x5-x3 <= -3)
        @constraint(model1, x5-x4 <= -2.5)

        algoModel1 = AlgoModel(model1)
        # Test comes to a decision:
        @test SolverPeeker.optimize!(algoModel1, DifferenceConstraints()) == true
        @test algoModel1.status == TerminationStatus(4)
        # Test correct solution
        solution = algoModel1.solution
        sol = [-6, -5.3, 0, -1, -4]
        @test solution.primal_status == SolutionStatus(2)
        @test issetequal(solution.x, sol)
        @test solution.objective_value == dot(sol, [1, 1, -5, 2, 6]) + 4
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())


        # Test mapping between variable names and values. 
        name_to_var = Dict(value => key for (key, value) in algoModel1.rep.var_to_name)
        x = solution.x
        @test x[name_to_var["x1"]] == -6
        @test x[name_to_var["x2"]] == -5.3
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
        #@test SolverPeeker.optimize!(model2, DifferenceConstraints()) == true
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


        # Test on the edge of being feasible vs negative cycle
        # Negative cycle
        model5 = Model()
        @variable(model5, x1)
        @variable(model5, x2, Int)
        @variable(model5, x3)
        @variable(model5, x4)
        @variable(model5, x5 , Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -1.2)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 5.4)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(3)

        @test typeof(algoModel5.solution.algorithm_used) == typeof(DifferenceConstraints())


        # Feasible, cycle adjusted to 0
        model5 = Model()
        @variable(model5, x1)
        @variable(model5, x2, Int)
        @variable(model5, x3)
        @variable(model5, x4)
        @variable(model5, x5 , Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -1.2)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 6.2)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(4)

        solution = algoModel5.solution
        @test solution.primal_status == SolutionStatus(2)
        sol = [-6.2, -4, 0, -2, -5, 0]
        @test issetequal(solution.x, sol)

        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())


        """ Moving solution """

        # Moving solution from model5 above one, with rounding
        model5 = Model()
        @variable(model5, x1 >= 1)
        @variable(model5, x2 >= 1, Int)
        @variable(model5, x3 >= 1)
        @variable(model5, x4 >= 1)
        @variable(model5, x5 >= 1, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -1.2)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 6.2)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(4)

        solution = algoModel5.solution
        @test solution.primal_status == SolutionStatus(2)
        sol = [(8-6.2), (8-4), 8, (8-2), (8-5), 0]   # Add ceil(1 - (-6.2)) = 8
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())
        

        # Moving solution below -7.2, with rounding, and with two variables being equal_to.
        # Should subtract 8, even though there are no integers, because of implementation.
        model4 = Model()
        @variable(model4, x1 <= -7.2)
        @variable(model4, x2 <= -7.2)
        @variable(model4, x3 <= -7.2)
        @variable(model4, x4 == 23)
        @variable(model4, x5 <= -7.2)
        @variable(model4, x6 <= -7.2)
        @variable(model4, x7 == -30)
        @constraint(model4, x1-x2 <= 0)
        @constraint(model4, x1-x6 <= -1)
        @constraint(model4, x2-x6 <= 1)
        @constraint(model4, x3-x1 <= 5)
        @constraint(model4, x5-x1 <= 4)
        @constraint(model4, x5-x3 <= -1)
        @constraint(model4, x6-x3 <= -3)
        @constraint(model4, x6-x5 <= -3)

        algoModel4 = AlgoModel(model4)

        @test SolverPeeker.optimize!(algoModel4, DifferenceConstraints()) == true
        @test algoModel4.status == TerminationStatus(4)

        solution = algoModel4.solution
        @test solution.primal_status == SolutionStatus(2)
        sol = [-13, -11, -8, 23, -9, -12, -30]
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())

        # Test split feasible, move solution up
        model5 = Model()
        @variable(model5, x1 <= 6)
        @variable(model5, x2 <= 6, Int)
        @variable(model5, x3 >= 6)
        @variable(model5, x4 >= 6)
        @variable(model5, x5 <= 6, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -1.2)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 6.2)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(4)

        solution = algoModel5.solution
        @test solution.primal_status == SolutionStatus(2)
        sol = [(8-6.2), (8-4), 8, (8-2), (8-5), 0]    # add ceil(6 - (-2)) = 8, and is not too much for lesser set, so ok.
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())

        # Test split feasible, move solution down
        model5 = Model()
        @variable(model5, x1 <= -10)
        @variable(model5, x2 <= -10, Int)
        @variable(model5, x3 >= -10)
        @variable(model5, x4 >= -10)
        @variable(model5, x5 <= -10, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -1.2)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 6.2)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(4)

        solution = algoModel5.solution
        @test solution.primal_status == SolutionStatus(2)
        sol = [(-6.2-6), (-4-6), -6, (-2-6), (-5-6), 0]    # substract ceil(-4 - (-10)) = 6
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())


        # Test split where not feasible
        model5 = Model()
        @variable(model5, x1 <= 0)
        @variable(model5, x2 >= 0, Int)
        @variable(model5, x3 <= 0)
        @variable(model5, x4 >= 0)
        @variable(model5, x5 >= 0, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -1.2)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 6.2)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(3)
        @test typeof(algoModel5.solution.algorithm_used) == typeof(DifferenceConstraints())

        

        # Test split not feasible when would want to move less than an integer up.
        model5 = Model()
        @variable(model5, x1 <= 2.4)
        @variable(model5, x2 >= 2.4, Int)
        @variable(model5, x3 >= 2.4)
        @variable(model5, x4 >= 2.4)
        @variable(model5, x5 >= 2.4, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -0.3)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 5.3)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(3)
        @test typeof(algoModel5.solution.algorithm_used) == typeof(DifferenceConstraints())

        # But ok when it adds to an integer number
        model5 = Model()
        @variable(model5, x1 <= 2.7)
        @variable(model5, x2 >= 2.7, Int)
        @variable(model5, x3 >= 2.7)
        @variable(model5, x4 >= 2.7)
        @variable(model5, x5 >= 2.7, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -0.3)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 5.3)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(4)

        solution = algoModel5.solution
        @test solution.primal_status == SolutionStatus(2)
        # add ceil(2.7 - (-5)) = 8. Ok, because then x1 meets the bound exactly
        sol = [(-5.3+8), (-4+8), 8, (-1.3+8), (-5+8), 0]
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())

        # Same for moving down, infeasible
        model5 = Model()
        @variable(model5, x1 <= -7.4)
        @variable(model5, x2 >= -7.4, Int)
        @variable(model5, x3 >= -7.4)
        @variable(model5, x4 >= -7.4)
        @variable(model5, x5 >= -7.4, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -0.3)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 5.3)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(3)
        @test typeof(algoModel5.solution.algorithm_used) == typeof(DifferenceConstraints())

        
        # Moving down, feasible
        model5 = Model()
        @variable(model5, x1 <= -7.3)
        @variable(model5, x2 >=  -7.3, Int)
        @variable(model5, x3 >=  -7.3)
        @variable(model5, x4 >=  -7.3)
        @variable(model5, x5 >=  -7.3, Int)
        @variable(model5, x6 == 0)
        @constraint(model5, x1-x2 <= 0)
        @constraint(model5, x1-x5 <= -0.3)
        @constraint(model5, x2-x5 <= 1)
        @constraint(model5, x3-x1 <= 5.3)
        @constraint(model5, x4-x1 <= 4.2)
        @constraint(model5, x4-x3 <= -1.3)
        @constraint(model5, x5-x3 <= -3)
        @constraint(model5, x5-x4 <= -3)

        algoModel5 = AlgoModel(model5)

        @test SolverPeeker.optimize!(algoModel5, DifferenceConstraints()) == true
        @test algoModel5.status == TerminationStatus(4)

        solution = algoModel5.solution
        @test solution.primal_status == SolutionStatus(2)
        # subtract ceil(-5.3 - (-7.3)) = ceil(2.0) = 2. Ok, because then x5 meets doesn't supass -7.3
        sol = [(-5.3-2), (-4-2), -2, (-1.3-2), (-5-2), 0]
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())


        # Test infeasible with integer, but no integer, don't care
        model6 = Model()
        @variable(model6, x1 >= 1.5, Int)
        @variable(model6, x2 <= 1.5)
        @variable(model6, x3 >=  1.5)
        @constraint(model6, x1-x3 <= -1.0)
        @constraint(model6, x2-x3 <= -1.1)

        algoModel6 = AlgoModel(model6)

        @test SolverPeeker.optimize!(algoModel6, DifferenceConstraints()) == true
        @test algoModel6.status == TerminationStatus(3)
        @test typeof(algoModel6.solution.algorithm_used) == typeof(DifferenceConstraints())


        # Remove integer, and see that it works
        model6 = Model()
        @variable(model6, x1 >= 1.5)
        @variable(model6, x2 <= 1.5)
        @variable(model6, x3 >=  1.5)
        @constraint(model6, x1-x3 <= -1.0)
        @constraint(model6, x2-x3 <= -1.1)

        algoModel6 = AlgoModel(model6)

        @test SolverPeeker.optimize!(algoModel6, DifferenceConstraints()) == true
        @test algoModel6.status == TerminationStatus(4)

        solution = algoModel6.solution
        @test solution.primal_status == SolutionStatus(2)
        # add 1.5 - (-1) = 2.5
        sol = [-1.0 + 2.5, -1.1 + 2.5, 0+2.5]
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())


        # Test same with moving solution down
        model6 = Model()
        @variable(model6, x1 >= -1.5, Int)
        @variable(model6, x2 <= -1.5)
        @variable(model6, x3 >=  -1.5)
        @constraint(model6, x1-x3 <= -1.0)
        @constraint(model6, x2-x3 <= -1.1)

        algoModel6 = AlgoModel(model6)

        @test SolverPeeker.optimize!(algoModel6, DifferenceConstraints()) == true
        @test algoModel6.status == TerminationStatus(3)
        @test typeof(algoModel6.solution.algorithm_used) == typeof(DifferenceConstraints())

        # Remove integer, and see that it works
        model6 = Model()
        @variable(model6, x1 >= -1.6)
        @variable(model6, x2 <= -1.6)
        @variable(model6, x3 >=  -1.6)
        @constraint(model6, x1-x3 <= -1.0)
        @constraint(model6, x2-x3 <= -1.1)

        algoModel6 = AlgoModel(model6)

        @test SolverPeeker.optimize!(algoModel6, DifferenceConstraints()) == true
        @test algoModel6.status == TerminationStatus(4)

        solution = algoModel6.solution
        @test solution.primal_status == SolutionStatus(2)
        # substract -1.2 - (-1.7) = 0.5
        sol = [-1.0 - 0.5, -1.1 - 0.5, 0 - 0.5]
        @test issetequal(solution.x, sol)
        @test typeof(solution.algorithm_used) == typeof(DifferenceConstraints())


        # Test different bounds, and thus not recoginizable

        model6 = Model()
        @variable(model6, x1 >= 1.5)
        @variable(model6, x2 <= -1.5)
        @variable(model6, x3 >=  1.5)
        @constraint(model6, x1-x3 <= -1.0)
        @constraint(model6, x2-x3 <= -1.1)

        algoModel6 = AlgoModel(model6)

        @test SolverPeeker.optimize!(algoModel6, DifferenceConstraints()) == false
        @test algoModel6.status == TerminationStatus(1)
        @test typeof(algoModel6.solution.algorithm_used) == Nothing



    end



end