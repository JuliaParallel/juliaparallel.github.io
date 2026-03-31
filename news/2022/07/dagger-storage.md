@def title = "Storage Changes coming to Dagger.jl"
@def hascode = true
@def date = Date(2022, 07, 01)
@def rss = "Storage Changes coming to Dagger.jl"
@def tags = ["dagger", "storage", "news"]

# Storage Changes coming to Dagger.jl

In my last blog post I wrote about how Dagger.jl, a pure-Julia graph scheduler, executes programs represented as DAGs (directed acyclic graphs). Part of executing a DAG involves moving data around between computers, and keeping track of results from each node of the DAG. When the DAG being executed can fit entirely in memory, this works out excellently. But what happens when it *doesn't* fit?

One common approach is to simply buy more computer RAM, another is to use someone else's (bigger) computer. Sometimes we can just use more computers, and wire them up together (which Dagger is always happy about, since it gets more compute resources to work with). But what if it were possible to get more RAM, without having to *actually* get more RAM? We do have a big blob of memory on most computers, although it's somewhat slow in comparison to RAM, and that is disk (or SSD, or Optane, but let's just call it "disk" for simplicity). Disks often can hold *way* more data than RAM, and they have the sometimes convenient property that they also retain anything written to them across reboots of the computer.

Getting back to our problem, maybe we can use whatever disk is available as extra data storage? That would be awfully convenient: on this computer, for example, instead of having just 16GB of memory available to Dagger, I would love to have an additional 200GB of memory (the amount of space on my disk) available as well. The question is, why doesn't anybody use disk like this?

Well, firstly, almost everybody actually *does* use some of their disk like this, they just might not know it; modern operating systems often carve out a chunk of disk space and treat it like memory, moving less often-used data onto the disk when RAM gets filled up (called "swapping out"). Whenever that data is later accessed, it will be "swapped in" to RAM, and other data swapped out to disk at the same time, so that data being actively accessed can always be accessed as if it were in RAM the whole time.

If the OS already does this, then are we all set? Not exactly - making use of this swapping support requires either that the system administrator (which is not always the same person as the user) configures enough OS swap space to suit the user's needs, or it requires directly allocating memory backed by files on disk. The former makes for a pretty bad user experience when the system configuration doesn't align with the problem requirements. The latter requires invasive changes to code that the user calls to make all allocations go through file-backed memory allocations, which is also a bad user experience. Additionally, if you use the OS' swap support, you're at the mercy of the OS' memory manager to determine which data to evict when your data is swapped in (which might end up harming performance).

Maybe instead of relying on the OS, we should try to do this ourselves. We'll allow the user to allocate their data as usual, and when they're ready for it to become swappable to disk, they'll hand us the objects that they want managed. Hypothetically, if we hold the only copy of a piece of data, we could write it to a file on disk and then drop our copy of the in-memory data, effectively swapping it to disk. We can also do the inverse (read from disk into memory, and delete the file on disk) to swap the data back in. Of course, if we take this approach, the onus is on us to implement a memory manager, but that we means we can also control what decisions and trade-offs are made, making it possible to tune the memory management algorithm to our advantage.

Let's bring this concept back to Dagger to ground it in reality. When Dagger executes a DAG, it has exclusive access to the results of every node of the DAG, meaning that if Dagger "forgets" about a result, Julia's GC will delete the memory used by that result. Similarly, when the user asks for the result of a node, it's up to Dagger to figure out how to get that result to the user, but *how* Dagger does that is opaque, and thus flexible. So, theoretically, between the result being created and the result being provided to the user, Dagger could have saved the result to disk, deleted the copy in memory, and then later read the result back into memory from disk, effectively swapping our result out of and into memory on demand.

The cool thing is, this *was* a theory, but now it's a reality - Dagger has the ability to do exactly this with results generated within a DAG as I just described. More specifically, our memory management library, MemPool.jl, gained "storage awareness" (just like we described above), and Dagger simply makes it possible to use this functionality automatically.

Let's see how we can do this in practice with Dagger's `DTable`. We first need to configure MemPool with a memory manager device. MemPool has a built-in Most-Recently Used (MRU) allocator that we can enable by setting a few environment variables:

```sh
JULIA_MEMPOOL_EXPERIMENTAL_FANCY_ALLOCATOR=1 # Enable the MRU allocator globally
JULIA_MEMPOOL_EXPERIMENTAL_MEMORY_BOUND=$((1024 ** 3)) # Set a 1GB limit for in-memory data
JULIA_MEMPOOL_EXPERIMENTAL_DISK_BOUND=$((32 * (1024 ** 3))) # Set a 32GB limit for on-disk data
```

We can now launch Julia and do some table operations:

```julia
using DataFrames, PooledArrays
using Dagger

strings = ["alpha",
           "beta",
           "delta",
           "eta"]

fetch(DTable(i->DataFrame(a=PooledArray(rand(strings, 1024^2)),
                          b=PooledArray(rand(UInt8, 1024^2))),
             200))
```

Let's now ask MemPool's memory manager how much memory and disk it's using:

```julia
println(MemPool.GLOBAL_DEVICE[])
TODO
```

And we can check manually that our data is (at least partially) stored on disk:

```sh
du -sh ~/.mempool/
TODO
```

This is really cool! With a small amount of code, our table operations suddenly start operating out-of-core and let us scale beyond the amount of RAM in our computer. In fact, it's possible to scale even further with some tricks. In the example above, some of the data being stored is pretty repetitive; maybe we can get a bit fancy and compress our data before storing it to disk? Doing this is easy, we just need to tell MemPool to do data compression and decompression for us automatically:

TODO: Demo of inline data compression/decompression
```julia
# In a fresh Julia session
using DataFrames, PooledArrays, Dagger
using MemPool, CodecZlib

# Enable automatic compression (globally)
push!(MemPool.GLOBAL_DEVICE[].filters, GzipCompressorStream=>GzipDecompressorStream)

fetch(DTable(i->DataFrame(a=PooledArray(rand(strings, 1024^2)),
                          b=PooledArray(rand(UInt8, 1024^2))),
             1024))
```

Amazing, we've cut down TODO% of the disk space needed to store our data!

However, there's a wrinkle to this magic: what if we're working with sensitive data (maybe healthcare PHI, or social security numbers), and we need to make sure that our data is encrypted whenever it's stored on disk? Right now, anyone with read access to our file could read it into their Julia session and decode all of our sensitive information. Thankfully, solving this problem is as easy as implementing seamless compression, and actually cooperates with it pretty nicely:

TODO: Demo of inline data encryption/decryption

The only cost we pay for all of this auto-compressing, auto-encrypting convenience is a little bit of CPU overhead when writing and reading:

TODO: Show breakdown of costs of out-of-core: plain, w/compression, w/encryption, w/compression+encryption

## Reading from files

The above shows how we can swap out data that's already in-memory, which is great when that matches your use case. But what about when your data is already on disk? Do you have to read everything in manually just to hand it to MemPool (and thus duplicate all of that disk space)? Of course not! MemPool supports passing a file handle to `poolset`, which will be provided to the device to work with. MemPool also supports "retaining" on-device data, which is to say that MemPool won't automatically delete your data from disk when you're done using it. These two features combine nicely to make working with existing on-disk datasets easy:

```julia
using CSV, MemPoolCSV

files = readdir("path/to/csvs")
dt = DTable(path->Dagger.tochunk(nothing; device=LazyFileDevice(CSVStorageDevice(path)),
                                          retain=true,
                                          handle=path,
                                          inmem=false), files)
```

Wait a second, why wouldn't you just directly load the CSV in the callback passed to the `DTable` constructor? Because laziness, my friend! Let's make up a philosophical business use case to help explain:

You're a member of an organization that stores one CSV file for stock trading data of each hour of each day that goes back 10 years. Each CSV doesn't have many rows (let's say 1 per minute, so 60 rows), but each row is pretty big (covering every publicly-traded stock in every national market). Your organization typically accesses just a few days worth of data at a time (to display historical stock tickers and other metrics), and so splitting data like this can make a lot of sense. Additionally, because of its size, this data on a big, slow networked disk array. So you can imagine that each time you touch the disk to read a file, it's pretty expensive.

Your job is pretty straightforward: you're building a program which allows your organization's analysts to interactively process all of this data on a big computer cluster, doing various operations on windows over the data. In your excellent wisdom, you plan to use Dagger and its `DTable` to process this data to save you from having to write all of the parallel processing code from scratch. Thanks to good organizational practices, you can determine the path to each file that you're interested in, allowing you to write a simple Julia generator to generate the file paths for every file in the historical archive.

Now, if you just naively passed all of those files paths into the `DTable` constructor (which then calls `CSV.File` on each one), you would be opening and parsing `10 years * 365 days * 24 hours = 87600` files; if each file takes 1 millisecond to open and parse (*very* wishful thinking), your users would still end up twiddling their thumbs for over a minute. Of course, on a busy day, the network might be more congested and result in per-file average load times of 50 ms, which implies sitting around for about 73 minutes just to get all the files parsed; this is, of course, unacceptable!

If you instead use an invocation like the above (using all the fancy flags to `Dagger.tochunk`), your per-file times would look more like 100 nanoseconds, *irrespective* of how slow the networked filesystem is, leading to a comfortable wait time of 8 milliseconds. How is this possible?! By cheating :) Instead of loading the file on the spot, this invocation just registers the path within MemPool's datastore, and only later (when a read of the data for a file is attempted) is the file actually opened and parsed. This means that if you never ask MemPool to access a file's data, it will never pass it to CSV.jl to be opened and parsed, so your program's users never have to spend time waiting on loading data that they don't use.

{{addcomments}}
