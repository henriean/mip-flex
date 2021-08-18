export get_lpmodel
export LPModel, LPRep
export 
    get_objective_vector, 
    get_constraint_matrices, 
    get_greater_than_variables, 
    get_less_than_variables,
    get_integer_variables, 
    get_zero_one_variables

"""
This part defines its own Jump ModelLike type, LPModel, which is limited regarding
how its constraints and variables can look like.

"""

# Recuire the model to have only less than constraints.
# May extend to vector formulation or equalto, but not currently.
# Single variable constraints cannot be controlled by this:
# Can be EqualTo, GreaterThan, LessThan, Interval, Integer, ZeroOne, Semicontionous or Semiinteger.
MOI.Utilities.@model(
    LPModel,                            # model_name
    (),                                 # scalar_sets
    (MOI.LessThan,),                    # typed_scalar_sets (removed MOI.EqualTo)
    (),                                 # vector_sets
    (),                                 # typed_vector_sets
    (),                                 # scalar_functions
    (MOI.ScalarAffineFunction,),        # typed_scalar_functions
    (),                                 # vector_functions
    (),                                 # typed_vector_functions
    false)                              # is_optimizer, Subtype of MathOptInterface.ModelLike


# Only MOI.GreaterThan{T}, MOI.LessThan{T}, MOI.ZeroOne and MOI.Integer currently allowed for variables, 
# other limitations get converted to constraints if possible, or the model is not built.
function MOI.supports_constraint(
    ::LPModel{T}, 
    ::Type{MOI.SingleVariable},
    ::Type{<:Union{MOI.EqualTo{T}, MOI.Interval{T}, MOI.Semicontinuous{T}, MOI.Semiinteger{T}}}) where T
    return false
end

# If not allowing free variables (?)
function MOI.supports_constraint(::LPModel{T}, ::Type{MOI.VectorOfVariables}, ::Type{MOI.Reals}) where T
    return false
end




# If on the right form, return it
function get_lpmodel(model::LPModel{T}) where T
    return model # Check if needed wrap model into LP-struct with other objects. Then possiby define base operations on it?
end


# Else bridge:
#TODO: Make sure and test that the mapping between old and new variables is ok.
function get_lpmodel(model::MOI.ModelLike, T::Type = Float64)
    _model = LPModel{T}()

    # Specify that any bridge can be used when using copy_to:
    
    #If all bridges:
    bridged_model = MOI.Bridges.full_bridge_optimizer(_model, Float64)

    """
    # From polyhedra
    bridged_model = MOI.Bridges.LazyBridgeOptimizer(_model)
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.GreaterToLessBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.LessToGreaterBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.NonnegToNonposBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.NonposToNonnegBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.ScalarizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.VectorizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.ScalarFunctionizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.VectorFunctionizeBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.SplitIntervalBridge{T})
    MOI.Bridges.add_bridge(bridged_model, MOI.Bridges.Constraint.NormInfinityBridge{T})
    """

    # Do the actual bridging into _model:
    MOI.copy_to(bridged_model, model)

    return get_lpmodel(_model)
end


# If getting JuMP.Model, use the backend MOI.ModelLike:
#TODO: Maybe do something in order to convert back to a JuMP model?
get_lpmodel(model::JuMP.Model) = get_lpmodel(backend(model))



"""
The following is code concerning representing the lnear problem in an easy to access way.
LPRep will be a struct holding desired fields.
"""


# Finds matrix A and vector b representing the linear system of LessThan inequalities
function get_constraint_matrices(lpmodel::LPModel)

    # Constraint indices from regular constraints (only affine in less than allowed.)
    cis = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.ScalarAffineFunction{Float64},MathOptInterface.LessThan{Float64}}())
    
    # Initiate Matrix with constraints as rows and variables as columns.
    con_number = size(lpmodel.constrmap, 1)
    var_number = lpmodel.num_variables_created
    A = zeros(con_number, var_number)
    #show(zeros(con_number, var_number))
    #show(Array{Float64, 2}(undef, con_number, var_number))

    # Initiate vector of less than constraints values
    b = zeros(con_number)
   
    # For each row, find the value of each variable in the corresponding constraint.
    # Use var_to_name in order to know what index each variable has, if needed.
    for i in 1:con_number
        for term in MOI.get(lpmodel, MOI.ConstraintFunction(), cis[i]).terms
            A[i, term.variable_index.value] = term.coefficient
        end
        b[i] = MOI.get(lpmodel, MOI.ConstraintSet(), cis[i]).upper
    end

    return (A, b)

end


# If a variable has greater than constraints,
# the lower bound will be saved in the index corresponding to its MOI index.
# If it has no lower bound, the value will be NaN.
function get_greater_than_variables(lpmodel::LPModel)
    cis_g = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.SingleVariable,MathOptInterface.GreaterThan{Float64}}())

    greater_than = fill(NaN, lpmodel.num_variables_created)

    for index in cis_g
        greater_than[MOI.get(lpmodel, MOI.ConstraintFunction(), index).variable.value] = MOI.get(lpmodel, MOI.ConstraintSet(), index).lower
    end
    return greater_than
