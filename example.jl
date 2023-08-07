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
activate(".")
using TaskmasterMPI

MPI.Init()
comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)

function f(x)
    sleep(1 * rand())
    return [x, x^0.5]
end

# tasks = Vector(3:100)
tasks = Float64.(Vector(3:50))
res = work_delegation(f, tasks, comm; master_verbose=1)

if rank == 0
    df = DataFrame(x = [r[1] for r in res], sqrtx = [r[2] for r in res])

    println("Results converted to a DataFrame:")
    @show df
end

MPI.Finalize()
