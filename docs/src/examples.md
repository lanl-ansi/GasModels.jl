# Examples Documentation

The examples folder contains a library gas network instances which have been developed in the literature.

Many of the examples can be run using the `run_examples.jl` script which executes various problems and formulations on the library of instances and verifies that `GasModels returns solutions which were reported in the literature.

Long term, the plan is to move the examples out of the `GasModels` repository and maintain a special `GasModelsLib` repository specifically for warehousing models developed in the literature.

| Problems          | Source               |
| ----------------- | -------------------- |
| 24-pipe-benchmark | [1]                  |
| A3                | [2]                  |
| case-30           | [1]                  |
| gaslib-40-*       | [2]                  |
| gaslib-135-*      | [2]                  |
| gaslib-582-*      | [2]                  |

## Sources

[1] Unknown

[2] Conrado Borraz-Sanchez, Russell Bent, Scott Backhaus, Hassan Hijazi and Pascal Van Hentenryck. "Convex Relaxations for Gas Expansion Planning". *INFORMS Journal on Computing*, 28 (4): 645-656, 2016.
