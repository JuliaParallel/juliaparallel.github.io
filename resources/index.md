+++
title = "Resources"
+++

# Resources

All you wanted to know about Julia in High-Performance Computing (HPC): workshops, papers,
and how to get in touch with the community.
If you find something to be missing, please create a PR to the
[website repo](https://github.com/JuliaParallel/juliaparallel.github.io)
with the relevant information to help ensure that this overview is as
comprehensive as possible.

## Workshops

Workshops about performance engineering, GPU programming and general use of Julia in HPC:

### 2022
* [Julia for HPC](https://sc22.supercomputing.org/presentation/?id=bof136&sess=sess309)
  Birds of a Feather session at SuperComputing22 (SC22)
  ([material](https://github.com/JuliaParallel/julia-hpc-bof-sc22)), by William F. Godoy,
  Valentin Churavy, Johannes Blaschke, Carsten Bauer, Mosè Giordano, Pedro Valero-Lara. November 15th,
  2022.
* [Julia for High-Performance Computing @ HLRS](https://www.hlrs.de/training/2022/julia)
  ([material](https://github.com/carstenbauer/JuliaHLRS22)), by Carsten Bauer, Michael Schlottke-Lakemper. September 20th-23rd, 2022.
* [Julia for High-Performance Computing @ JuliaCon 2022
  ](https://live.juliacon.org/talk/LUWYRJ),
  ([video](https://www.youtube.com/watch?v=fog1x9rs71Q),
  [material](https://github.com/JuliaParallel/juliacon-2022-julia-for-hpc-minisymposium)),
  by William F Godoy, Michael Schlottke-Lakemper, Carsten Bauer, Samuel Omlin, Simon Byrne, Tim Besard,
  Julian Samaroo, Albert Reuther, Johannes Blaschke, Ludovic
  Räss. July 26th, 2022.

### 2021
* [GPU Programming with Julia @ CSCS/ETH Zurich](https://github.com/omlins/julia-gpu-course)
  ([video recording](https://youtu.be/LmM2QmYw_NM)), by Tim Besard, Samuel Omlin. November
  2nd-5th, 2021.
* [Advanced Workshop on Julia @ University of Cologne](https://github.com/carstenbauer/JuliaCologne21),
  by Carsten Bauer. March 15th-17th, 2021.
* [Julia Workshop @ HPC.NRW](https://github.com/carstenbauer/JuliaNRW21),
  by Carsten Bauer. March 2nd-4th, 2021. ([second edition](https://github.com/carstenbauer/JuliaNRWSS21), June 22th-24th)

### 2020 and older
* [Julia Workshop @ University of Oulu](https://github.com/carstenbauer/JuliaOulu20),
  by Carsten Bauer. February 11th-13th, 2020.
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
* [Julia Workshop @ University of Cologne](https://github.com/carstenbauer/JuliaWorkshop19),
  by Carsten Bauer. Fall 2019.
* [Introduction to Julia @ CSC](https://www.csc.fi/web/training/-/julia_intro_2019)
  ([material](https://github.com/csc-training/julia-introduction/)), by Joonas
  Nättilä. April 17th-19th, 2019.

## Papers

Some of the papers using Julia in HPC, including the JuliaParallel software stack:

### 2022
* V. Churavy, W. F Godoy, C. Bauer, H. Ranocha, M. Schlottke-Lakemper, L. Räss, J. Blaschke,
  M. Giordano, E. Schnetter, S. Omlin, J. S. Vetter, and A. Edelman, **Bridging HPC
  Communities through the Julia Programming Language**,
  2022, [arXiv:2211.02740](https://arxiv.org/abs/2211.02740).
* M. Giordano, M. Klöwer and V. Churavy, **Productivity meets Performance: Julia on
  A64FX**, 2022 IEEE International Conference
  on Cluster Computing (CLUSTER), 2022, pp. 549-555,
  [doi:10.1109/CLUSTER51413.2022.00072](https://doi.org/10.1109/CLUSTER51413.2022.00072),
  [arXiv:2207.12762](https://arxiv.org/abs/2207.12762).

### 2021
* H. Shang et al., (2022). **Large-Scale Simulation of Quantum Computational Chemistry on a
  New Sunway Supercomputer**. [arXiv:2207.03711](https://arxiv.org/abs/2207.03711).
* W. C. Lin and S. McIntosh-Smith, **Comparing Julia to Performance Portable Parallel
  Programming Models for HPC**, 2021
  International Workshop on Performance Modeling, Benchmarking and Simulation of High
  Performance Computer Systems (PMBS), 2021, pp. 94-105,
  [doi:10.1109/PMBS54543.2021.00016](https://doi.org/10.1109/PMBS54543.2021.00016).
* A. Rizvi, K. C. Hale, (2021). **A Look at Communication-Intensive Performance in
  Julia**. [arXiv:2109.14072](https://arxiv.org/abs/2109.14072).
* S. Byrne, L. C. Wilcox and V. Churavy, (2021). **MPI.jl: Julia bindings for the Message
  Passing Interface**. JuliaCon Proceedings, 1(1), 68,
  [doi:10.21105/jcon.00068](https://doi.org/10.21105/jcon.00068).

### 2020 and older
* C. Bauer, Y. Schattner, S. Trebst, and E Berg, **Hierarchy of energy scales in an O(3)
  symmetric antiferromagnetic quantum critical metal: a Monte Carlo
  study**, 2020, Phys. Rev. Research 2,
  023008,
  [doi:10.1103/PhysRevResearch.2.023008](https://doi.org/10.1103/PhysRevResearch.2.023008).
* S. Hunold and S. Steiner, **Benchmarking Julia’s Communication Performance: Is Julia HPC
  ready or Full HPC?**, 2020 IEEE/ACM
  Performance Modeling, Benchmarking and Simulation of High Performance Computer Systems
  (PMBS), 2020, pp. 20-25,
  [doi:10.1109/PMBS51919.2020.00008](https://doi.org/10.1109/PMBS51919.2020.00008).
* J. Regier et al., **Cataloging the visible universe through Bayesian inference in Julia at
  petascale**, Journal of Parallel and
  Distributed Computing, Volume 127, 2019, Pages 89-104,
  [doi:10.1016/j.jpdc.2018.12.008](https://doi.org/10.1016/j.jpdc.2018.12.008),
  [arXiv:1801.10277](https://arxiv.org/abs/1801.10277).
  <!-- For some reason Xranklin seems to duplicate the character after the last `)` if it's
	   only one, so we put something else to work around this bug. -->

## Using Julia in HPC facilities

* [Instructions and scripts to run Julia on
  Summit](https://github.com/JuliaLabs/julia-on-summit)
* [Instructions for using Julia on Fugaku](https://github.com/giordano/julia-on-fugaku/)
* [Documentation for using Julia at
  NERSC](https://docs.nersc.gov/development/languages/julia/)
* [Documentation for using Julia at PC2](https://uni-paderborn.atlassian.net/wiki/spaces/PC2DOK/pages/12878307/Julia)

## Community

Get involved with the Julia HPC community:

* JuliaHPC monthly call, typically every fourth Tuesday of the month @ 2pm ET, see events in
  [Julia Community calendar](https://julialang.org/community/#events) for more details.
* [#hpc](https://julialang.slack.com/archives/CBFP2PTTR) on the [Julia Slack](https://julialang.org/slack/)
