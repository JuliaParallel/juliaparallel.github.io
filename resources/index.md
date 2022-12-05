+++
title = "Resources"
+++

# Resources

All you wanted to know about Julia in High-Performance Computing (HPC): workshops, papers,
and how to get in touch with the community.

## Workshops

Workshops about performance engineering, GPU programming and general use of Julia in HPC:

* [Julia for HPC](https://sc22.supercomputing.org/presentation/?id=bof136&sess=sess309)
  Birds of a Feather session at SuperComputing22 (SC22)
  ([material](https://github.com/JuliaParallel/julia-hpc-bof-sc22)), by William F. Godoy,
  Valentin Churavy, Johannes Blaschke, Mosè Giordano, Pedro Valero-Lara.  November 15th,
  2022.
* [Julia for High-Performance Computing @ HLRS](https://www.hlrs.de/training/2022/julia)
  ([material](https://github.com/carstenbauer/JuliaHLRS22)), by Carsten Bauer, Michael
  Schlottke-Lakemper.  September 20th-23rd, 2022.
* [Julia for High-Performance Computing @ JuliaCon 2022
  ](https://live.juliacon.org/talk/LUWYRJ),
  ([video](https://www.youtube.com/watch?v=fog1x9rs71Q),
  [material](https://github.com/JuliaParallel/juliacon-2022-julia-for-hpc-minisymposium)),
  by William F Godoy, Michael Schlottke-Lakemper, Samuel Omlin, Simon Byrne, Tim Besard,
  Julian Samaroo, Albert Reuther, Johannes Blaschke, Michael Schlottke-Lakemper, Ludovic
  Räss. July 26th, 2022.
* [GPU Programming with Julia @ CSCS/ETH Zurich](https://github.com/omlins/julia-gpu-course)
  ([video recording](https://youtu.be/LmM2QmYw_NM)), by Tim Besard, Samuel Omlin. November
  2nd-5th, 2021.
* [Advanced Workshop on Julia - Cologne 21](https://github.com/carstenbauer/JuliaCologne21),
  by Carsten Bauer. March 15th-17th, 2021.
* [Julia performance
  workshop](https://github.com/vchuravy/julia-performance/tree/a1c77e92033c0ef3f58a360978ac2d3b08745ba8),
  by Valentin Churavy.  November, 2019.
* [Efficient Scientific Computing in Julia — Workshop OIST
  2019](https://github.com/JuliaLabs/Workshop-OIST) (videos: [#1 -
  Introduction](https://www.youtube.com/watch?v=uWlfFn5U0WA), [#2 - Performance
  Engineering](https://www.youtube.com/watch?v=Vm8ZoyM3kqw), [#3 - Open Source and Julia in
  Science](https://www.youtube.com/watch?v=iCeg795IZq0), [#4 - GPU Computing in
  Julia](https://www.youtube.com/watch?v=7Yq1UyncDNc), [#5 - Multithreading in
  Julia](https://www.youtube.com/watch?v=dewQHIaATGE)), by Valentin Churavy. July, 2019.
* [Introduction to Julia @ CSC](https://www.csc.fi/web/training/-/julia_intro_2019)
  ([material](https://github.com/csc-training/julia-introduction/)), by Joonas
  Nättilä. April 17th-19th, 2019.

## Papers

Some of the papers using Julia in HPC, including the JuliaParallel software stack:

* M. Giordano, M. Klöwer and V. Churavy, _[Productivity meets Performance: Julia on
  A64FX](https://ieeexplore.ieee.org/document/9912702)_, 2022 IEEE International Conference
  on Cluster Computing (CLUSTER), 2022, pp. 549-555,
  [doi:10.1109/CLUSTER51413.2022.00072](https://doi.org/10.1109/CLUSTER51413.2022.00072)
  (pre-print: [arXiv:2207.12762](https://arxiv.org/abs/2207.12762)).
* H. Shang et al., (2022). _[Large-Scale Simulation of Quantum Computational Chemistry on a
  New Sunway Supercomputer](https://arxiv.org/abs/2207.03711)_. arXiv:2207.03711.
* W. C. Lin and S. McIntosh-Smith, _[Comparing Julia to Performance Portable Parallel
  Programming Models for HPC](https://ieeexplore.ieee.org/document/9652798)_, 2021
  International Workshop on Performance Modeling, Benchmarking and Simulation of High
  Performance Computer Systems (PMBS), 2021, pp. 94-105,
  [doi:10.1109/PMBS54543.2021.00016](https://doi.org/10.1109/PMBS54543.2021.00016).
* A. Rizvi, K. C. Hale, (2021). _[A Look at Communication-Intensive Performance in
  Julia](https://arxiv.org/abs/2109.14072)_. arXiv:2109.14072.
* S. Byrne, L. C. Wilcox and V. Churavy, (2021). _[MPI.jl: Julia bindings for the Message
  Passing Interface](https://proceedings.juliacon.org/papers/10.21105/jcon.00068)_. JuliaCon
  Proceedings, 1(1), 68, [doi:10.21105/jcon.00068](https://doi.org/10.21105/jcon.00068).
* S. Hunold and S. Steiner, _[Benchmarking Julia’s Communication Performance: Is Julia HPC
  ready or Full HPC?](https://ieeexplore.ieee.org/document/9307882)_, 2020 IEEE/ACM
  Performance Modeling, Benchmarking and Simulation of High Performance Computer Systems
  (PMBS), 2020, pp. 20-25,
  [doi:10.1109/PMBS51919.2020.00008](https://doi.org/10.1109/PMBS51919.2020.00008).
* J. Regier et al., _[Cataloging the visible universe through Bayesian inference in Julia at
  petascale](https://www.sciencedirect.com/science/article/pii/S0743731518304672)_, Journal
  of Parallel and Distributed Computing, Volume 127, 2019, Pages 89-104,
  [doi:10.1016/j.jpdc.2018.12.008](https://doi.org/10.1016/j.jpdc.2018.12.008) (preprint:
  [arXiv:1801.10277](https://arxiv.org/abs/1801.10277)).
  <!-- For some reason Xranklin seems to duplicate the character after the last `)` if it's
	   only one, so we put something else to work around this bug. -->

## Using Julia in HPC facilities

* [Instructions and scripts to run Julia on
  Summit](https://github.com/JuliaLabs/julia-on-summit)
* [Instructions for using Julia on Fugaku](https://github.com/giordano/julia-on-fugaku/)
* [Documentation for using Julia at
  NERSC](https://docs.nersc.gov/development/languages/julia/)

## Community

Get involved with the Julia HPC community:

* JuliaHPC monthly call, typically every fourth Tuesday of the month @ 2pm ET, see events in
  [Julia Community calendar](https://julialang.org/community/#events) for more details.