```@meta
EditURL = "@__REPO_ROOT_URL__/"
```

A very daunting thing to programm is a feedback loop with paralelism. Paralelism introduces stochasticity and thus debugging a feeback loop or the part which learns in such system is painful. On the other hand we have so many different kinds of systems which implments paralelism - processes, threads, GPUs, job schedulers, GRID and etc. And so one ends up writting non-rusable code a case by a case.

A TaskMater is an abstraction for all of thoose issues. A two important concepts are used for such system - Master and Learner. Master is a process which takes input values from a channel Master.tasks and evaluates in an arbitrary fashion/order and puts that in Master.results channel as a tuple (input,output). One make a concrete implementation which usses processes, threads, GPUs, TPUs, job scheduler and etc for evaluation. Or one can treat Master as some process which commes from an experimental equipment, for example, from a multihead scanning tuneling microscope. Or one could try to find optimal parameters for plant growth where paralelism is very natural.

The other concept it Learner which tries to learn from the Master by learner asking questions and master telling answers. The nature is that master has multiple questions an he answers them in arbitrary order. Thus the learner needs to be smart to optimize the objective. Again the learner could be a computer program, animal (if you can teach them paralelism), or a human pressing buttons.

Particularly in the case of a computer program there are quite a variety. There is a class of learners where programmer had programmed all cases how the system should behave. A very great example is made by my Python collegues in adaptive package which allows adaptive function evaluation for reducing computational needs to make a nice figure (see Adaptive.jl for a wrapper). Other type of learners had been brainstrormed in this issue. The other class which might gain a traction is a machine learned learner, for example, a plant state recognition algorthm with some ML to optimize the growth.

# Interface

For what follows we need to load and execute

```@example index
using Distributed
addprocs(2)
```

before loading TaskMaster. That would give us two workers to proceed.

To load the package install it from the Julia main registry and execute:

```@example index
using TaskMaster
```

further on we assume that it is loaded.

## Learner

To see how to implement Learner let's consider IgnorantLearner from the package. To initiate it we do:

```@example index
learner = IgnorantLearner(1:4)
```

The first part of the interface is ask! part. To ask a point we execute:

```@example index
x1 = ask!(learner,4)
x2 = ask!(learner,2)
```

x1 and x2 now would give us points which learner thinks as most benefitial to reach the objective. The numbers 4 and 2 represent the input, for example, a random number in that purifying learner from randomness. That is particularly useful when one wants to debug the learner from output values allone (see debugging section).

The second part of the interface is telling about masters evaluated points to learner. Let's say that y1 and y2 represents the resluts of evaluation. Then to tell learner about them we do:

```@example index
tell!(learner,(3,9))
```

Which would affect the state of the learner giving us better predictions on where interesting things would happen even when x1 is not yet evaluated. (That is the reason why ask is written with exclamaition mark ask!). Ignorant learner as the name implies would ignore this knowledge and would proceed with evaluating points given by iterator.

## Master

To see how Master works let's consider ProcMaster from the package. To initiate it we need to define a function on all workers and then start master:

```@example index
@everywhere f(x) = x^2
master = WorkMaster(f)
```

Now we can evaluate the function with specific values as simple as:

```@example index
put!(master.tasks,3)
put!(master.tasks,5)
```

And take out the results:

```@example index
take!(master.results)
```

And that is all what master does! As one can see it is pretty obvious to make ThreadMaster and different implentations.

## Loop

The third and the final concept is the Loop which represents execution of master on the loop. That can be initated as follows:

```@example index
master = WorkMaster(f)
learner = IgnorantLearner(1:10)
loop = Loop(master,learner)
```

Also if one wishes to follow the learning process it is possible to pass an function `iterhook(loop)` which is executed in every iteration with constructor `Loop(master,learner,iterhook)`.

Now the main part is the execution. If one knows the collection beforehand on what one wants to execute the loop (so it is finite) one can do:

```@example index
output1 = evaluate!(loop,1:4)
```

Often however one wants to learn until some convergence criteria is being met. That one can also do by passing a stopping condition which is executed every time before a new point is asked:

```@example index
output2 = evaluate!(loop,learner->learner.state==7,5:9)
```

which will terminate when the laerners state would be 7. A note is that evaluate would continue to execute the previous state of the loop (thus exclamation mark !).

## Debugging learner

Let's imagine a situation where one had spent hours at evaluating the function with a learner. For some particular reason looking at the ouptut the Learner seems had misbehaved. The question then is how could you debug that?

A way the package overcomes such pitfall is by ensuring deterministic process of `evaluate!` function which communicates with Master (this is why it is important that `ask!` does not have stochasticity inside). That allows to replay the history and explore the learners state as it evolved.

In TaskMaster that is implemented with `HisotyMaster` type. To see how to use it let's apply it on the previous execution:

```@example index
output = [output1...,output2...]
master = HistoryMaster(output,2)
```

where 2 is the number of unresolved points which were allowed during the original Masters run. Now to repeat the history we do:

```@example index
learner = IgnorantLearner(1:10)
loop = Loop(master,learner,loop->@show loop.learner.state)
evaluate!(loop,learner->learner.state==7,1:9)
```

As you can see the `iterhook` makes a lot of sense for debugging. Also HistoryMaster could be usefull to write tests for Learner so when code changes one would imediatly see the effects of that.

