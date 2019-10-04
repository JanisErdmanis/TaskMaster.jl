using Distributed
addprocs(2)

using TaskMaster

######### Now some testing ###########

####### Implemntation of Learner interface with iterator ########

@info "Testing Loop and ProcMaster"

@everywhere f(x) = x^2

master = ProcMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,(x,y)->y,learner)

for i in 1:11
    x = TaskMaster.getx(loop,nothing)
    if x == nothing
        break
    end
    @show res = TaskMaster.getres(loop,x)
end

@info "Testing evaluate"

master = ProcMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,(x,y)->y,learner)
evaluate(loop)

@info "Testing evaluate with source"

master = ProcMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,(x,y)->y,learner)
evaluate(loop,1:6) ### In a way looks like a transducer

@info "Testing evaluate with iterator and askhook."

master = ProcMaster(f)
learner = IgnorantLearner(1:10)
evaluate(master,learner,1:5)

@info "Testing evaluate with stopping condition"

master = ProcMaster(f)
learner = IgnorantLearner(1:10)
evaluate(master,(x,y)->y,learner,l->l.state==4)

@info "Testing capturing and releasing of the slave"

@everywhere f(x) = x^2
learner = IgnorantLearner(1:10)
master = ProcMaster(f,WorkerPool())

captureslave!(2,f,master)
captureslave!(3,f,master)
@show releaseslave!(master)
@show releaseslave!(master)

@info "Success!!!"
