struct Loop
    master::Master
    learner::Learner
    iterhook::Function
end
Loop(master::Master,learner::Learner) = Loop(master,learner,x->nothing)

function evaluate(loop::Loop,inch,outch)
    np = nparalel(loop.master)
    unresolved = 0
    x = 0 ### Needs to be some value of ask! output type
    while true
        if x!=nothing && unresolved<np
            i = take!(inch)
            x = ask!(loop.learner,i) 

            if x!=nothing
                put!(loop.master.tasks,x)
                unresolved+=1
            else
                close(inch)
            end
        else
            res = take!(loop.master.results)
            tell!(loop.learner,res)
            put!(outch,res)
            unresolved -= 1

            if unresolved==0
                break
            end
        end
        loop.iterhook(loop)
    end
    close(outch)
end

"""
Evaluates until evaluate closes inchannel.
"""
function evaluate(loop::Loop)
    np = nparalel(loop.master)
    
    acc = []
    inch = Channel(np)
    outch = Channel(1)

    @sync begin
        @async evaluate(loop,inch,outch)

        @async while isopen(inch)
            put!(inch,true)
        end
        
        while isopen(outch)
            res = take!(outch)
            push!(acc,res)
        end
    end
    
    return acc
end

"""
Easy way to evaluate master with learner and a stopping condition.
"""
function evaluate(master::Master,l::Learner,stop::Function,iterhook::Function)
    wl = WrappedLearner(l, stop, (x,y)->nothing, (x,y)->nothing)
    loop = Loop(master,wl,iterhook)
    evaluate(loop)
end
evaluate(master::Master,l::Learner,stop::Function) = evaluate(master,l,stop,x->nothing)

"""
Evaluates until evaluate closes inchannel or iterator ends. Could be also used to pass random numbers. 
"""
function evaluate(loop::Loop,iter)
    np = nparalel(loop.master)
    
    acc = []
    inch = Channel(np)
    outch = Channel(1)

    @sync begin
        @async evaluate(loop,inch,outch)

        @async begin
            for i in iter
                if !isopen(inch)
                    break
                end
                put!(inch,i)
            end
            put!(inch,nothing)
        end

        
        while isopen(outch)
            res = take!(outch)
            push!(acc,res)
        end
    end
    
    return acc
end
