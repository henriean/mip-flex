using SolverPeeker
using Test
using JuMP
using MathOptInterface
const MOI = MathOptInterface
using Clp


# Model with linear constraints and objective
#model1 = Model()
#@variable(model1, x >= 5, Int)
#@variable(model1, y <= 5)
#@variable(model1, 0 <= z <= 50)
#@objective(model1, Max, 3x+5y-2z+2)
#@constraint(model1, x+2y <= 45)
#@constraint(model1, z - y >= 4)
#@constraint(model1, 0 <= 2z <= 7)
#@constraint(model1, x+y+2z <= 55)

function fill_small_test_model!(model::JuMP.Model)
    # The model does not need to make sense, just use many different features.
    @variable(model, a[1:5] >= 0)
    @variable(model, b[6:10])
    @variable(model, 10 <= c[1:3] <= 20)
    @constraint(model, con1, sum(a) + sum(b) <= 5)
    @constraint(model, con2, sum(b) >= 3)
    @constraint(model, con3, sum(c[1:2]) >= 5)
    @objective(model, Max, sum(a) - sum(b) + sum(c))
    return model
end



@testset "interface.jl" begin
    model = Model(Clp.Optimizer)
    @variable(model, x >= 0)
    @variable(model, y >= 0)
    @constraint(model, con1, x+y <= 5)
    @objective(model, Max, x-y)
    set_optimizer_attributes(model, "LogLevel" => 1, "PrimalTolerance" => 1e-7)
    optimize!(model)
    solution_summary(model; verbose=true)
    
end