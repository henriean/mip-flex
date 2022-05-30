using MathOptInterface

export get_lpmodel
export LPModel, LPRep


#This part defines its own Jump ModelLike type, LPModel, which is limited regarding
#how its constraints and variables can look like.

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

Core.@doc """
    LPModel

A special JuMP ModelLike type defined for use in ['SolverPeeker'](@ref).

This type only supports ['MathOptInterface.LessThan'](@ref) typed scalar sets, and only
['MathOptInterface.ScalarAffineFunction'](@ref) typed scalar functions, meaning that any
vector constraint has to be bridged into a set of less than inequalities.

Single variable constraints cannot be controlled by this, and can be 
['MathOptInterface.EqualTo'](@ref), ['MathOptInterface.GreaterThan'](@ref), 
['MathOptInterface.LessThan'](@ref), ['MathOptInterface.Interval'](@ref),
['MathOptInterface.Integer'](@ref), ['MathOptInterface.ZeroOne'](@ref), 
['MathOptInterface.Semicontionous'](@ref) or ['MathOptInterface.Semiinteger'](@ref).
""" SolverPeeker.LPModel

"""
    MOI.supports_constraint(BT::LPModel{T}, <keyword arguments>)

Method specifying which 'MOI.SingleVariable' constraints that are not supported by LPModel.

'Union{MOI.EqualTo{T}', 'MOI.Interval{T}',' MOI.Semicontinuous{T}', 'MOI.Semiinteger{T}'
are the ones not allowed, which results in
MOI.GreaterThan{T}, MOI.LessThan{T}, MOI.EqualTo{T}, and MOI.Integer currently allowed for variables, 
"""
function MOI.supports_constraint(
    ::LPModel{T}, 
    ::Type{MOI.VariableIndex},
    ::Type{<:Union{MOI.Interval{T}, MOI.Semicontinuous{T}, MOI.Semiinteger{T}, MOI.ZeroOne}}) where T
    return false
end


# If not allowing free variables (?)
function MOI.supports_constraint(::LPModel{T}, ::Type{MOI.VectorOfVariables}, ::Type{MOI.Reals}) where T
    return false
end




# If on the right form, return it
get_lpmodel(model::LPModel) = model


# Else bridge:
#TODO: Make sure and test that the mapping between old and new variables is ok.
function get_lpmodel(model::MOI.ModelLike, T::Type = Float64)
    lpmodel = LPModel{T}()

    # Specify that any standard bridge can be used when using copy_to:
    # Uses amongst others supports_constraint with tyoe LPModel to decide on
    # which bridges to use.
    bridging_model = MOI.Bridges.full_bridge_optimizer(lpmodel, Float64)

    # Do the actual bridging into lpmodel:
    MOI.copy_to(bridging_model, model)

    # Check for supported constraints
    for (F,S) in MOI.get(lpmodel, MOI.ListOfConstraintTypesPresent())
        if !MOI.supports_constraint(lpmodel, F, S)
            throw(MOI.UnsupportedConstraint{F,S}())
        end
    end

    return lpmodel
end


# If getting JuMP.Model, use the backend MOI.ModelLike:
#TODO: Maybe do something in order to convert back to a JuMP model?
get_lpmodel(model::JuMP.Model) = get_lpmodel(backend(model))





#The following is code concerning representing the lnear problem in an easy to access way.
#LPRep will be a struct holding desired fields.



# Here 1 is set whenever the index variable is defined to be zero_one.
#function get_zero_one_variables(lpmodel)
#    cis_z = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.SingleVariable,MathOptInterface.ZeroOne}())

#    zero_one = fill(NaN, lpmodel.num_variables_created)

#    for index in cis_z
#       zero_one[MOI.get(lpmodel, MOI.ConstraintFunction(), index).variable.value] = 1
#    end
#    return zero_one
#end





#cis_g = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MathOptInterface.SingleVariable,MathOptInterface.GreaterThan{Float64}}())


# TODO: Insert list zero-one variables.
struct LPRep

    # If, on creation, an inconsistency is revealed,
    # set this flag to false, and stop creating the representation
    is_consistent::Bool

    var_count::Int64  # Number of variables
    con_count::Int64  # Number of constraints

    #Optimisation sense and vector c representing the objective function.
    sense::MOI.OptimizationSense
    c::Array{Float64,1}
    obj_constant::Float64

    # Matrix A and vector b representing the linear system of LessThan inequalities,
    # while At is the transposed version of A.
    A::SparseMatrixCSC{Float64, Int64}
    b::Array{Float64,1}
    At::SparseMatrixCSC{Float64, Int64}

    # greater than variables
    greater_than::Dict{Int64, Float64}

    # less than variables
    less_than::Dict{Int64, Float64}

    # integer variables
    integer::Dict{Int64, Bool}

    # dict of original equality variables
    equal_to::Dict{Int64, Float64}

    # zero-one variables
    #zero_one::Array{T,1}

    # Mapping between original variable names and column in matrix.
    var_to_name::Dict{Int64, String}

end



# Updates dictionary of bounds only if new bound is stricter.
function update_dict!(dict, index, constant, less_than=true)
    if less_than
        if (!haskey(dict, index) || dict[index] > constant)
            dict[index] = constant
        end
    else
        if (!haskey(dict, index) || dict[index] < constant)
            dict[index] = constant 
        end
    end
end



# Right now does not support equal to - constraints for variables.
# Throws error if '='.

