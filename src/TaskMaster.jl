module TaskMaster

abstract type Learner end
ask!(learner::Learner) = error("For runner learner needs to implement ask! and tell! methods")
tell!(learner::Learner,message) = error("For runner learner needs to implement ask! and tell! methods")

using Distributed

function work(f,tasks,results)
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

mutable struct Master
    learner
    tasks
    results
    workers
    unresolved
end

Runner(learner,tasks,results) = Master(learner,tasks,results,[],0)

function Master(f::Function,learner)
    tasks = RemoteChannel(()->Channel{Any}(10))
    results = RemoteChannel(()->Channel{Tuple{Any,Any}}(10))

    worklist = []
    for p in workers()
        wp = @spawnat p work(f,tasks,results)
        push!(worklist)
    end

    Master(learner,tasks,results,worklist,0)
end


import Base.iterate

function iterate(runner,state) 

    if runner.unresolved < nprocs()-1 
        xi = ask!(runner.learner)
        if xi!=nothing
            runner.unresolved += 1
        end
    else
        xi = nothing
    end
    
    if xi==nothing && runner.unresolved==0
        return nothing 
    elseif xi!=nothing 
        put!(runner.tasks,xi)
        return iterate(runner,state) ### So this part would get fulled by
     else
        (xi,yi) = take!(runner.results)
        tell!(runner.learner,(xi,yi))
        runner.unresolved -= 1
        return (xi,yi), state
    end
end

iterate(runner) = iterate(runner,nothing)


############## Now some abstractions #############

function evaluate(f,learner)

    tasks = RemoteChannel(()->Channel{Any}(10))
    results = RemoteChannel(()->Channel{Tuple{Any,Any}}(10))

    for p in workers()
        @spawnat p begin
            while true
                x = take!(tasks)
                y = f(x)
                put!(results,(x,y))
            end
        end
    end

    for (xi,yi) in Master(learner,tasks,results)
        println("xi=$xi yi=$yi")
    end
    # No need to return anything since learner itself contains information
end

### In the end I would need to anotate code with types. Then I will see if it can be subtyped. 

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

export Master, work, iterate, Learner, ask!, tell!, evaluate, WrappedLearner

end
