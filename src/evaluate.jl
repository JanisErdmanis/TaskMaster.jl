using Transducers

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
        if x!=nothing && unresolved<np && isopen(inch)
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


Looptr(master,learner) = inch -> Channel() do outch
    loop = Loop(master,learner)
    evaluate(loop, inch, outch)
end

"""
Evaluates until evaluate closes inchannel.
"""
function evaluate(loop::Loop)
    inch = Channel(1)
    @async while true
        put!(inch,true)
    end
    inch |> Looptr(loop.master,loop.learner) |> collect
end

"""
Easy way to evaluate master with learner and a stopping condition.
"""
function evaluate(loop::Loop,stop::Function)
    wl = WrappedLearner(loop.learner, stop, (x,y)->nothing, (x,y)->nothing)
    loop = Loop(loop.master,wl,loop.iterhook)
    evaluate(loop)
end

"""
Evaluates until evaluate closes inchannel or iterator ends. Could be also used to pass random numbers. 
"""
evaluate(loop::Loop,iter) = Channel(Map(identity),iter) |> Looptr(loop.master,loop.learner) |> collect
