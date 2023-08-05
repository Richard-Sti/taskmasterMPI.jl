# TaskmasterMPI.jl

`TaskmasterMPI.jl` is a Julia package designed to efficiently delegate tasks for parallel evaluation using the Message Passing Interface (MPI).

## Features
- **MPI Integration**: Seamless communication between master and worker processes using the MPI.
- **Verbose Mode**: Monitoring task delegation, reception, and completion with optional verbose output.
- **Flexible Task Execution**: Delegation of tasks for both single and multiple MPI processes.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Installation

Follow the steps below to manually download and install the `TaskmasterMPI` package:

1. **Clone the Repository**: First, you'll need to clone the `TaskmasterMPI` repository from GitHub. Navigate to the directory where you want to install the package and run:
    ```bash
    git clone git@github.com:Richard-Sti/taskmasterMPI.jl.git
    ```

2. **Activate the Environment**: Navigate to the directory of the cloned repository and activate the Julia environment:
    ```julia
    cd TaskmasterMPI
    using Pkg
    Pkg.activate(".")
    ```

3. **Install Dependencies**: Still within Julia, ensure you install any necessary dependencies for the package:
    ```julia
    Pkg.instantiate()
    ```

4. **Using the Package**: After you've successfully activated and instantiated the package's environment, you can start using it in your Julia scripts or REPL:
    ```julia
    using TaskmasterMPI
    ```

## Dependencies

The `TaskmasterMPI` package requires the following dependencies:

- **MPI.jl**

## Usage

The primary function in `TaskmasterMPI.jl` is `work_delegation()`. This function delegates tasks for parallel evaluation using MPI.

```julia
using MPI
using TaskmasterMPI

MPI.Init()

# Define a function to be run on each task
function f(x)
    sleep(0.5 * rand())
    return [x, x^0.5]
end

# List of tasks
tasks = Vector(1:10)

# Delegate tasks using work_delegation
res = work_delegation(f, tasks, MPI.COMM_WORLD)

if MPI.Comm_rank(MPI.COMM_WORLD) == 0
    println("Results:")
    @show res
end

MPI.Finalize()
```

Please refer to inline documentation for detailed function parameters and usage. Similar example is included in the script `example.jl`.

## Authors

- **Richard Stiskalek** ([richard.stiskalek@protonmail.com](mailto:richard.stiskalek@protonmail.com))

