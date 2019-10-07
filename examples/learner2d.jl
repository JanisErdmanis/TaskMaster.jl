using Distributed
addprocs(2)

using Adaptive
using TaskMaster
using PyPlot

@everywhere f(p) = exp(-p[1]^2 - p[2]^2)

master = ProcMaster(f)
learner2d = AdaptiveLearner2D([(-3,+3),(-3,+3)])
loop = Loop(master,learner2d)
evaluate(loop,1:100)

fig = figure()

p,tri,v = learner2d.points, learner2d.vertices, learner2d.values

tricontourf(p[:,1],p[:,2],tri.-1,v)
triplot(p[:,1],p[:,2],tri.-1,"k.-")

show()
