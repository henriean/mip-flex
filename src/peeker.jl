using JuMP
using MathOptInterface

export Peeker

mutable struct Peeker
    model::JuMP.Model
    lpmodel::LPModel
    lprep::LPRep

    function Peeker(model::JuMP.Model)
        lpmod = get_lpmodel(model)
        this = new(model, lpmod, LPRep(lpmod))
    end

    function update()
        this.lpmod = get_lpmodel(this.model)
        this.lprep = LPRep(this.lpmod)
    end
end