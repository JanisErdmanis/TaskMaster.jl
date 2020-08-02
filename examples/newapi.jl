# # New API

# The previous API is too verbose to be a convinient substitute for `pmap`. The goal on this file is to demonstrate a higher level API which migh be more convinient.

using Distributed
addprocs(2)
using TaskMaster
using Adaptive
using PyPlot

@everywhere f(p) = exp(-p[1]^2 - p[2]^2)

learner2d = AdaptiveLearner2D([(-3,+3),(-3,+3)])
results = play!(learner2d, f, x->x.loss()<0.05)

# The results object stores all necessary information to reconstruct the state of the learner which can be done with replay! command. That could work as follows:
# ```
# learnerrec = AdaptiveLearner2D([(-3,+3),(-3,+3)])
# replay!(learnerrec, results)
# ```
# For this command to work it requires that learner is deterministic and is configured at the same way as when computations were produced. 

### Now I can have a plotting recipie for the adaptive package
fig = figure()
plot(learner2d)
savefig("learner2d.svg")

# ![](learner2d.svg)

