GasModels.jl Change Log
=================

### Pending

- Modify the compressor and control valve data model so that bi-directional regulation objects require two objects in the data (breaking)
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
- Producers and Consumers defined as seperate objects so that multiple can exist at each node (breaking)

### v0.1.0
- Initial implementation
