using Distributed
addprocs(2)
using TaskMaster
using Transducers

@everywhere f(x) = x^2

master = ProcMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,learner)

inch = Channel(Map(identity),1:10)
outch = Channel(10)

@sync begin
    @async evaluate(loop,inch,outch)
    collect(Map(identity),outch)
end

# would be nice to write:
# collect(Map(identity) |> Loop(master,learner) |> Map(identity),1:10)