end


# If a variable has less than constraints,
# the upper bound will be saved in the index corresponding to its MOI index.
# If it has no upper bound, the value will be NaN.
function get_less_than_variables(lpmodel::LPModel)
    cis_l = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.SingleVariable,MathOptInterface.LessThan{Float64}}())

    less_than = fill(NaN, lpmodel.num_variables_created)

    for index in cis_l
        less_than[MOI.get(lpmodel, MOI.ConstraintFunction(), index).variable.value] = MOI.get(lpmodel, MOI.ConstraintSet(), index).upper
    end
    return less_than
end


# Here 1 is set whenever the index variable is defined to be integer.
function get_integer_variables(lpmodel::LPModel)
    cis_i = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.SingleVariable,MathOptInterface.Integer}())

    integer = fill(NaN, lpmodel.num_variables_created)

    for index in cis_i
       integer[MOI.get(lpmodel, MOI.ConstraintFunction(), index).variable.value] = 1
    end
    return integer
end

# Here 1 is set whenever the index variable is defined to be zero_one.
function get_zero_one_variables(lpmodel::LPModel)
    cis_z = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.SingleVariable,MathOptInterface.ZeroOne}())

    zero_one = fill(NaN, lpmodel.num_variables_created)

    for index in cis_z
       zero_one[MOI.get(lpmodel, MOI.ConstraintFunction(), index).variable.value] = 1
    end
    return zero_one
end



# Gets objective vector of an LPModel as a vector of indices.
function get_objective_vector(lpmodel::LPModel)
    obj = lpmodel.objective
    c = zeros(size(obj.terms)[1])
    for term in obj.terms
        c[term.variable_index.value] = term.coefficient
    end
    return c
end

"""
# Gets objective function of any Jump model if the objective is linear.
function get_objective_vector(model::JuMP.Model)
    obj = MOI.get(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}())
    c = zeros(size(obj.terms)[1])
    for term in obj.terms
        c[term.variable_index.value] = term.coefficient
    end
    return c
end
"""


#cis_g = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.SingleVariable,MathOptInterface.GreaterThan{Float64}}())


# TODO: Insert list of integer variables and zero-one variables.
struct LPRep
    #Optimisation sense and vector c representing the objective function.
    sense::MathOptInterface.OptimizationSense
    c::Array{Float64,1}
    obj_constant::Float64

    # Matrix A and vector b representing the linear system of LessThan inequalities.
    A::Array{Float64,2}
    b::Array{Float64,1}

    # greater than variables
    greater_than::Array{Float64,1}

    # less than variables
    less_than::Array{Float64,1}

    # integer variables
    #integer::Array{Float64,1}

    # zero-one variables
    #zero_one::Array{Float64,1}

    # Mapping between original variable names and column in matrix.
    var_map::Dict{MathOptInterface.VariableIndex,String}


    function LPRep(lpmodel::LPModel)
        constraint_matrices = get_constraint_matrices(lpmodel)
        this = new(
            lpmodel.sense, 
            get_objective_vector(lpmodel),
            lpmodel.objective.constant,
            constraint_matrices[1],
            constraint_matrices[2],
            get_greater_than_variables,
            get_less_than_variables,
            lpmodel.var_to_name)
    end

end

LPRep(model::MOI.ModelLike) = LPRep(get_lpmodel(model))
LPRep(model::JuMP.Model) = LPRep(get_lpmodel(model))





"""
function show(lpmodel::LPModel)
    print("LPModel:\n")
    print("name:\n")
    show(lpmodel.name)
    print("\n\n")
    print("sense:\n")
    show(lpmodel.sense)
    print("\n\n")
    print("objective:\n")
    show(lpmodel.objective)
    print("\n\n")
    print("num_variables_created:\n")
    show(lpmodel.num_variables_created)
    print("\n\n")
    print("single_variable_mask:\n")
    show(lpmodel.single_variable_mask)
    print("\n\n")
    print("lower_bound:\n")
    show(lpmodel.lower_bound)
    print("\n\n")
    print("upper_bound:\n")
    show(lpmodel.upper_bound)
    print("\n\n")
    print("var_to_name:\n")
    show(lpmodel.var_to_name)
    print("\n\n")
    print("name_to_var:\n")
    show(lpmodel.name_to_var)
    print("\n\n")
    print("nextconstraintid:\n")
    show(lpmodel.nextconstraintid)
    print("\n\n")
    print("con_to_name:\n")
    show(lpmodel.con_to_name)
    print("\n\n")
    print("name_to_con:\n")
    show(lpmodel.name_to_con)
    print("\n\n")
    print("constrmap:\n")
    show(lpmodel.constrmap)
end
"""