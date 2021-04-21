# GasModels Unit and Regression Tests

This folder contains the GasModels scripts for performing unit tests and regression tests. From within the Julia environment, these tests are executed by running the command

```julia
test GasModels
```

Each file in this directory is designed to test different features of the GasModels code and are outlined in this table


| Filename                | Description    |
| :-------------          | :------------- |
| data.jl                 | Contains unit tests for parsing input files and GasModels data structures                                          |
| debug.jl                | Contains unit tests for specific structures in GasModels formulations                                              |
| direction_compressor.jl | Contains regression tests on different combinations of direction logic for compressors as outlined in direction.md |
| direction_pipe.jl       | Contains regression tests on different combinations of direction logic for pipes as outlined in direction.md       |
| direction_regulator.jl  | Contains regression tests on different combinations of direction logic for regulators as outlined in direction.md  |
| direction_resistor.jl   | Contains regression tests on different combinations of direction logic for resistors as outlined in direction.md   |
| direction_short_pipe.jl | Contains regression tests on different combinations of direction logic for short pipes as outlined in direction.md |
| direction_valve.jl      | Contains regression tests on different combinations of direction logic for valves as outlined in direction.md      |
| gf.jl                   | Contains regression and verification tests on the steady-state gas flow formulation                                |
| ls.jl                   | Contains regression and verification tests on the steady-state load shedding formulation                           |
| ne.jl                   | Contains regression and verification tests on the steady-state network expansion formulation                       |
| nels.jl                 | Contains regression and verification tests on the steady-state network expansion + load shedding formulation       |
| ogf.jl                  | Contains regression and verification tests on the steady-state optimal gas flow formulation                        |
| transient.jl            | Contains regression and verification tests on the transient gas flow formulation                                   |
