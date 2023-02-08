push!(LOAD_PATH,"../src/")
using MipFlex
using Documenter

DocMeta.setdocmeta!(MipFlex, :DocTestSetup, :(using MipFlex); recursive=true)

makedocs(;
    modules=[MipFlex],
    authors="Henriette Andersen <henriean@stud.ntnu.no> and contributors",
    repo="https://github.com/henriean/MipFlex.jl/blob/{commit}{path}#{line}",
    sitename="MipFlex.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://henriean.github.io/MipFlex.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/henriean/MipFlex.jl",
)
