struct WrappedLearner <: Learner
    learner
    stop
    askhook
    tellhook
end
WrappedLearner(learner,stop) = WrappedLearner(learner, stop, (x,y)->nothing, (x,y)->nothing)

function ask!(learner::WrappedLearner,input)
    if learner.stop(learner.learner)
        val = nothing
    else
        val = ask!(learner.learner,input)
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

function ask!(learner::IgnorantLearner,input)

    if input==nothing
        return nothing
    end
    
    temp = learner.state==nothing ? iterate(learner.iter) : iterate(learner.iter,learner.state)
    if temp==nothing
        return nothing
    else
        val,learner.state = temp
        return val
    end
end

tell!(learner::IgnorantLearner,m) = nothing


### Something which would help to reproduce the state of the Learner. 
mutable struct HistoryMaster <: Master
    tasks
    results
    np
end

nparalel(master::HistoryMaster) = master.np

function HistoryMaster(output,np)
    N = length(output)
    tasks = Channel{Any}(N)
    results = Channel{Tuple{Any,Any}}(N)

    for oi in output
        put!(results,oi)
    end

    HistoryMaster(tasks,results,np)
end


### 

struct PlayRes
    input::Union{Nothing,Vector}
    output::Vector
    nprocs::Int
end 

function play!(learner, f::Function, stop::Function)#,cond::Function) ### I could also pass WorkerPool here
    master = WorkMaster(f)
    nprocs = length(master.slaves)
    loop = Loop(master, learner)
    nodes = evaluate!(loop, stop)
    releaseall!(master)
    return PlayRes(nothing, nodes, nprocs)
end


function replay!(learner,nodes::Array{Any}) ### I could make a st function as an optional argument
    for n in nodes
        tell!(learner,n)
    end
end

function replay!(learner, ldata::PlayRes, n::Int)
    @assert n <= length(ldata.output)
    master = HistoryMaster(ldata.output,ldata.nprocs) 
    loop = Loop(master,learner) 
    iter = 1:n
    evaluate!(loop,iter)
end

replay!(learner, ldata::PlayRes) = replay!(learner, ldata, length(ldata.output))

