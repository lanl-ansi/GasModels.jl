GasModels.jl Change Log
=================

### Pending

- Introduce the constraint_template.jl framework for gas constraints
- Modify the fixed direction "problem" to become a model (breaking)
- Modify the compressor and control valve data model so that bi-directional regulation objects require two objects in the data (breaking)
- Implement non-binary variable model of compressors and control valves  
- Implement nlp version(s) of the problems (abs, x - x^2 = 0, compressor directionalty)
- Implement a "make_per_unit" function to normalize all units
- Allow multiple loads/producers per node (breaking)
- Implement Constraints on compressor power 

### Staged

- Added support for multiple networks in the JuMP model (breaking)

### v0.1.0
- Initial implementation
