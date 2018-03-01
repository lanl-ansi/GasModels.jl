GasModels.jl Change Log
=================

### Pending

- Implement non-binary variable model of compressors and control valves  
- Implement nlp version(s) of the problems (abs, x - x^2 = 0, compressor directionalty)
- Implement a "make_per_unit" function to normalize all units
- Implement Constraints on compressor power 
- Implement a multi-network test
- Implement an update_data function patterned after PowerModels.jl
- Implement a matlab like data input format

### Staged

- Added support for multiple networks in the JuMP model (breaking)
- Introduced the constraint_template.jl framework for gas constraints
- Created undirected and directed gas formulations (breaking)
- Producers and Consumers defined as separate objects so that multiple can exist at each node (breaking)
- Compressors and control valves on compress in one direction as defined from f_junction -> t_junction (breaking)


### v0.1.0
- Initial implementation
