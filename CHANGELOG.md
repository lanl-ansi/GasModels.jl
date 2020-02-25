# GasModels.jl Change Log

## Pending

- Add data consistency checks to file parsing
- Refactor to make code style / conventions consistent with Infrastructure Models ecosystem (#136) (breaking)
- Implement constraints on compressor power
- Implement a multi-network test

## Staged

- Introduced matgas format (breaking) (#147)
- Added support for JuMP v0.21 and Infrastructure v0.4
- Removed requirement that all edges must have unique ids (breaking)
- Introduced optimal gas flow formulation (ogf)

## v0.5

- Renamed various function names for consistency (breaking)
- Replaced yn and yp variables with a single variable y
- Broke out resistor constraints from pipe constraints (breaking)
- Added upper bounds on second order code relaxations

## v0.4.2

- Implement nlp version(s) of the problems
- Renamed various function names for consistency (breaking)
- Updated the documentation

## v0.4.1

- Remove bounds on binary variables for increased solver robustness
- Improved support for infeasible status codes
- Fixed AMPLNLWriter name in extra tests

## v0.4.0

- Support for JuMP 0.19 and the MOI interface

## v0.3.5

- move to new Registrator and drop Julia v0.7 and v0.6 support
- fixed bugs in multinetwork build_ref construction
- Redefined the data dictionary to split out connections by type and removed type field (breaking)
- Replaced Logging with Memento
- Removed directionality from being defined in the forms. Instead, it is defined at the problem level (breaking)
- Added utility reference sets to improve computational efficiency of model building
- Refectored qgmin/qgmax/qgfirm and qlmin/qlmax/qlfirm. Now just qgmin/qgmax/qg and ql with a dispatchable flag. The semantics is that a dispatchable consumer or producer should take a value between min and max.  A non dispatchable consumer or producer should use ql and qg respectively (breaking)

## v0.3.4

- fixed bugs in print_summary function
- added tests for summary function to improve coverage

## v0.3.3

- Added support for matlab like data input format parsing
- Added a print_summary function

## v0.3.2

- Add support for Julia v0.7 and v1.0
- Minor documentation updates

## v0.3.1

- Fixed a bug in the resistance calculation (thanks @cvr)
- Added Julia version upper bound

## v0.3.0

- Standardized on SI for real unit inputs (breaking)
- Standardized naming conventions on volumetric flow, mass flow, and mass flux, depending on context (breaking)
- All computations and results are performed in non-dimenionalized units (per unit)
- Update MINLP solvers used in testing

## v0.2.0

- Dropped support for Julia v0.5 (breaking)
- Added support for multiple networks in the JuMP model (breaking)
- Introduced the constraint_template.jl framework for gas constraints
- Created undirected and directed gas formulations (breaking)
- Producers and Consumers defined as separate objects so that multiple can exist at each node (breaking)
- Added compressors and control valves on compress in one direction as defined from f_junction -> t_junction (breaking)
- Added geolocation parameters to junctions
- Added support for a `status` parameter on call components

## v0.1.0

- Initial implementation
