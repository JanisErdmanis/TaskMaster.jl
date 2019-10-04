module TaskMaster

abstract type Learner end
ask!(learner::Learner) = error("For runner learner needs to implement ask! and tell! methods")
tell!(learner::Learner,message) = error("For runner learner needs to implement ask! and tell! methods")


struct WrappedLearner <: Learner
    learner
    stop
    askhook
    tellhook
end
WrappedLearner(learner,stop) = WrappedLearner(learner, stop, (x,y)->nothing, (x,y)->nothing)

function ask!(learner::WrappedLearner)
    if learner.stop(learner.learner)
        val = nothing
    else
        val = ask!(learner.learner)
    end
    learner.askhook(learner.learner,val)
    return val
end

function tell!(learner::WrappedLearner,message)
    tell!(learner.learner,message)
    learner.tellhook(learner.learner,message)
end

### The interface probabily needs to be a little different
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

abstract type Master end
include("procmaster.jl")

struct Loop
    master::Master
    op::Function
    learner::Learner
end
#Loop(master::Function,op::Function,l::Function) = Loop(master(),op,l())

function getres(loop::Loop,x)
    put!(loop.master.tasks,x)
    res = take!(loop.master.results)
    tell!(loop.learner,res)
    return res
end

function getx(loop::Loop,input)
    feedinput = ask!(loop.learner)
    x = loop.op(input,feedinput)
    return x
end
### I could have infinity iterator which always just gives true.

function evaluate(loop::Loop,iter)
    acc = []

    nparalel = length(loop.master.slaves)
    unresolved = 0
    
    @sync for i in iter

        ### While loop could perhaps be avoided if a fixed size Channel is used.
        ### Perhaps I could use a fixed size Channel for the tasks.
        ### When one spawns one needs to know if the process had been finished.
        ### Master(f) VS f and Master()
        while unresolved>nparalel end

        x = getx(loop,i)
        if x==nothing
            break
        end
        
        @async begin
            unresolved+=1
            res = getres(loop,x)
            unresolved-=1
            push!(acc,res)
        end
    end
    return acc
end

### We could use generated functions so I would not need to make infinity iterator.
function evaluate(loop::Loop)
    acc = []

    nparalel = length(loop.master.slaves)
    unresolved = 0
    
    @sync while true

        while unresolved>nparalel end

        x = getx(loop,nothing)
        if x==nothing
            break
        end
        
        @async begin
            unresolved+=1
            res = getres(loop,x)
            unresolved-=1
            push!(acc,res)
            # This is the point where one may think of the next iteration.
            # Could spawning be a better option?
        end
    end
    return acc
end
    
function evaluate(master::Master,op::Function,l::Learner,stop::Function)
    wl = WrappedLearner(l, stop, (x,y)->nothing, (x,y)->nothing)
    loop = Loop(master,op,wl)
    evaluate(loop)
end

function evaluate(master::Master,op::Function,l::Learner,iter)
    iterlength = length(iter)

    count = 0
    askhook(x,y) = count+=1;
    stop(l) = count==iterlength

    wl = WrappedLearner(l, stop, askhook, (x,y)->nothing)
    loop = Loop(master,op,wl)
    evaluate(loop,iter)
end

evaluate(master::Master,l::Learner,iter) = evaluate(master,(x,y)->x,l,iter)


export ProcMaster, Learner, ask!, tell!, WrappedLearner, IgnorantLearner, evaluate, Loop, captureslave!, releaseslave!


### High level interface
export ProcMaster, Loop, Learner, ask!, tell!, evaluate

end
