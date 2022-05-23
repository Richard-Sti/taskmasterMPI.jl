module TaskmasterMPI

import MPI
import Dates: now


export get_free_worker, tag, master_process, worker_process

include("./taskmaster.jl")


end
