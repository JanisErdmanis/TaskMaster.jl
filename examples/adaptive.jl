using Distributed
addprocs(2)
using TaskMaster
using Adaptive

@everywhere f(x) = exp(-x^2)

@info "1D learner for a finite number of steps."

master = ProcMaster(f)
learner1d = AdaptiveLearner1D((0,1))
loop = Loop(master,learner1d)
evaluate(loop,1:10)

@info "1D learner with a stopping condition."

master = ProcMaster(f)
learner1d = AdaptiveLearner1D((0,1))
loop = Loop(master,learner1d)
evaluate(loop,learner->learner.loss()<0.1)

@info "2D learner with a stopping condition."

@everywhere f(x) = exp(-x[1]^2 - x[2]^2)

master = ProcMaster(f)
learner2d = AdaptiveLearner2D([(0,1),(0,1)])
loop = Loop(master,learner2d)
evaluate(loop,learner->learner.loss()<0.1)

