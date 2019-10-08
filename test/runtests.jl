using Distributed
addprocs(2)

using TaskMaster

@everywhere f(x) = x^2

@info "Testing evaluate"

master = WorkMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,learner)
evaluate!(loop)

@info "Testing evaluate with source"

master = WorkMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,learner)
output1 = evaluate!(loop,1:6) ### In a way looks like a transducer

@info "Testing the debugger for Learner"

master = HistoryMaster(output1,length(master.slaves))
learner = IgnorantLearner(1:10)
loop = Loop(master,learner,loop->println("Learner state $(loop.learner.state)"))
output2 = evaluate!(loop,1:6)

@info "Testing evaluate with stopping condition"

master = WorkMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,learner)
evaluate!(loop,l->l.state==4)

@info "Testing capturing and releasing of the slave"

@everywhere f(x) = x^2
learner = IgnorantLearner(1:10)
master = WorkMaster(f,WorkerPool())

captureslave!(2,f,master)
captureslave!(3,f,master)
@show releaseslave!(master)
@show releaseslave!(master)

@info "Success!!!"
