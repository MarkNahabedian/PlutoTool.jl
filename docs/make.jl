
using Documenter
using PlutoTool

# Temporary hack:
push!(LOAD_PATH,"../src/")

makedocs(;
         modules=[PlutoTool],
         format=Documenter.HTML(),
         pages=[
             "Home" => "index.md",
         ],
         sitename="PlutoTool.jl",
         authors="Mark Nahabedian"
)

deploydocs(;
           repo="github.com/MarkNahabedian/PlutoTool.jl",
           devbranch="main",
)
