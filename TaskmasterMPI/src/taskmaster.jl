"""
    get_free_worker(comm::MPI.Comm)

Get a free worked from process of rank ≥ 1 as signalled from `worker_process`.
"""
function get_free_worker(comm::MPI.Comm)
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
    master_process(tasks::Vector{<:Any}, comm::MPI.Comm, snooze::Real=0.1)

The master, delegating process. Checks if any rank ≥ 1 processes are available and if they
are assigns them work.
"""
function master_process(tasks::Vector{<:Any}, comm::MPI.Comm, snooze::Real=0.1)
    # Check there are no nothing as those are the stopping condition.
    size = MPI.Comm_size(comm)
    @assert ~any(isnothing.(tasks)) "`tasks` cannot contain `nothing`."
    @assert size > 1 "MPI size must be ≥ 1."
    # Make a copy of the tasks append at the front terminating conditions
    tasks = append!(fill!(Vector{Any}(undef, size - 1), nothing), tasks)

    while length(tasks) > 0
        worker = get_free_worker(comm)

        # Send a job to a free worker
        if ~isnan(worker)
            task = pop!(tasks)
            println("Sending $task to worker $worker")
            MPI.send(task, worker, tag(comm, worker), comm)
        end
        # Snooze to avoid refreshing this loop too often
        sleep(snooze)
    end
end


""""
    worker_process(comm::MPI.Comm)

The worker process of rank ≥ 1 that performs the work.
"""
function worker_process(comm::MPI.Comm)
    rank = MPI.Comm_rank(comm)
    while true
        # Send a signal that prepared to work
        MPI.send(0, 0, tag(comm), comm)
        # Receive a new task
        task, __ = MPI.recv(0, tag(comm), comm)
        # Stopping condition        
        if isnothing(task)
            break
        end

        println("Rank $rank received task $task.. Working very hard.")
        sleep(1)
    end
end