function LPRep(lpmodel::LPModel)

    is_consistent = true

    var_count = MOI.get(lpmodel, MOI.NumberOfVariables())

    # Dictionary holding what variable index i is greater than
    greater_than = Dict()

    # Dictionary holding what variable index i is less than
    less_than = Dict()


    # Constraint indices from regular constraints (only affine in less than allowed.)
    cis = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Float64}, MOI.LessThan{Float64}}())
    con_number = size(cis)[1]

    # Initiate vector of less than constraints values
    b = zeros(con_number)

    # rows index
    R = []
    # column index
    C = []
    # value
    V=[]
   
    # Go through each constraint and regiser the coefficient for each variable index.
    polynomial_constraint_number = 1
    Threads.@threads for i in 1:con_number
        terms = MOI.get(lpmodel, MOI.ConstraintFunction(), cis[i]).terms
        constant = MOI.get(lpmodel, MOI.ConstraintSet(), cis[i]).upper

        if size(terms)[1] == 1
            # Add this to variable constraints
            index = terms[1].variable.value
            coefficient = terms[1].coefficient

            if coefficient > 0
                # It's less than some number
                # Normalize constant
                constant = constant/coefficient
                # If new least upper bound, update dictionary
                update_dict!(less_than, index, constant)
            elseif coefficient < 0
                # It's greater than some number
                # Normalize constant, and flip sign
                constant = (-constant)/(-coefficient)
                # If new least upper bound, update dictionary
                update_dict!(greater_than, index, constant, false)
            else 
                # Does not reach this, because if zero, then terms has no length.
            end

        elseif size(terms)[1] == 0
            # Variable is set to zero, and if constant is less than zero, it's inconsistent
            # If it's greater than zero, then it's redundant
            if constant < 0
                is_consistent = false
                # Stop building? Proof?
                # It will be constraint nr i states 0>coefficient
            end

        else
            for term in terms
                append!(R, [polynomial_constraint_number])
                append!(C, [term.variable.value])
                append!(V, [term.coefficient])
            end
            b[polynomial_constraint_number] = MOI.get(lpmodel, MOI.ConstraintSet(), cis[i]).upper
            polynomial_constraint_number += 1
        end

    end
    # Set the final number of polynomial constraints
    con_count = polynomial_constraint_number - 1
    b = b[1:con_count]

    # Make sparse matrices
    A = sparse(R,C,V)
    At = sparse(C,R,V)
    # Drop zeros if any are registered
    A = dropzeros(A)
    At = dropzeros(At)


    # Get integer variables
    cis_i = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MOI.VariableIndex, MathOptInterface.Integer}())
    integer = Dict()
    Threads.@threads for i in (1:size(cis_i)[1])
        integer[MOI.get(lpmodel, MOI.ConstraintFunction(), cis_i[i]).value] = true
    end

    # Get EqualTo-variables
    cis_e = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MOI.VariableIndex, MathOptInterface.EqualTo{Float64}}())
    equal_to = Dict()
    Threads.@threads for i in (1:size(cis_e)[1])
        equal_to[cis_e[i].value] = MOI.get(lpmodel, MOI.ConstraintSet(), cis_e[1]).value
    end

    
    # Update less_than and greater_than from variable constraints
    cis_l = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.LessThan{Float64}}())
    Threads.@threads for i in (1:size(cis_l)[1])
        index = MOI.get(lpmodel, MOI.ConstraintFunction(), cis_l[i]).value
        constant = MOI.get(lpmodel, MOI.ConstraintSet(), cis_l[i]).upper
        update_dict!(less_than, index, constant)
    end


    cis_g = MOI.get(lpmodel, MOI.ListOfConstraintIndices{MOI.VariableIndex, MOI.GreaterThan{Float64}}())
    Threads.@threads for i in (1:size(cis_g)[1])
        index = MOI.get(lpmodel, MOI.ConstraintFunction(), cis_g[i]).value
        constant = MOI.get(lpmodel, MOI.ConstraintSet(), cis_g[i]).lower
        update_dict!(greater_than, index, constant, false)
    end

    # Check for infeasibility in greater than and less than dictionary
    # Usually not that many problems with intersecting, so not too big a space, so no threading?
    for i in intersect(keys(less_than), keys(greater_than))
        if less_than[i] < greater_than[i]
            # Infeasibe, empty set of legal values
            is_consistent = false
        elseif haskey(integer, i) && (less_than[i] - greater_than[i] < 1)
            # Infeasible, no legal integer values
            is_consistent = false
        end
    end

    # Get objective function
    objective = fill(0, var_count)
    o = MOI.get(lpmodel, MOI.ObjectiveFunction{MathOptInterface.ScalarAffineFunction{Float64}}())
    Threads.@threads for term in o.terms
        objective[term.variable.value] = term.coefficient
    end
    obj_constant = o.constant

    # Remove MathOptInterface type in dict
    var_to_name = Dict()
    for (key, entry) in lpmodel.var_to_name
        var_to_name[key.value] = entry
    end

    return LPRep(is_consistent,
        var_count,
        con_count,
        MOI.get(lpmodel, MOI.ObjectiveSense()), 
        objective,
        obj_constant,
        A,
        b,
        At,
        greater_than,
        less_than,
        integer,
        equal_to,
        var_to_name)
end


LPRep(model::JuMP.Model) = LPRep(get_lpmodel(model))