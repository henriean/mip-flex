export gaussian_elimination

function gaussian_elimination(algomodel)
    lp = algomodel.rep
    A = lp.A
    At = lp.At
    b = lp.b
    nzval = At.nzval
    colptr = At.colptr


end

function is_flow_problem(algomodel)
    lp = algomodel.rep
    A = lp.A
    At = lp.At
    b = lp.b
    nzval = At.nzval
    colptr = At.colptr

    vector = reduce(A)
    
end


# Transform into equality form
function equality_form(A, b)
end

# Factorize A (rxc) until the first r columns of A is the identity matrix
function reduce(A)
    return [A]
end