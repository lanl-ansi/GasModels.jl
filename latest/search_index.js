var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#GasModels.jl-Documentation-1",
    "page": "Home",
    "title": "GasModels.jl Documentation",
    "category": "section",
    "text": "CurrentModule = GasModels"
},

{
    "location": "index.html#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "GasModels.jl is a Julia/JuMP package for Steady-State Gas Network Optimization. It provides utilities for parsing and modifying network data (see GasModels Network Data Format for details), and is designed to enable computational evaluation of emerging gas network formulations and algorithms in a common platform.The code is engineered to decouple Problem Specifications (e.g. Gas Flow, Expansion Planning, ...) from Network Formulations (e.g. MINLP, MISOC-relaxation, ...). This enables the definition of a wide variety of gas network formulations and their comparison on common problem specifications."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "The latest stable release of GasModels will be installed using the Julia package manager withPkg.add(\"GasModels\")For the current development version, \"checkout\" this package withPkg.checkout(\"GasModels\")At least one solver is required for running GasModels.  The open-source solver Pajarito is recommended and can be used to solve a wide variety of the problems and network formulations provided in GasModels.  The Pajarito solver can be installed via the package manager withPkg.add(\"Pajarito\")Test that the package works by runningPkg.test(\"GasModels\")"
},

{
    "location": "quickguide.html#",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "page",
    "text": ""
},

{
    "location": "quickguide.html#Quick-Start-Guide-1",
    "page": "Getting Started",
    "title": "Quick Start Guide",
    "category": "section",
    "text": "Once Gas Models is installed, Pajarito is installed, and a network data file (e.g. \"test/data/gaslib-40.json\") has been acquired, a Gas Flow with SOC relaxation can be executed with,using GasModels\nusing Pajarito\n\nrun_soc_gf(\"../test/data/gaslib-40.json\", PajaritoSolver())Similarly, a full non-convex Gas Flow can be executed with a MINLP solver likerun_nl_gf(\"../test/data/gaslib-40.json\", CouenneNLSolver())"
},

{
    "location": "quickguide.html#Getting-Results-1",
    "page": "Getting Started",
    "title": "Getting Results",
    "category": "section",
    "text": "The run commands in GasModels return detailed results data in the form of a dictionary. This dictionary can be saved for further processing as follows,run_soc_gf(\"../test/data/gaslib-40.json\", PajaritoSolver())For example, the algorithm's runtime and final objective value can be accessed with,result[\"solve_time\"]\nresult[\"objective\"]The \"solution\" field contains detailed information about the solution produced by the run method. For example, the following dictionary comprehension can be used to inspect the junction pressures in the solution,Dict(name => data[\"p\"] for (name, data) in result[\"solution\"][\"junction\"])For more information about GasModels result data see the GasModels Result Data Format section."
},

{
    "location": "quickguide.html#Accessing-Different-Formulations-1",
    "page": "Getting Started",
    "title": "Accessing Different Formulations",
    "category": "section",
    "text": "The function \"run_soc_gf\" and \"run_nl_gf\" are shorthands for a more general formulation-independent gas flow execution, \"run_gf\". For example, run_soc_gf is equivalent to,run_gf(\"test/data/gaslib-40.json\", MISOCPGasModel, PajaritoSolver())where \"MISOCPGasModel\" indicates an SOC formulation of the gas flow equations.  This more generic run_gf() allows one to solve a gas flow feasability problem with any gas network formulation implemented in GasModels.  For example, the full non convex Gas Flow can be run with,run_gf(\"test/data/gaslib-40.json\", MINLPGasModel, CouenneNLSolver())"
},

{
    "location": "quickguide.html#Modifying-Network-Data-1",
    "page": "Getting Started",
    "title": "Modifying Network Data",
    "category": "section",
    "text": "The following example demonstrates one way to perform multiple GasModels solves while modify the network data in Julia,network_data = GasModels.parse_file(\"test/data/gaslib-40.json\")\n\nrun_gf(network_data, MISOCPGasModel, PajaritoSolver())\n\nnetwork_data[\"junction\"][\"24\"][\"pmin\"] = 30.0\n\nrun_gf(network_data, MISOCPGasModel, PajaritoSolver())For additional details about the network data, see the GasModels Network Data Format section."
},

{
    "location": "quickguide.html#Inspecting-the-Formulation-1",
    "page": "Getting Started",
    "title": "Inspecting the Formulation",
    "category": "section",
    "text": "The following example demonstrates how to break a run_gf call into separate model building and solving steps.  This allows inspection of the JuMP model created by GasModels for the gas flow problem,gm = build_generic_model(\"test/data/gaslib-40.json\", MISOCPGasModel, GasModels.post_gf)\n\nprint(gm.model)\n\nsolve_generic_model(gm, PajaritoSolver())"
},

{
    "location": "network-data.html#",
    "page": "Network Data Format",
    "title": "Network Data Format",
    "category": "page",
    "text": ""
},

{
    "location": "network-data.html#GasModels-Network-Data-Format-1",
    "page": "Network Data Format",
    "title": "GasModels Network Data Format",
    "category": "section",
    "text": "Todo"
},

{
    "location": "result-data.html#",
    "page": "Result Data Format",
    "title": "Result Data Format",
    "category": "page",
    "text": ""
},

{
    "location": "result-data.html#GasModels-Result-Data-Format-1",
    "page": "Result Data Format",
    "title": "GasModels Result Data Format",
    "category": "section",
    "text": "Todo"
},

{
    "location": "formulations.html#",
    "page": "Network Formulations",
    "title": "Network Formulations",
    "category": "page",
    "text": ""
},

{
    "location": "formulations.html#Network-Formulations-1",
    "page": "Network Formulations",
    "title": "Network Formulations",
    "category": "section",
    "text": "Todo"
},

{
    "location": "specifications.html#",
    "page": "Problem Specifications",
    "title": "Problem Specifications",
    "category": "page",
    "text": ""
},

{
    "location": "specifications.html#Problem-Specifications-1",
    "page": "Problem Specifications",
    "title": "Problem Specifications",
    "category": "section",
    "text": "Todo"
},

{
    "location": "model.html#",
    "page": "PowerModel",
    "title": "PowerModel",
    "category": "page",
    "text": ""
},

{
    "location": "model.html#Gas-Model-1",
    "page": "PowerModel",
    "title": "Gas Model",
    "category": "section",
    "text": "Todo"
},

{
    "location": "objective.html#",
    "page": "Objective",
    "title": "Objective",
    "category": "page",
    "text": ""
},

{
    "location": "objective.html#GasModels.objective_max_load-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Objective",
    "title": "GasModels.objective_max_load",
    "category": "Method",
    "text": "function for maximizing load \n\n\n\n"
},

{
    "location": "objective.html#GasModels.objective_min_ne_cost-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Objective",
    "title": "GasModels.objective_min_ne_cost",
    "category": "Method",
    "text": "function for costing expansion of pipes and compressors \n\n\n\n"
},

{
    "location": "objective.html#Objective-1",
    "page": "Objective",
    "title": "Objective",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"core/objective.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "variables.html#",
    "page": "Variables",
    "title": "Variables",
    "category": "page",
    "text": ""
},

{
    "location": "variables.html#GasModels.getstart",
    "page": "Variables",
    "title": "GasModels.getstart",
    "category": "Function",
    "text": "extracts the start value\n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_compressor_ne-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_compressor_ne",
    "category": "Method",
    "text": "variables associated with building compressors \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_connection_direction-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_connection_direction",
    "category": "Method",
    "text": "variables associated with direction of flow on the connections \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_connection_direction_ne-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_connection_direction_ne",
    "category": "Method",
    "text": "variables associated with direction of flow on the connections \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_flux-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_flux",
    "category": "Method",
    "text": "variables associated with flux \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_flux_ne-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_flux_ne",
    "category": "Method",
    "text": "variables associated with flux in expansion planning \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_load-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_load",
    "category": "Method",
    "text": "variables associated with demand \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_pipe_ne-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_pipe_ne",
    "category": "Method",
    "text": "variables associated with building pipes \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_pressure_sqr-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_pressure_sqr",
    "category": "Method",
    "text": "variables associated with pressure squared \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_production-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_production",
    "category": "Method",
    "text": "variables associated with production \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_valve_operation-Tuple{GasModels.GenericGasModel{T}}",
    "page": "Variables",
    "title": "GasModels.variable_valve_operation",
    "category": "Method",
    "text": "0-1 variables associated with operating valves \n\n\n\n"
},

{
    "location": "variables.html#Variables-1",
    "page": "Variables",
    "title": "Variables",
    "category": "section",
    "text": "We provide the following methods to provide a compositional approach for defining common variables used in gas flow models. These methods should always be defined over \"GenericGasModel\".Modules = [GasModels]\nPages   = [\"core/variable.jl\"]\nOrder   = [:type, :function]\nPrivate  = true"
},

{
    "location": "constraints.html#",
    "page": "Constraints",
    "title": "Constraints",
    "category": "page",
    "text": ""
},

{
    "location": "constraints.html#Constraints-1",
    "page": "Constraints",
    "title": "Constraints",
    "category": "section",
    "text": "Todo"
},

{
    "location": "parser.html#",
    "page": "File IO",
    "title": "File IO",
    "category": "page",
    "text": ""
},

{
    "location": "parser.html#File-IO-1",
    "page": "File IO",
    "title": "File IO",
    "category": "section",
    "text": "TODO"
},

{
    "location": "developer.html#",
    "page": "Developer",
    "title": "Developer",
    "category": "page",
    "text": ""
},

{
    "location": "developer.html#Developer-Documentation-1",
    "page": "Developer",
    "title": "Developer Documentation",
    "category": "section",
    "text": "Nothing yet."
},

]}
