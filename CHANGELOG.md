# GasModels.jl Change Log

## Staged


## v0.9.2 
- Move Cbc to HiGHS
- update JuMP version 
- simplified storage model

## v0.9.1

- fixes bug for data with no receipts 
- non-dimensionalization of compressor power objective
- bug fix in `parse_files` where `prep_transient_data!` was called twice, overwriting `"original_pipe"` and `"original_junction"`
- bug fix in GasLib component index assignment
- updates for new multi-infrastructure conventions
- add mgc.sources to the matgas format to keep track of data source metadata
- Added storage to steady-state model

## v0.8.2

- changed default interpolation to linear
- bug fix in reservoir constraints

## v0.8.1

- bug fix in interpolation

## v0.8

- strengthen variable bounds for resistors and loss resistors
- compressors are made optional components
- fixed bug in `calc_connected_components`
- corrected models of resistor physics
- added support storage model for transient_ogf added
- transient_ogf constraints and variables changed for improved computation times
- renamed variable_valve_operation to be variable_on_off_operation to reflect the name change from control_valve to regulator (breaking)
- removed explicit direction function calls. These are now handled automatically based on data
- renamed pd_min, pd_max to be pd_sqr_min and pd_sqr_max (breaking)
- added support for loss resistors, which model constant pressure loss
- added support for native GasLib parsing functionality
- added pressure slack node constraints to base formulations
- added compressor energy constraints to base formulations
- renamed formulations: NLP -> WP (Weymouth Physics), MINLP -> DWP (Disjunctive Weymouth Physics), MISOCP -> CRDWP (Convex relaxation of the disjunctive weymouth physics), MIP -> LRDWP (Linear relaxation of disjunctive weymouth physics), LP -> LRWP (Linear relaxation of the weymouth physics) (breaking)

## v0.7

- Update to InfrastructureModels solution building (breaking)
- Add support for Memento v0.13, v1.0
- Introduce transient optimal gas flow formulation (transient_ogf)
- Support for transient optimization problem restricted to component types: junction, pipe, compressor, receipt, delivery, and transfers; objective support: load shed, compressor power, and linear combination of both.
- Add multi-network and transient_ogf unit tests
- Fixed bug in area computation .
- Fixed bug in sound speed computation and other parameters
- Fixed bugs in matgas parser by merging parses-fixes branch by @pseudocubic
- Implemented constraints on compressor power
- Implemented a multi-network test

## v0.6

- Introduced matgas format (breaking) (#147)
- Add data consistency checks to file parsing
- Added support for JuMP v0.21 and Infrastructure v0.4
- Removed requirement that all edges must have unique ids (breaking)
- Refactor to make code style / conventions consistent with Infrastructure Models ecosystem (#136) (breaking)
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
