# GasModels.jl 


Forthcoming


## Installation

For the moment, GasModels.jl is not yet registered as a Julia package.  Hence, "clone" should be used instead of "add" for package installation,

`Pkg.clone("git@github.com:lanl-ansi/GasModels.jl.git")`

At least one solver is required for running PowerModels.  Using the open-source solver Ipopt is recommended, as it is extremely fast, and can be used to solve a wide variety of the problems and network formulations provided in PowerModels.  The Ipopt solver is installed via,

`Pkg.add("Ipopt")`


## Basic Usage


Forthcoming



## Acknowledgments

This code has been developed as part of the Advanced Network Science Initiative at Los Alamos National Laboratory.
The primary developer is Russell Bent, with significant contributions from Conrado Borraz-Sanchez, Hassan Hijazi, and Pascal van Hentenryck.

Special thanks to Miles Lubin for his assistance in integrating with Julia/JuMP.


## License

This code is provided under a BSD license as part of the Multi-Infrastructure Control and Optimization Toolkit (MICOT) project, LA-CC-13-108.
