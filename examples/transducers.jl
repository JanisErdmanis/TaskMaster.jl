using Distributed
addprocs(2)
using TaskMaster
using Transducers

@everywhere f(x) = x^2

master = ProcMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,learner)

@sync begin
    inch = Channel(Map(identity),1:10)
    outch = Channel(1)
    @async evaluate(loop,inch,outch)

    for o in outch
        @show o
    end
    ### Gets stuck at the first element
    collect(Map(identity),outch)
end

# would be nice to write:
# collect(Map(identity) |> Loop(master,learner) |> Map(identity),1:10)
