using Revise

@everywhere using TaskMaster
using Distributed

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

tasks = RemoteChannel(()->Channel{Int}(10))
results = RemoteChannel(()->Channel{Tuple{Int,Int}}(10))

for p in workers()
    wp = @spawnat p work(f,tasks,results)
end

learner = IgnorantLearner(1:10)
for (xi,yi) in Master(learner,tasks,results)
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

tasks = RemoteChannel(()->Channel{Int}(10))
results = RemoteChannel(()->Channel{Tuple{Int,Int}}(10))

for p in workers()
    wp = @spawnat p work(f,tasks,results)
end

learner = IgnorantLearner(1:10)
wlearner = WrappedLearner(learner,x->x.state!=nothing && x.state>3) 
for (xi,yi) in Master(wlearner,tasks,results)
     @show (xi,yi)
end

@info "Testing evaluate"

@everywhere f(x) = x^2
learner = IgnorantLearner(1:10)
evaluate(f,learner)
