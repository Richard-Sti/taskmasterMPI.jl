# taskmasterMPI

A simple Julia taskmaster that delagates the evaluation of a function ``f(x)`` where ``x`` is an element of a vector ``tasks``. A new task is delegated whenever a worker is free. Function ``f(x)`` is not expected to take any arguments, instead it should write its output directly to disk and the user can then read those in.
