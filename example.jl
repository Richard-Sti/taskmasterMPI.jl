import MPI

# Later directly import
import Pkg: activate
activate("./TaskmasterMPI/.")
using TaskmasterMPI


MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)

# Example function we would like to evaluate
f(x) = sleep(rand())


if rank == 0
    tasks = Vector(1:100)
    master_process(tasks, comm)
else
    worker_process(f, comm, verbose=true)
end


MPI.Barrier(comm)
if rank == 0
    println("We're all done!")
end
