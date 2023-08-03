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
using MPI, DataFrames

import Pkg: activate
activate("./TaskmasterMPI/.")
using TaskmasterMPI

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)

function f(x)
    sleep(0.5 * rand())
    return [x, x^0.5]
end

tasks = Vector(1:10)
res = work_delegation(f, tasks, comm)

if rank == 0
    println("The results are a vector of vectors:")
    @show res

    df = DataFrame(x = [r[1] for r in res], sqrtx = [r[2] for r in res])

    println("Results converted to a DataFrame:")
    @show df

    println("We're all done!")
end

MPI.Finalize()
