using PyPlot

using Distributed
addprocs(2)

using Adaptive
using TaskMaster


@everywhere f(x) = exp(-x^2)

fig = figure()

x = collect(range(-2,stop=2,length=200))
plot(x,f.(x),label=L"e^{-x^2}")

xx = collect(range(-2,stop=2,length=20))
plot(xx,f.(xx),".-",label="even sampling")

master = ProcMaster(f)
learner1d = AdaptiveLearner1D((-2,+2))
loop = Loop(master,learner1d)
evaluate(loop,1:20)

plot(learner1d.x,learner1d.y,".-",label="AdaptiveLearner1D")

legend()
show()

