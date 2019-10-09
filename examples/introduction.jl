# # Introduction

# A very daunting thing to program is a feedback loop with parallelism. Parallelism introduces stochasticity and thus debugging a feedback loop, or the part which learns in such a system is painful. On the other hand, we have so many different kinds of systems which implement parallelism - processes, threads, GPUs, job schedulers, GRID, etc. And so one ends up writing non-reusable code a case by a case.

# A TaskMater is an abstraction for all of those issues through two critical concepts - Master and Learner. Master is a process which takes input values from a channel `Master.tasks` and evaluates in an arbitrary fashion/order and puts that in `Master.results` channel as a tuple (input, output). One makes a concrete implementation which uses processes, threads, GPUs, TPUs, job scheduler, etc. for evaluation. Or one can treat Master as some process which comes from a piece of experimental equipment, for example, from a multi-head scanning tunnelling microscope. Or one could try to find optimal parameters for plant growth where parallelism is very natural. 

# The other concept is Learner which tries to learn from the Master by asking questions and receiving answers. Nature is that Master has received multiple questions, and he answers them in arbitrary order. Thus the Learner needs to be smart to optimize the objective. Again the Learner could be a computer program, animal (if you can teach them parallelism), or human pressing buttons.

# Particularly in the case of a computer program, there is quite a variety. There is a class of learners where the programmer had programmed all cases of how the system should behave. My Python colleagues make a very great example in the [adaptive package](https://github.com/python-adaptive/adaptive), which allows adaptive function evaluation for reducing computational needs to make a beautiful figure (see Adaptive.jl for a wrapper). Another type of learners had been brainstormed in [this reedit](https://www.reddit.com/r/dataisbeautiful/comments/b8vv2p/i_wrote_a_python_package_to_do_adaptive_sampling/). The other class which might gain traction is a machine-learned Learner, for example, a plant state recognition algorithm with some ML to optimize the growth.

# # Interface

# For what follows we need to load and execute:
using Distributed
addprocs(2)
# before loading TaskMaster. That would give us two workers to proceed.

# To load the package, install it from the Julia central registry and execute:

using TaskMaster

# further on, we assume that it is loaded.

# ## Learner

# To see how to implement Learner, let's consider IgnorantLearner from the package. To initiate it, we do:
learner = IgnorantLearner(1:4)

# The first part of the interface is asking part. To `ask!` a point we execute:

x1 = ask!(learner,4)
x2 = ask!(learner,2)

# x1 and x2 now would give us points which Learner thinks as most beneficial to reach the objective. The numbers 4 and 2 represent the input, for example, a random number in that purifying Learner from randomness. That is particularly useful when one wants to debug the Learner from output values alone (see debugging section).

# The second part of the interface is telling about masters evaluated points to Learner. Let's say that x2=3 and thus y2=9 represent the results of the evaluation. Then to tell Learner about them we do:

tell!(learner,(3,9))

# Which would affect the state of the Learner, giving us better predictions on where exciting things would happen even when x1 is still being evaluated. (That is the reason why ask is written with exclamation mark ask!). Ignorant Learner as the name implies would ignore this knowledge and would proceed with evaluating points given by iterator.

# ## Master

# To see how Master works, let's consider WorkMaster from the package. To initiate it, we need to define a function on all workers and then start Master:

@everywhere f(x) = x^2
master = WorkMaster(f)

# Now we can evaluate the function with specific values as simple as:

put!(master.tasks,3)
put!(master.tasks,5)

# And take out the results:

take!(master.results)

# As one can see, it is pretty apparent to make ThreadMaster and other different kinds of Master implementations.

# ## Loop

# The third and the final concept is the Loop which represents the execution of master on the Loop. That can be initiated as follows:

master = WorkMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,learner)

# Also if one wishes to follow the learning process, it is possible to pass a function `iterhook(::Loop)` is executed in every iteration with constructor `Loop(::Master,::Learner,iterhook(::Loop))`.

# Now the central part is the execution. If one knows the collection beforehand on what one wants to execute the Loop (so it is finite) one can do:

output1 = evaluate!(loop,1:4)

# Often, however, one wants to learn until some convergence criteria are being met. That one can also do by passing a stopping condition which is executed every time before a new point is asked:

output2 = evaluate!(loop,learner->learner.state==7,5:9)

# which will terminate when the Learner's state would be 7. A note is that evaluate would continue to execute the previous state of the Loop (thus exclamation mark !).

# ## Debugging Learner

# Let's imagine a situation where one had spent hours evaluating the function with a Learner. For some particular reason looking at the output, the Learner seems had misbehaved. The question then is how one could debug that?

# A way the package overcomes such pitfall is by ensuring a deterministic process of `evaluate!` function which communicates with Master. This is why it is crucial that `ask!` does not have stochasticity inside but if needed, takes that from the input. That allows us to replay the history and explore the Learner's state as it evolved.

# In TaskMaster that is implemented with `HisotyMaster` type. To see how to use it, let's apply it on the previous execution: 
output = [output1...,output2...]
master = HistoryMaster(output,2)
# where 2 is the number of unresolved points which were allowed during the original Masters run. Now to repeat the history, we do:
learner = IgnorantLearner(1:10)
loop = Loop(master,learner,loop->@show loop.learner.state)
evaluate!(loop,learner->learner.state==7,1:9)
# As you can see the `iterhook(::Loop)` makes a lot of sense for debugging. Also, HistoryMaster could be useful to write tests for Learner, so when code changes, one would immediately see the effects of that. 
