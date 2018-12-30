module TaskMaster

abstract type Learner end
ask!(learner::Learner) = error("For runner learner needs to implement ask! and tell! methods")
tell!(learner::Learner,message) = error("For runner learner needs to implement ask! and tell! methods")

using Distributed

mutable struct Master
    learner
    tasks
    results
    slaves 
    unresolved
end

"""
Releases one worker (who is the next one of taking a new task) from the duty calculating function values given him by the master. Returns pid.
"""
function releaseslave!(master::Master)
    @assert length(master.slaves)>0
    
    put!(master.tasks,nothing)

    while true
        for i in 1:length(master.slaves)
            ### I need to find first one which is free 
            if isready(master.slaves[i])==true
                pid = master.slaves[i].where
                deleteat!(master.slaves,i)
                return pid
            end
        end
    end
end

"""
Releases all workers from the Master's duties.
"""
function releaseall!(master::Master)
    for s in master.slaves
        put!(master.tasks,nothing)
    end

    
    for s in master.slaves
        wait(s)
    end

    pids = [s.where for s in master.slaves]
    master.slaves = []

    return pids
end

"""
Gives the slave a duty to follow orders of his new Master
"""
function captureslave!(pid,f::Function,master::Master)
    tasks, results = master.tasks, master.results
    wp = @spawnat pid begin
        while true
            x = take!(tasks)
            if x==nothing
                break
            else
                y = f(x)
                put!(results,(x,y))
            end
        end
    end
    push!(master.slaves,wp)
end

Master(learner,tasks,results,slaves) = Master(learner,tasks,results,slaves,0)
Master(learner,tasks,results) = Master(learner,tasks,results,[],0)

function Master(f::Function,wpool::AbstractWorkerPool,learner)
    tasks = RemoteChannel(()->Channel{Any}(10))
    results = RemoteChannel(()->Channel{Tuple{Any,Any}}(10))

    master = Master(learner,tasks,results)
    for p in wpool.workers
        captureslave!(p,f,master)
    end

    return master
end

Master(f::Function,learner) = Master(f,WorkerPool(nprocs()==1 ? [1] : workers()),learner)

import Base.iterate

function iterate(master,state) 

    if master.unresolved < length(master.slaves) 
        xi = ask!(master.learner)
        if xi!=nothing
            master.unresolved += 1
        end
    else
        xi = nothing
    end
    
    if xi==nothing && master.unresolved==0
        ### A perfect time to release all slaves
        releaseall!(master)
        return nothing 
    elseif xi!=nothing 
        put!(master.tasks,xi)
        return iterate(master,state) 
     else
        (xi,yi) = take!(master.results)
        tell!(master.learner,(xi,yi))
        master.unresolved -= 1
        return (xi,yi), state
    end
end

iterate(master) = iterate(master,nothing)

############## Now some abstractions #############

struct WrappedLearner
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

function evaluate(f,wpool::AbstractWorkerPool,learner)
    master = Master(f,wpool,learner)
    for (xi,yi) in master
        # 
        println("xi=$xi yi=$yi")
    end
    return nothing
end

evaluate(f,wpool::AbstractWorkerPool,learner,stop) = evaluate(f,wpool,WrappedLearner(learner,stop))
evaluate(f,learner) = evaluate(f,WorkerPool(nprocs()==1 ? [1] : workers()),learner)
evaluate(f,learner,stop) = evaluate(f,WorkerPool(nprocs()==1 ? [1] : workers()),learner,stop)

export Master, iterate, Learner, ask!, tell!, evaluate, WrappedLearner, releaseslave!, captureslave!

end
