@def title = "Comments on the Julius Graph Engine Benchmark"
@def hascode = true
@def date = Date(2022, 07, 01)
@def rss = "Comments on the Julius Graph Engine Benchmark"
@def tags = ["dagger", "benchmarks", "news"]

# Comments on the Julius Graph Engine Benchmark
\toc

### Introduction

![Shipping goods over the sea via ocean freighter](https://thumbnails.production.thenounproject.com/GZSNSq5eKQqKDoHfKGOFmb5QT4s=/fit-in/1000x1000/photos.production.thenounproject.com/photos/6D93E0C1-DFF3-410B-8086-214D12A2D362.jpg)
##### Public domain image courtesy of https://thenounproject.com/carolhighsmith/

Scheduling is a hard problem, but it's a necessary evil for modern civilization:

- Moving perishable goods quickly from producer to consumer
- Tracking and re-routing aircraft to prevent collisions while optimizing flight paths
- Planning traffic light timings to avoid gridlock

In the space of computing, we often have lots of different kinds of tasks we need to complete, but only a few computing resources to fulfill these tasks. There are plenty of naive ways to do scheduling, from round-robin to FIFO and LIFO, and these can work out well when your tasks and computing resources are homogeneous. But life is rarely so simple; tasks can be small or large and can have dependencies on each other, and computing resources aren't all alike (e.g. CPU vs. GPU). Using a naive scheduling algorithm for such problems is a recipe for sitting around, waiting for an analysis or computation to complete. Thankfully, there exist smarter schedulers, like Dask, Ray, and Dagger.jl, which are able to handle heterogeneous task scheduling effectively through resource queries, runtime metric collection, and other smart ideas.

In this blog post, we'll introduce you to a benchmark of some of these schedulers, and walk you through how I optimized Dagger.jl's scheduler to more efficiently run the benchmark. I'll also introduce you to a new proprietary scheduler platform offered by a Julia-focused startup, and show how it stacks up against the open-source schedulers. I'll finally give some ideas for problems that these schedulers can solve effectively, which will help you understand how these schedulers can support your computational needs.

### The Julius Scheduler Benchmark

In the last few weeks, it came to my attention that [Julius Technologies](https://www.juliustech.co/), a Julia-focused startup, published a [benchmark](https://juliustechco.github.io/JuliusGraph/dev/pages/t007_benchmark.html) of their "Graph Engine", which is a proprietary low/no-code programming platform, likely written in Julia. They compared the performance of their platform on two kinds of benchmarks, and provided equivalent benchmark scripts written for Dask, TensorFlow, and Dagger.jl. The benchmark showed a very wide margin in runtimes between Julius Graph Engine (which I'll call "JGE") and the competition, with JGE coming in more than an order of magnitude faster, and scaling near-linearly. Notably, Dask and Dagger showed very poor performance, and weren't able to complete most of the benchmark, only working on smaller scales.

As the maintainer of Dagger.jl, I have skin in this benchmarking game. Most users of Dagger came to it under the premise and with the promise of fast heterogeneous programming. Since these results showed that Dagger struggles with executing certain common kinds of programs, I decided to spend a few days tweaking Dagger to get the performance that I’d want. All of the changes that I’ll be describing in this post are going upstream to Dagger in one way or another. In this blog post, I'll introduce you to graph engines and how their schedulers work, I'll talk about how I profiled Dagger's runtime costs, and I'll walk you through how I brought Dagger's benchmark runtime down to within 10x of Julius' product offering.

(Side Note: Julius has since updated their benchmark showing Dagger doing much better (thanks to improvements spurred by their benchmark), but I've kept my original benchmark results below for the purpose of explanation.)

#### Aside: Scheduling for Graph Engines

Let's back up for a second: why should you care? What is a "graph engine", and what does it have to do with scheduling? Starting from the top: A "graph engine" is just a fancy way of talking about a program which executes code represented as a Directed Acyclic Graph, or DAG. Any program you've ever written can probably be represented as a DAG; the vertices of the DAG are typically basic operations, such as arithmetic or memory access, while the edges of the DAG represent calls between functions, or control flow like `for`-loops or `try-catch` blocks. For an example of this (using Dagger), see [this documentation section](https://juliaparallel.org/Dagger.jl/dev/#Simple-example).

You can even see this with regular Julia code: when Julia code is "lowered" by Julia's frontend, it's converted into a graph for later analysis and compilation, although it's not guaranteed to be acyclic (and if you write a `for` or `while` loop, it's definitely not acyclic). This lack of cyclicity can be worked around by "unrolling" a cyclic directed graph into an acyclic equivalent, and doing lots of copy-pasta of the code within each graph cycle. Importantly, this isn't a trivial thing to do *efficiently*, so it's still an active area of research and development for graph engines. The schedulers that underlie graph engines sometimes have built-in fast paths for such cases, but in the absence of those, having low scheduling overhead is paramount to acceptable performance.

What about all those other kinds of schedulers that I pointed out in the intro? Well, schedulers for other use cases don't necessarily compare well with graph schedulers, because they're solving fundamentally different problems, and thus doing different classes of scheduling. So for the rest of this post, all of the schedulers that we'll be looking at are designed for graph execution, so we can compare "apples to apples".

### Benchmark Results - Prelude and Interpretation

Anyway, that's enough background. Let's scrutinize this benchmark a bit more, because at first guess, we shouldn't expect a newcomer to the graph scheduling space to handily beat out two different production Python schedulers and a pure-Julia scheduler (and kudos to Julius for pulling that off). The benchmark has two parts, which they call [`s_n`](https://juliustechco.github.io/JuliusGraph/dev/assets/widegraph.png) and [`y_n`](https://juliustechco.github.io/JuliusGraph/dev/assets/deepgraph.png) ([details here](https://juliustechco.github.io/JuliusGraph/dev/pages/t007_benchmark.html#Benchmark-Setup-1)). The `s_n` benchmark tests DAGs which are really "wide", which means that a single node has a lot of other directly-connected nodes. The `y_n` benchmark tests DAGs which are really "deep", which means that there is a really long path from start to finish (going through many different nodes). The core or "kernel" of each benchmark is a `fibsum` function, which is very cheap (two multiplies and one add per each of 10 array elements). This kind of setup is a pretty common way to stress-test graph schedulers, since it exposes the cost of every little part of scheduling that isn't directly executing the user's functions. In other words, it effectively exposes the overhead of the scheduler being used.

Something else that we need to understand about this benchmark is that the four graph schedulers included are not all alike. One of the most important ways that schedulers can be compared is "visibility"; can the scheduler see the entire DAG before it starts executing, or does it only get bits and pieces as it goes along executing? This is an important consideration because being able to see the full DAG means that it's easy to perform optimizations on it, such as combining repetitive sub-graphs with a `for`-loop (basically undoing the "unrolling" of the graph so that the language's compiler can better optimize the whole sub-graph). Constructing the whole graph also incurs memory overhead, because the entire graph needs to exist in memory at some point in time; in certain cases, it can be prohibitively expensive just to construct the graph (let alone to actually execute it).

From what I understand, the JGE requires visibility into the whole DAG before execution begins; the same is also true for TensorFlow. Dask, instead, only sees parts of the DAG, as it is being built. I will term these two modes "ahead-of-time" (AOT) and "just-in-time" (JIT), respectively (these are often also referred to as "static" and "dynamic", respectively). So what does Dagger do? Well, in the benchmark, Dagger is being used in JIT mode, although it also supports an AOT mode. JIT mode (using `@spawn` and `fetch`) is recommended for most users, as it is often easier to use, and doesn't require knowledge of the full graph before execution can begin. However, AOT mode (using `delayed` and `compute`) has the benefit of being very efficient at consuming a fully constructed DAG, and can use less memory at runtime for reasons I won't get into here.

#### Comparison: What graph-building modes are supported?

| Feature | Dask | Ray | Dagger.jl | JGE | TensorFlow | Cilk | Vanilla Julia |
| :-- | :--: | :--: | :--: | :--: | :--: | :--: | :--: |
| AOT (static) | :heavy_check_mark: | :heavy_check_mark: (Actors) | :heavy_check_mark: (`delayed`) | :heavy_check_mark: | :heavy_check_mark: (TF 1.x) | :x: | :x: |
| JIT (dynamic) | :x: | :heavy_check_mark: (Tasks) | :heavy_check_mark: (`@spawn`) | :x: | :heavy_check_mark: (TF 2.x) | :heavy_check_mark: | :heavy_check_mark: |

There was also a minor issue with the benchmark that I noticed for Dask and Dagger that could possibly give them an unfair advantage over TF and JGE (which I've reported to Julius, who kindly updated their benchmark results). Specifically, the benchmarking script doesn’t wait on the launched computations to complete. This is a simple matter of calling `f2.compute()` and `fetch(f2)` for Dask and Dagger respectively, to force the execution of the full graph and the retrieval of the final result.

### Benchmark Results

For a quick comparison, I chose to briefly switch Dagger into AOT mode to get a better idea of how Dagger directly compared to JGE, and also how it compared with Dagger's JIT mode (Dask also added for comparison, and extra-long runs are excluded):

#### Comparison: Initial results on `s_n` (in seconds)

| # of Iterations | Dagger AOT | Dagger JIT | Dask |
| :-- | :--: | :--: | :--: |
| 1000 | 34.108724 | 4.031126 | 1.6458556 |
| 5000 | :x: | 123.653653 | 30.8954490 |
| 10000 | :x: | :x: | 136.261454 |

(An :x: implies that the benchmark took too long to complete)

#### Comparison: Initial results on `y_n` (in seconds)

| # of Iterations | Dagger AOT | Dagger JIT | Dask |
| :-- | :--: | :--: | :--: |
| 1000 | 0.136007 | 3.378034 | 1.5771625 |
| 5000 | 0.771038 | 128.213972 | 31.0315958 |
| 10000 | 1.184655 | :x: | 133.501586 |
| 100000 | 13.019151 | :x: | :x: |
| 200000 | 27.982819 | :x: | :x: |
| 500000 | 73.965525 | :x: | :x: |

As we can see, AOT mode is *much* better than JIT mode on the `y_n` benchmark. AOT mode has some issues on the `s_n` benchmark, but that's due to splatting not being efficient at large scales in AOT mode (which is part of why I advise against using AOT mode). Still, regardless of the improvements from switching to AOT mode for `y_n`, I was disappointed by Dagger's performance in JIT mode, so I decided to continue investigating what I could do to improve that. The rest of this post will thus focus on Dagger's JIT mode.

### Oh No! Can we fix it?

Thankfully, the poor performance exhibited by Dagger is actually just the result of a lack of detailed optimizations in a select few (hot) code paths, which lead to slowdowns which dominate the majority of time that the benchmark was executing. Of course, all of these issues are now fixed on Dagger's `master` branch by the time this blog post reaches your eyes, but let's review what I fixed, just so you know that I'm not pulling a fast one on you.

First, how did I find out what was slowing things down? Easy answer (and if you've used Julia to do anything performance-sensitive, you can probably guess): `Profile.@profile`. The `Profile` stdlib uses a statistical profiler to help us find where in our code we're spending the most amount of time, and is immensely useful for finding hot code paths in Julia code[^1].

Ok, so we've got a way to see where and how our execution time was being spent; what did I actually find?

### First Fix: Object Size Calculation

Let's start with the most eggregious offender first: `Base.summarysize()`. This function is simple: it calculates approximately how much memory a given object takes, including every other object it directly or indirectly references. Unfortunately, it is also very slow; because it's recursive, it needs to be able to detect cyclic references, and handles every kind of object that could ever be passed to it with good latency. Furthering the unfortunate situation, our dependency package MemPool.jl calls this function every time a Dagger task produces a result (in `MemPool.poolset`, if you're wondering). If that happens many times, and/or if the objects passed in are somewhat large and complicated, then we'll see this function taking a large proportion of our runtime. And this was exactly what I saw; more than 37% of our runtime was spent here on the 1000-deep run, which is absolutely atrocious (and it gets worse as the depth grows).

So, what can we do about this? The specific case where this was occuring is in `add_thunk!`, which is where new tasks are generated and added to the scheduler. Here, thankfully, `MemPool.poolset` is being called on a small-ish task object for GC purposes; however, the size will not be used, because task objects can't be serialized over the network or to disk (the only two cases where size is used). To completely eliminate calls to `Base.summarysize()` when we don't want it called, we can just manually specify a size for the object being passed to `MemPool.poolset`, avoiding the `Base.summarysize()` call entirely. Therefore, we can safely pass any arbitrary size value to disable the automatic `Base.summarysize()` call.  With [that change](https://github.com/JuliaParallel/Dagger.jl/commit/2f47217c29e4ac9b2f0921df7bc18bdfe4356e2b), how do we fare?

| # of Iterations | Dagger JIT on `s_n` | Dagger JIT on `y_n` |
| :-- | :--: | :--: |
| 1000 | 0.899850 | 0.947113 |
| 5000 | 16.065269 | 13.962618 |
| 10000 | 65.198173 | 66.801668 |

Ok, that's much better! At 10000 depth, we shaved off about 50% from each benchmark! But we're still showing abysmal scaling, so what's next?

### Second Fix: Node Memoization

The next improvement came from how task dependencies are resolved. The `add_thunk!` function calls `reschedule_inputs!` to ensure that all "upstream" dependencies of a given task are satisfied before getting the task ready to be scheduled. While this function was recently optimized due to reported scaling issues, it's still far too slow, mostly because it recursively walks up the dependency chain until it finds that all upstream tasks are actively executing or finished executing. That's pretty silly; while not everything upstream is executing, that doesn't mean we need to keep walking through those tasks everytime we add a new task further down the DAG. What I chose to do was add a memoization dictionary to the scheduler that, when a task has been through `reschedule_inputs!` or an equivalent code path, holds an entry to that task to mark that it's not necessary to traverse it again. This was a [reasonably simple improvement](https://github.com/JuliaParallel/Dagger.jl/commit/c17b86d13423351617c7a68ff2d5dafd27d7d32a), trading a bit of memory for massively decreased execution overhead, leading us to these results:

| # of Iterations | Dagger JIT on `s_n` | Dagger JIT on `y_n` |
| :-- | :--: | :--: |
| 1000 | 0.452218 | 0.577350 |
| 5000 | 5.234815 | 4.086071 |
| 10000 | 18.304120 | 14.707820 |

Nice, we just cut out 72% of the `s_n` runtime and 78% of the `y_n` runtime. We're making good progress, but let's keep going!

### Third Fix: Domination Checks

Still looking at the same region of code, we find that we're spending a lot of runtime in validating that our graph is actually acyclic. More specifically, the `register_future!` function is called from `add_thunk!` to register a `Distributed.Future` that will be filled with the result of the newly-created task once it's done executing, allowing the user to wait on and fetch the task result. This function needs to be somewhat defensive, though, when being called from one task targetting another. If a task tries to register and wait on a future for some other task that is downstream of itself, it will wait forever, because that downstream task won't execute until the task waiting on it completes (thus, a deadlock occurs). Similarly, a task shouldn't be able to wait on itself. To avoid this, `register_future!` checks whether the calling task "dominates" the targetted task; when a task A dominates a task B, that means that the completion of A is necessary before the execution and completion of B can occur. If the calling task dominates the target task, then an error is thrown, preventing accidental deadlock. This check is well-intended, but is also slow; thankfully, when adding tasks with `add_thunk!`, we generally can assume that this new task isn't going to be waited on by a downstream task (it's possible, but a careful developer can trivially avoid it; we shouldn't burden them with unnecessary checks). To alleviate this, I simply added a kwarg to `register_future!` that will by default do the domination check, but can allow it to be manually disabled. For `@spawn`, which implicitly calls `add_thunk!`, we disable the check, because in common usage of that API it's not easy to cause deadlocks[^2]. [This change](https://github.com/JuliaParallel/Dagger.jl/commit/d543c23815de79ae39616045aa1ee285665c014c) gives us the following excellent results:

| # of Iterations | Dagger JIT on `s_n` | Dagger JIT on `y_n` |
| :-- | :--: | :--: |
| 1000 | 0.201789 | 0.223203 |
| 5000 | 1.216356 | 1.173638 |
| 10000 | 2.711312 | 2.428500 |
| 100000 | 25.743532 | 28.761774 |
| 200000 | 59.582494 | 64.312516 |
| 500000 | 201.391146 | 225.147642 |

Wow, that's about 84% faster!

This is a good time to stop; trimming down everything else in the profile trace will likely require optimizations that fundamentally affect Dagger's semantics, which are waters that I don't want to wade through just to win a benchmark. With all of these changes in place, the final benchmark that I ran can be found at [this link](https://gist.github.com/jpsamaroo/95c78b3361ae454a51916183f2cf346f) (and make sure to run with Dagger's `master` branch, where all these performance enhancements are now available!).

### Giving credit where credit is due

We've spent a lot of time discussing how Dagger can be made to compete better, but let's put that aside for a moment to be realistic and give credit where it's due; the work that Julius has done to make low/no-code programming both productive and performant in Julia (while expertly leveraging the many strengths of the language) is quite exceptional. The problem that their product is solving is one that us programmers often like to forget: programming is *hard* and it's *cumbersome*, and we all sometimes take that for granted when considering the best way for non-programmers to contribute their domain expertise to a business' success. It's easy to say, "Why don't you just learn to program?", but it's so much harder to actually learn even the bare basics (and yet more work to become proficient enough to make all this learning pay off). The Julius Graph Engine and its frontend UI environment cuts out the "cruft" of traditional programming, and lets domain experts do what they are lauded for without having to struggle on programming concepts that they didn't spend their entire schooling and careers training for.

I know many of us in the Julia community understand this plight, and most of us had to just endure the pain and struggle the struggle to get to the point where we could express our knowledge in the form that our favorite language demands it to be written. While it's not particularly helpful to ask "what if's" about what our future would have looked like if JGE had shown up a bit earlier, we can look toward the future and help Julius build out their product to provide the power of Julia's amazing ecosystem of packages in a form that everyone can enjoy.

### Debrief

Let's recap briefly what we've covered over the course of this post: I introduced Julius and their Graph Engine product, explained the basics of graph scheduling, showed off Julius' multi-faceted DAG benchmark, and walked you through how I optimized Dagger to bring our benchmark runtime down from "terrible" to "pretty damned good" through a few different optimizations:

- Avoiding automatic size calculations when object size is irrelevant
- Using memoization to prevent re-walking sections of the DAG
- Disabling graph cyclicity checks when unnecessary

!!! note All of these changes are valid because we make certain simplifying assumptions about how code will be executed. If those assumptions stop holding, then we'll have to reconsider the correctness of these optimizations (which is quite similar to the question of when to use `@inbounds` in library code).

We also recognized that Julius' product offering is a powerful alternative to Dagger, especially for organizations which desire a low/no-code interface and strong performance on very large graphs (among other features).

### Conclusion

All of this leads us to a final question: what can Dagger do for you? Maybe you have a lot of images of different sizes that you want to shrink down to thumbnails, while utilizing GPUs where possible. Or you might have many matrices that need to have their eigenvalues calculated with an iterative approach, which can take differing amounts of time. If you're a data scientist, you may have large tables that need processing that you can split into chunks and process independently. You might be developing a SaaS application and need a way to execute "serverless" functions on event triggers.

#### Comparison: Important graph scheduler features

| Feature | Dask | Ray | Dagger.jl | JGE | TensorFlow | Cilk | Vanilla Julia |
| :------ | :--: | :-: | :-------: | :--------: | :--: | :--: | :--: |
| Multithreading | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Distributed | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |:heavy_check_mark: | :x: | :heavy_check_mark: |
| GPUs    | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :x: | :heavy_check_mark: | :x: | :heavy_check_mark: |
| Mutability | :x: | :heavy_check_mark: (Actors) | :heavy_check_mark: (`@mutable`) | :x: | :x: | :heavy_check_mark: | :heavy_check_mark: |

There are so many possibilities, and Dagger strives to handle all of them efficiently.If your problem sounds even remotely similar, Dagger might be the right choice for you. If you aren't sure if Dagger will suit your needs, please reach out to me; my contact information is below!

### Aside: Future work and collaboration

I must admit, I wasn't sure whether Dagger was going to be able to compete with JGE's performance, but clearly we're now getting pretty close! Of course, there's still more work to do to bring down these times even further, but that can be left for another day and maybe for another contributor. Speaking of which: if this post has gotten you interested in contributing a bit to Dagger (even just some small things like adding some docs, tests, or examples), I'd love the help! Improvements like these aren't too hard to accomplish in an afternoon or two, but can make a huge difference for our users. If you decide that you'd like to help out, please drop me a line!

In the process of writing this post, I think I made it reasonably clear that graph schedulers are both simple yet simultaneously complicated beasts which rely on good performance engineering to get good runtime performance. Going forward, I'd like to cover other Dagger-related topics, such as the upcoming storage changes (aka "swap-to-disk"), and how to use Dagger and DaggerGPU for seamless GPU computing (among many other possible topics). If you have any ideas for a post that you'd like to read about, please message me with your thoughts!

### Contact Information

I'm `@jpsamaroo` on Slack, Zulip, or Discourse, and my email is jpsamaroo -AT- gmail -DOT- com. On Slack, Dagger questions are well-suited for the `#helpdesk`, `#multithreading` and `#distributed` channels.

[^1]: `Profile.@profile myfunc(...)` runs `myfunc(...)` as usual, but also runs a background statistical profiler while the code is executing. This profiler will stochastically sample stacktraces from the running function, which can later by collected and processed by `Profile.print()`. The result of `Profile.print()` is essentially a view of all collected stacktraces overlayed on top of each other; this gives you a full view of *what* was happening at some point during `myfunc`'s execution. It also shows a counter next to each stackframe (approximately each function call), which shows you *how often* a given code location was hit. Combined with the count of the total number of stacktraces collected (shown at the bottom), it's possible to get an idea of what percentage of `myfunc`'s execution time was caused by each of its components, no matter how far down in the call stack you look.

[^2]: Julia's native multitasking system also does not provide this check, even though it's fully possible to cause deadlocks in exactly the same way, yet this isn't considered an issue with Julia's multithreading system because the user is doing something that doesn't make semantic sense.

{{addcomments}}
