# Copyright (C) 2023 Richard Stiskalek
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
using MPI
using Dates

const STOP = "__STOP__"
ctime() = Dates.format(now(), "HH:MM:SS")


function worker_process(func::Function, comm::MPI.Comm; verbose::Bool=false)
    rank = MPI.Comm_rank(comm)

    while true
        # Receive a task from the master or stop signal.
        task = MPI.recv(comm; source=0, tag=0)

        if task == STOP
            break
        end

        index, task = task

        verbose && println("$(ctime()): rank $rank received task $task.")

        result = func(task)
        MPI.send([index, result], comm; dest=0, tag=1)
    end
end


function master_process(tasks::Vector{<:Real}, comm::MPI.Comm; verbose::Bool=false)
    num_workers = MPI.Comm_size(comm) - 1
    num_tasks = length(tasks)
    completed_tasks = 0
    tasks_sent = 0

    results = Vector{Any}(undef, num_tasks)
    # results = Vector{Any}()

    # Initially distribute tasks to workers
    for worker_rank = 1:min(num_workers, num_tasks)
        task = tasks[worker_rank]
        verbose && println("$(ctime()): sending task $task to worker $worker_rank.")
        MPI.send([worker_rank, task], comm; dest=worker_rank, tag=0)
        tasks_sent += 1
    end

    while completed_tasks < num_tasks
        # Block until there is a worker sending back results.
        status = MPI.Probe(MPI.ANY_SOURCE, 1, comm)
        worker_rank = status.source

        verbose && println("$(ctime()): receiving from worker $worker_rank.")

        result = MPI.recv(comm; source=worker_rank, tag=1)
        index, result = result

        # Check that the index is valid. If its e.g. 2.0 convert to Int
        msg = "Received an invalid index `$index` from worker `$worker_rank`."
        isa(index, Real) || error(msg)
        isinteger(index) ? (index = Int64(index)) : error(msg)

        results[index] = result

        completed_tasks += 1
        # Send a new task to the worker that just finished.
        if tasks_sent < num_tasks
            task = tasks[tasks_sent + 1]
            verbose && println("$(ctime()): sending task $task to worker $worker_rank.")
            MPI.send([tasks_sent + 1, task], comm; dest=worker_rank, tag=0)
            tasks_sent += 1
        end
    end

    # All tasks have been completed, send a stop signal.
    for i in 1:num_workers
        MPI.send(STOP, comm; dest=i, tag=0)
    end

    return results
end


"""
    work_delegation(func::Function, tasks::Vector{<:Real}, comm::MPI.Comm;
                    master_verbose::Bool=true, worker_verbose::Bool=false)

Distributes tasks among the available MPI processes. If there's only one process, it will
execute all tasks.

# Arguments
- `func`: The function to be applied to each task. This function should take a single argument,
    which is a task from the `tasks` vector. The function should return a result that can be
    collected by the master process.
- `tasks`: A vector of tasks to be distributed among the MPI processes. Each task will be
    passed as an argument to `func`.
- `comm`: The MPI communicator that handles the processes.

# Keyword Arguments
- `master_verbose`: If true, the master process will print a message each time it completes
    a task. Default is true.
- `worker_verbose`: If true, the worker processes will print a message each time they complete
    a task. Default is false.

# Returns
- For the master process (rank 0), it returns the results of the tasks it has processed.
- For worker processes (rank > 0), it doesn't return anything as the results are communicated
    through MPI.
- If there's only one process, it returns a vector with the results of all tasks.
"""
function work_delegation(func::Function, tasks::Vector{<:Real}, comm::MPI.Comm;
                         master_verbose::Bool=true, worker_verbose::Bool=false)
    if MPI.Comm_size(comm) > 1
        if MPI.Comm_rank(comm) == 0
            return master_process(tasks, comm; verbose=master_verbose)
        else
            worker_process(func, comm; verbose=worker_verbose)
        end
    else
        results = Vector{Any}()
        for task in tasks
            master_verbose && println("$(ctime()): completing task $task.")

            result_vector = func(task)
            push!(results, result_vector)
        end

        return results
    end
end
