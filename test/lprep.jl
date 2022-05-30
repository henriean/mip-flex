using SolverPeeker
using Test
using JuMP
using MathOptInterface
const MOI = MathOptInterface


# Model with linear constraints and objective
model1 = Model()
@variable(model1, x >= 5, Int)
@variable(model1, y <= 5)
@variable(model1, 0 <= z <= 50)
@objective(model1, Max, 3x+5y-2z+2)
@constraint(model1, x+2y <= 45)
@constraint(model1, z - y >= 4)
@constraint(model1, 0 <= 2z <= 7)
@constraint(model1, x+y+2z <= 55)

function fill_small_test_model!(model::JuMP.Model)
    # The model does not need to make sense, just use many different features.
    @variable(model, a[1:5] >= 0, Int)
    @variable(model, b[6:10], Bin)
    @variable(model, c[1:3] == 0)
    @variable(model, 10 <= d[1:3] <= 20)
    @constraint(model, con1, sum(a) + sum(b) <= 5)
    @constraint(model, con2, sum(b) >= 3)
    @constraint(model, con3, sum(d[1:2]) >= 5)
    @constraint(model, con4, sum(d) <= (sum(c) + 10))
    @objective(model, Max, sum(a) - sum(b) + sum(d))
    return model
end



@testset "lprep.jl" begin
    #peeker = Peeker(model1)
    #Base.show(Base.stdout, peeker)
    #show(isa(peeker, JuMP.AbstractModel))
end