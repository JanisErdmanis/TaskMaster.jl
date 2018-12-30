using Revise

using Distributed
using TaskMaster

######### Now some testing ###########

####### Implemntation of Learner interface with iterator ########

import TaskMaster: ask!, tell!, Learner 

mutable struct IgnorantLearner <: Learner
    iter
    state
end
IgnorantLearner(iter) = IgnorantLearner(iter,nothing)

function ask!(learner::IgnorantLearner)
    temp = learner.state==nothing ? iterate(learner.iter) : iterate(learner.iter,learner.state)
    if temp==nothing
        return nothing
    else
        val,learner.state = temp
        return val
    end
end

tell!(learner::IgnorantLearner,m) = nothing


@info "Testing bare interface"

@everywhere f(x) = x^2

learner = IgnorantLearner(1:10)

tasks = RemoteChannel(()->Channel{Union{Int,Nothing}}(10))
results = RemoteChannel(()->Channel{Tuple{Any,Any}}(10))

master = Master(learner,tasks,results)
for p in workers()
    captureslave!(p,f,master)
end

for (xi,yi) in master
    @show (xi,yi)
end

@info "Testing simple interface"
### Works!!!. Hurray!

@everywhere f(x) = x^2
learner = IgnorantLearner(1:10)

for (xi,yi) in Master(f,learner)
    @show (xi,yi)
end

@info "Testing WrappedLearner"

@everywhere f(x) = x^2

learner = IgnorantLearner(1:10)
wlearner = WrappedLearner(learner,x->x.state!=nothing && x.state>3) 

for (xi,yi) in Master(f,wlearner)
    @show (xi,yi)
end

@info "Testing evaluate"

@everywhere f(x) = x^2
learner = IgnorantLearner(1:10)
evaluate(f,learner)

@info "Testing evaluate with a stop condition"

@everywhere f(x) = x^2
learner = IgnorantLearner(1:10)
#evaluate(f,WrappedLearner(learner,learner->learner.state!=nothing && learner.state>3))
evaluate(f,learner,learner->learner.state!=nothing && learner.state>3)

@info "Testing capturing and releasing of the slave"

@everywhere f(x) = x^2
learner = IgnorantLearner(1:10)
master = Master(f,WorkerPool(),learner)

captureslave!(2,f,master)
captureslave!(3,f,master)
@show releaseslave!(master)
@show releaseslave!(master)

@info "Success!!!"






