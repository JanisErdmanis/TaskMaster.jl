using Distributed

mutable struct WorkMaster <: Master
    tasks
    results
    slaves 
end

nparalel(master::WorkMaster) = length(master.slaves)

"""
Releases one worker (who is the next one of taking a new task) from the duty calculating function values given him by the master. Returns pid.
"""
function releaseslave!(master::WorkMaster)
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
function releaseall!(master::WorkMaster)
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
function captureslave!(pid,f::Function,master::WorkMaster)
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

WorkMaster(tasks,results) = WorkMaster(tasks,results,[])

function WorkMaster(f::Function,wpool::AbstractWorkerPool)
    tasks = RemoteChannel(()->Channel{Any}(10))
    results = RemoteChannel(()->Channel{Tuple{Any,Any}}(10))

    master = WorkMaster(tasks,results)
    for p in wpool.workers
        captureslave!(p,f,master)
    end

    return master
end

WorkMaster(f::Function) = WorkMaster(f,WorkerPool(nprocs()==1 ? [1] : workers()))
