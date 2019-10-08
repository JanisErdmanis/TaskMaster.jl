using Documenter
using Literate
using TaskMaster

Literate.markdown(joinpath(@__DIR__, "../examples/introduction.jl"), joinpath(@__DIR__,"src/"); credit = false, name = "index")

Literate.markdown(joinpath(@__DIR__, "../examples/adaptive.jl"), joinpath(@__DIR__,"src/"); credit = false, name = "adaptive") 

makedocs(sitename="TaskMaster.jl",pages = ["index.md","adaptive.md"])

deploydocs(
     repo = "github.com/akels/TaskMaster.jl.git",
 )
