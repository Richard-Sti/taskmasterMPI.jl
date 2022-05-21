module TaskmasterMPI

import MPI


export get_free_worker, tag, master_process, worker_process

include("./taskmaster.jl")


end
