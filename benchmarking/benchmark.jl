using JuMP, MathOptInterface, MipFlex
const MOI = MathOptInterface
using Cbc, HiGHS, GLPK, SCIP, BenchmarkTools
using PlotlyJS
using Pkg, Coverage

# Run in terminal to gain plot
# NB HiGHS prints objective value!!

# For time on difference constraints tests
global diffc_set = "benchmarking/difference_constraints_problems/"
BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000

# Create suite
global suite = BenchmarkGroup()
suite["HiGHS"] =  BenchmarkGroup()
suite["Cbc"] =  BenchmarkGroup()
suite["SCIP"] =  BenchmarkGroup()
suite["AlgoModel"] =  BenchmarkGroup()

global i = 0

for file in readdir(diffc_set)
    if file == ".DS_Store"
        continue
    end
    global i += 1

    file_model = MOI.FileFormats.Model(format = MOI.FileFormats.FORMAT_MPS)
    MOI.read_from_file(file_model, "$diffc_set$file")

    global model = Model()
    MOI.copy_to(model, file_model)
    global model1 = copy(model)
    global model2 = copy(model)
    global model3 = copy(model)

    set_optimizer(model1, HiGHS.Optimizer)
    set_silent(model1)
    global suite["HiGHS"][i] = @benchmarkable optimize!($model1)
    

    set_optimizer(model2, Cbc.Optimizer)
    set_silent(model2)
    global suite["Cbc"][i] = @benchmarkable optimize!($model2)


    set_optimizer(model3, SCIP.Optimizer)
    set_silent(model3)
    global suite["SCIP"][i] = @benchmarkable optimize!($model3)


    global algoModel = AlgoModel(model, DifferenceConstraints())
    global suite["AlgoModel"][i] = @benchmarkable optimize!($algoModel)


    # small problems. Mean time for all. Report if problem on some
end

points = [j for j in 1:i]

tuned = tune!(suite)
println("Samples:")
println(tuned.data["HiGHS"][1].params.samples)

results = run(suite)

HiGHS_times = [mean(value).time for (trial, value) in results["HiGHS"]]./10^3
Cbc_times = [mean(value).time  for (trial, value) in results["Cbc"]]./10^3
SCIP_times = [mean(value).time  for (trial, value) in results["SCIP"]]./10^3
AlgoModel_times = [mean(value).time  for (trial, value) in results["AlgoModel"]]./10^3

line1 = scatter(x=points, y=HiGHS_times, mode="lines+markers", name="HiGHS")
line2 = scatter(x=points, y=Cbc_times, mode="lines+markers", name="Cbc")
line3 = scatter(x=points, y=SCIP_times, mode="lines+markers", name="SCIP")
line4 = scatter(x=points, y=AlgoModel_times, mode="lines+markers", name="AlgoModel")

display(plot([line1, line2, line3, line4]))
sleep(60)



#####################################################################################


# For time on difference constraints tests
global infeasible_subproblem_diffc = "benchmarking/difference_constraints_subset_infeasible/"
BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000

# Create suite
global suite2 = BenchmarkGroup()
suite2["HiGHS"] =  BenchmarkGroup()
suite2["Cbc"] =  BenchmarkGroup()
suite2["SCIP"] =  BenchmarkGroup()
suite2["AlgoModel"] =  BenchmarkGroup()

global i = 0

for file in readdir(infeasible_subproblem_diffc)

    if file == ".DS_Store"
        continue
    end
    global i += 1

    file_model = MOI.FileFormats.Model(format = MOI.FileFormats.FORMAT_MPS)
    MOI.read_from_file(file_model, "$infeasible_subproblem_diffc$file")

    global model = Model()
    MOI.copy_to(model, file_model)
    global model1 = copy(model)
    global model2 = copy(model)
    global model3 = copy(model)

    set_optimizer(model1, HiGHS.Optimizer)
    set_silent(model1)
    global suite2["HiGHS"][i] = @benchmarkable optimize!($model1)
    

    set_optimizer(model2, Cbc.Optimizer)
    set_silent(model2)
    global suite2["Cbc"][i] = @benchmarkable optimize!($model2)


    set_optimizer(model3, SCIP.Optimizer)
    set_silent(model3)
    global suite2["SCIP"][i] = @benchmarkable optimize!($model3)


    global algoModel = AlgoModel(model, DifferenceConstraints())
    global suite2["AlgoModel"][i] = @benchmarkable optimize!($algoModel)


    # small problems. Mean time for all. Report if problem on some
end

points2 = [j for j in 1:i]

tuned2 = tune!(suite2)
println("Samples:")
println(tuned2.data["HiGHS"][1].params.samples)

results2 = run(suite2)

HiGHS_times2 = [mean(value).time for (trial, value) in results2["HiGHS"]]./10^3
Cbc_times2 = [mean(value).time  for (trial, value) in results2["Cbc"]]./10^3
SCIP_times2 = [mean(value).time  for (trial, value) in results2["SCIP"]]./10^3
AlgoModel_times2 = [mean(value).time  for (trial, value) in results2["AlgoModel"]]./10^3

line12 = scatter(x=points2, y=HiGHS_times2, mode="lines+markers", name="HiGHS")
line22 = scatter(x=points2, y=Cbc_times2, mode="lines+markers", name="Cbc")
line32 = scatter(x=points2, y=SCIP_times2, mode="lines+markers", name="SCIP")
line42 = scatter(x=points2, y=AlgoModel_times2, mode="lines+markers", name="AlgoModel")

display(plot([line12, line22, line32, line42]))
sleep(60)


#####################################################################################


global inconsistent_dir = "benchmarking/inconsistent_problems/"
BenchmarkTools.DEFAULT_PARAMETERS.samples = 1000

