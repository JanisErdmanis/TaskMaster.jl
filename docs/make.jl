using Documenter
using Literate


makedocs(sitename="TaskMaster.jl",pages = ["index.md"])

deploydocs(
     repo = "github.com/akels/TaskMaster.jl.git",
 )
