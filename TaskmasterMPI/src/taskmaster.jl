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

function current_time()
    return Dates.format(now(), "HH:MM:SS")
end


function get_worker(comm::MPI.Comm)
    status = MPI.Probe(MPI.ANY_SOURCE, MPI.ANY_TAG, comm)
    return status.source
end


function master_process(tasks::Vector{<:Any}, comm::MPI.Comm; verbose::Bool=false)
    size = MPI.Comm_size(comm)

    @assert !any(isnothing, tasks) "`tasks` cannot contain `nothing`."
    @assert size > 1 "MPI size must be ≥ 1."

    tasks = append!(fill(nothing, size - 1), tasks)
    total_tasks = length(tasks) - size + 1

    results = Vector{Vector{Any}}()

    for task in tasks
        worker = get_worker(comm)

        if verbose
            println("$(current_time()): sending $task to worker $worker. Remaining $(total_tasks) tasks.")
        end

        MPI.send(task, worker, worker, comm)

        result_vector = MPI.recv(worker, worker, comm)
        push!(results, result_vector)

        total_tasks -= 1
    end

    return results
end


function worker_process(func::Function, comm::MPI.Comm; verbose::Bool=false)
    rank = MPI.Comm_rank(comm)

    while true
        # Inform master that you are ready for a task
        MPI.send(0, 0, rank, comm)

        # Receive the task from the master
        task, status = MPI.recv(0, rank, comm)

        if isnothing(task)
            if verbose
                println("$(current_time()): closing rank $rank.")
            end
            break
        end

        if verbose
            println("$(current_time()): rank $rank received task $task.")
        end

        result_vector = func(task)

        MPI.send(result_vector, 0, rank, comm)
    end
end


"""
    work_delegation(func::Function, tasks::Vector{<:Any}, comm::MPI.Comm;
                    master_verbose::Bool=true, worker_verbose::Bool=false) -> Vector{Vector{Any}}

Delegate tasks for parallel evaluation using MPI. In the case of multiple processes,
the tasks are split between the master and worker processes. For single processes,
tasks are executed directly and results are returned.

# Arguments
- `func`: A function that takes a single task and produces a vector of results.
- `tasks`: A list of tasks to be processed.
- `comm`: The MPI communicator object, typically `MPI.COMM_WORLD`.

# Keyword Arguments
- `master_verbose=true`: If `true`, master prints out its activity.
- `worker_verbose=false`: If `true`, worker processes print out their activity.

# Returns
- If the process is the master, a list of result vectors corresponding to each task.
  Otherwise, nothing for worker processes.

# Notes
- When you use multiple MPI processes, only the master will return the results.
On single processes, it directly processes and returns the results.
- Make sure MPI is initialized before invoking this function, usually via MPI.Init()
and finalized after, usually via MPI.Finalize().
"""
function work_delegation(func::Function, tasks::Vector{<:Any}, comm::MPI.Comm;
                         master_verbose::Bool=true, worker_verbose::Bool=false)
    if MPI.Comm_size(comm) > 1
        if MPI.Comm_rank(comm) == 0
            results = master_process(tasks, comm, verbose=master_verbose)
            return results
        else
            worker_process(func, comm, verbose=worker_verbose)
            return nothing
        end
    else
        results = Vector{Vector{Any}}()
        for task in tasks
            if master_verbose
                println("$(current_time()): completing task '$task'.")
            end

            result_vector = func(task)
            push!(results, result_vector)
        end

        return results
    end
end