# Create suite
global suite3 = BenchmarkGroup()
suite3["HiGHS"] =  BenchmarkGroup()
suite3["Cbc"] =  BenchmarkGroup()
suite3["SCIP"] =  BenchmarkGroup()
suite3["AlgoModel"] =  BenchmarkGroup()

global i = 0

for file in readdir(inconsistent_dir)

    if file == ".DS_Store"
        continue
    end
    global i += 1

    file_model = MOI.FileFormats.Model(format = MOI.FileFormats.FORMAT_MPS)
    MOI.read_from_file(file_model, "$inconsistent_dir$file")

    global model = Model()
    MOI.copy_to(model, file_model)
    global model1 = copy(model)
    global model2 = copy(model)
    global model3 = copy(model)

    set_optimizer(model1, HiGHS.Optimizer)
    set_silent(model1)
    global suite3["HiGHS"][i] = @benchmarkable optimize!($model1)
    

    set_optimizer(model2, Cbc.Optimizer)
    set_silent(model2)
    global suite3["Cbc"][i] = @benchmarkable optimize!($model2)


    set_optimizer(model3, SCIP.Optimizer)
    set_silent(model3)
    global suite3["SCIP"][i] = @benchmarkable optimize!($model3)


    global algoModel = AlgoModel(model, DifferenceConstraints())
    global suite3["AlgoModel"][i] = @benchmarkable optimize!($algoModel)


    # small problems. Mean time for all. Report if problem on some
end

points3 = [j for j in 1:i]

tuned3 = tune!(suite3)
println("Samples:")
println(tuned3.data["HiGHS"][1].params.samples)

results3 = run(suite3)

HiGHS_times3 = [mean(value).time for (trial, value) in results3["HiGHS"]]./10^3
Cbc_times3 = [mean(value).time  for (trial, value) in results3["Cbc"]]./10^3
SCIP_times3 = [mean(value).time  for (trial, value) in results3["SCIP"]]./10^3
AlgoModel_times3 = [mean(value).time  for (trial, value) in results3["AlgoModel"]]./10^3

line13 = scatter(x=points3, y=HiGHS_times3, mode="lines+markers", name="HiGHS")
line23 = scatter(x=points3, y=Cbc_times3, mode="lines+markers", name="Cbc")
line33 = scatter(x=points3, y=SCIP_times3, mode="lines+markers", name="SCIP")
line43 = scatter(x=points3, y=AlgoModel_times3, mode="lines+markers", name="AlgoModel")

display(plot([line13, line23, line33, line43]))
sleep(60)


##########################################################
# Building and memory usage

global miplib_dir = "benchmarking/miplib_benchmarks/"
BenchmarkTools.DEFAULT_PARAMETERS.samples = 10

# Create suite
global suite4 = BenchmarkGroup()
suite4["JuMP_model"] =  BenchmarkGroup()
suite4["AlgoModel"] =  BenchmarkGroup()

n_m = []

global i = 0

for file in readdir(miplib_dir)

    if file == ".DS_Store"
        continue
    end
    global i += 1
    if i > 20
        i -= 1
        break
    end

    file_model = MOI.FileFormats.Model(format = MOI.FileFormats.FORMAT_MPS)
    MOI.read_from_file(file_model, "$miplib_dir$file") 
    # Test building:
    # JuMP
    global suite4["JuMP_model"][i] = @benchmarkable MOI.copy_to(Model(), $file_model)


    file_model = MOI.FileFormats.Model(format = MOI.FileFormats.FORMAT_MPS)
    MOI.read_from_file(file_model, "$miplib_dir$file")
    global model = Model()
    MOI.copy_to(model, file_model)

    # Additional time for our model:
    global model = copy(model)
    global suite4["AlgoModel"][i] = @benchmarkable AlgoModel($model, DifferenceConstraints())

    a =  AlgoModel(model, DifferenceConstraints())
    append!(n_m, a.rep.var_count+a.rep.con_count)


    # Find statistics, save and plot
    # var_count + con_count   vs    time    for both
    # Memory usage for both

end

points = [j for j in 1:20]

tuned4 = tune!(suite4)
println("Samples:")
println(tuned4.data["AlgoModel"][1].params.samples)

results4 = run(suite4)

JuMP_times4 = [mean(value).time for (trial, value) in results4["JuMP_model"]]./10^3
AgoModel_times4 = [mean(value).time  for (trial, value) in results4["AlgoModel"]]./10^3

JuMP_memory4 = [value.memory for (trial, value) in results4["JuMP_model"]]./10^3
AgoModel_memory4 = [value.memory  for (trial, value) in results4["AlgoModel"]]./10^3

JuMP_allocs4 = [value.allocs for (trial, value) in results4["JuMP_model"]]
AgoModel_allocs4 = [value.allocs  for (trial, value) in results4["AlgoModel"]]


line14 = scatter(x=n_m, y=JuMP_times4, mode="markers", name="JuMP_model")
line24 = scatter(x=n_m, y=AgoModel_times4, mode="markers", name="AgoModel")
display(plot([line14, line24]))
sleep(60)

line34 = scatter(x=n_m, y=JuMP_memory4, mode="markers", name="JuMP_model")
line44 = scatter(x=n_m, y=AgoModel_memory4, mode="markers", name="AgoModel")
display(plot([line34, line44]))

line154 = scatter(x=n_m, y=JuMP_allocs4, mode="markers", name="JuMP_model")
line164 = scatter(x=n_m, y=AgoModel_allocs4, mode="markers", name="AgoModel")
display(plot([line154, line164]))

line54 = scatter(x=points, y=JuMP_allocs4, mode="markers", name="JuMP_model")
line64 = scatter(x=points, y=AgoModel_allocs4, mode="markers", name="AgoModel")
display(plot([line54, line64]))
sleep(60)

