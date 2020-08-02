# In sequential case one can drive the system with for loop:

while !(learner.loss() < step)
    xi = ask!(learner,true)
    yi = f(xi) 
    tell!(learner,(xi,yi))
end

# However when paralelism is taken into account it gets a bit more complex

tasks = Channel()
results = Channel()

unresolved = 0 
while true

    if !(learner.loss() < step)

        xi = ask!(learner,true)
        put!(tasks,xi)
        unresolved += 1

        if unresolved < N
            continue
        end
    end

    if unresolved == 0
        break
    end

    yi = take!(results)
    tell!(learner,xi)
    unresolved -= 1
    
end

using Adaptive
using TaskMaster

@everywhere f(p) = exp(-p[1]^2 - p[2]^2)

master = WorkMaster(f)
learner2d = AdaptiveLearner2D([(-3,+3),(-3,+3)])
loop = Loop(master,learner2d)
evaluate!(loop,learner->learner.loss()<0.05)
