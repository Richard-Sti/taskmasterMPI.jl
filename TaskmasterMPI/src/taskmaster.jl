"""
    get_worker(comm::MPI.Comm)

Get a free worker from process of rank ≥ 1 as signalled from `worker_process`.
"""
function get_worker(comm::MPI.Comm)
    size = MPI.Comm_size(comm)
    # Go through the workes until signal from at least one that it's free
    for worker in 1:(size - 1)
        flag, __, __ = MPI.irecv(worker, tag(comm, worker), comm)

        if flag
            return worker
        end
    end
    # Otherwise simply return NaN
    return NaN
end


"""
    tag(comm::MPI.Comm, rank::Integer)

Return a tag ID of MPI size + the specified rank.
"""
function tag(comm::MPI.Comm, rank::Integer)
    return rank + MPI.Comm_size(comm)
end


"""
    tag(comm::MPI.Comm)

Return a tag ID of MPI size + the current rank.
"""
function tag(comm::MPI.Comm)
    return MPI.Comm_rank(comm) + MPI.Comm_size(comm)
end


"""
    master_process(tasks::Vector{<:Any}, comm::MPI.Comm, snooze::Real=0.1; verbose::Bool=false)

The master, delegating process. Checks if any rank ≥ 1 processes are available and if they
are assigns them work.
"""
function master_process(tasks::Vector{<:Any}, comm::MPI.Comm, snooze::Real=0.1; verbose::Bool=false)
    # Check there are no nothing as those are the stopping condition.
    size = MPI.Comm_size(comm)
    @assert ~any(isnothing.(tasks)) "`tasks` cannot contain `nothing`."
    @assert size > 1 "MPI size must be ≥ 1."
    # Make a copy of the tasks append at the front terminating conditions
    tasks = append!(fill!(Vector{Any}(undef, size - 1), nothing), deepcopy(tasks))

    while length(tasks) > 0
        worker = get_worker(comm)

        # Send a job to a free worker
        if ~isnan(worker)
            task = pop!(tasks)
            if verbose
                time = Dates.format(now(), "HH:MM")
                println("Sending $task to worker $worker at $time. Remaining $(length(tasks) - size + 1).")
                flush(stdout)
            end
            MPI.send(task, worker, tag(comm, worker), comm)
        end
        # Snooze to avoid refreshing this loop too often
        sleep(snooze)
    end
end


""""
    worker_process(func::Function, comm::MPI.Comm; verbose::Bool=false)

The worker process of rank ≥ 1 that evaluates `func(task)`.
"""
function worker_process(func::Function, comm::MPI.Comm; verbose::Bool=false)
    rank = MPI.Comm_rank(comm)
    while true
        # Send a signal that prepared to work
        MPI.send(0, 0, tag(comm), comm)
        # Receive a new task
        task, __ = MPI.recv(0, tag(comm), comm)
        # Stopping condition        
        if isnothing(task)
            println("Closing rank $rank.")
            break
        end

        if verbose
            println("Rank $rank received task $task.")
            flush(stdout)
        end
        # Evaluate
        func(task)
    end
end
