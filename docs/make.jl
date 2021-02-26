using SolverPeeker
using Documenter

DocMeta.setdocmeta!(SolverPeeker, :DocTestSetup, :(using SolverPeeker); recursive=true)

makedocs(;
    modules=[SolverPeeker],
    authors="Henriette Andersen <henriean@stud.ntnu.no> and contributors",
    repo="https://github.com/henriean/SolverPeeker.jl/blob/{commit}{path}#{line}",
    sitename="SolverPeeker.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://henriean.github.io/SolverPeeker.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/henriean/SolverPeeker.jl",
)
