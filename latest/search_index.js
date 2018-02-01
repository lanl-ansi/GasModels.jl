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
    "text": ""
},

{
    "location": "network-data.html#The-Network-Data-Dictionary-1",
    "page": "Network Data Format",
    "title": "The Network Data Dictionary",
    "category": "section",
    "text": "Internally GasModels utilizes a dictionary to store network data. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The default I/O for GasModels utilizes this serialization direction as a text file.The network data dictionary structure is roughly as follows:{\n\"name\":<string>,        # a name for the model\n\"junction\":{\n    \"1\":{\n      \"qlmax\": <float>,  # the maximum gas demand that can be added to qlfirm\n      \"qgmin\": <float>,  # the minimum gas production that can be added to qgfirm\n      \"qgmax\": <float>,  # the maximum gas production that can be added to qgfirm\n      \"qlmin\": <float>,  # the minimum gas demand that can be added to qlfirm\n      \"qgfirm\": <float>, # constant gas production\n      \"pmax\": <float>,   # maximum pressure\n      \"qlfirm\": <float>, # constant gas demand\n      \"pmin\": <float>,   # minimum pressure\n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"connection\":{\n    \"1\":{\n      \"length\": <float>,       # the length of the connection\n      \"f_junction\": <int>,     # the \"from\" side junction id\n      \"t_junction\": <int>,     # the \"to\" side junction id\n      \"resistance\": <float>,   # the resistance of the connection\n      \"diameter\": <float>,     # the diameter of the connection\n      \"c_ratio_min\": <float>,  # minimum multiplicative pressure change (compression or decompressions)\n      \"c_ratio_max\": <float>,  # maximum multiplicative pressure change (compression or decompressions)      \n      \"type\": <string>,        # the type of the connection. Can be \"pipe\", \"compressor\", \"short_pipe\", \"control_valve\", \"valve\"\n        ...\n    },\n    \"2\":{...},\n    ...\n}\n}All data is assumed to have consistent units (i.e. metric, English, etc.)The following commands can be used to explore the network data dictionary,network_data = GasModels.parse_file(\"gaslib-40.json\")\ndisplay(network_data)"
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
    "text": ""
},

{
    "location": "formulations.html#Type-Hierarchy-1",
    "page": "Network Formulations",
    "title": "Type Hierarchy",
    "category": "section",
    "text": "We begin with the top of the hierarchy, where we can distinguish between gas flow models. Currently, there are two variations of the disjunctive form of the weymouth equations: The full non convex formulation and its conic relaxation.AbstractMINLPForm <: AbstractGasFormulation\nAbstractMISOCPForm <: AbstractGasFormulation"
},

{
    "location": "formulations.html#Gas-Models-1",
    "page": "Network Formulations",
    "title": "Gas Models",
    "category": "section",
    "text": "Each of these forms can be used as the type parameter for a GasModel:MINLPGasModel = GenericGasModel(StandardMINLPForm)\nMISOCPGasModel = GenericGasModel(StandardMISOCPForm)For details on GenericGasModel, see the section on Gas Model."
},

{
    "location": "formulations.html#User-Defined-Abstractions-1",
    "page": "Network Formulations",
    "title": "User-Defined Abstractions",
    "category": "section",
    "text": "The user-defined abstractions begin from a root abstract like the AbstractGasFormulation abstract type, i.e. AbstractMyFooForm <: AbstractGasFormulation\n\nStandardMyFooForm <: AbstractFooForm\nFooGasModel = GenericGasModel{StandardFooForm}"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth-Tuple{GasModels.GenericGasModel{T<:GasModels.AbstractMINLPForm},Int64,Any}",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "Method",
    "text": "Weymouth equation with discrete direction variables \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth_fixed_direction-Tuple{GasModels.GenericGasModel{T<:GasModels.AbstractMINLPForm},Int64,Any}",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_fixed_direction",
    "category": "Method",
    "text": "Weymouth equation with fixed direction variables\n\n\n\n"
},

{
    "location": "formulations.html#MINLP-1",
    "page": "Network Formulations",
    "title": "MINLP",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/minlp.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth-Tuple{GasModels.GenericGasModel{T<:GasModels.AbstractMISOCPForm},Int64,Any}",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "Method",
    "text": "Weymouth equation with discrete direction variables \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth_fixed_direction-Tuple{GasModels.GenericGasModel{T<:GasModels.AbstractMISOCPForm},Int64,Any}",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_fixed_direction",
    "category": "Method",
    "text": "Weymouth equation with fixed direction\n\n\n\n"
},

{
    "location": "formulations.html#GasModels.variable_flux",
    "page": "Network Formulations",
    "title": "GasModels.variable_flux",
    "category": "Function",
    "text": "\n\n"
},

{
    "location": "formulations.html#GasModels.variable_flux_ne",
    "page": "Network Formulations",
    "title": "GasModels.variable_flux_ne",
    "category": "Function",
    "text": "\n\n"
},

{
    "location": "formulations.html#MISOCP-1",
    "page": "Network Formulations",
    "title": "MISOCP",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/misocp.jl\"]\nOrder   = [:function]\nPrivate  = true"
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
    "page": "GasModel",
    "title": "GasModel",
    "category": "page",
    "text": ""
},

{
    "location": "model.html#Gas-Model-1",
    "page": "GasModel",
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
    "location": "objective.html#GasModels.objective_max_load",
    "page": "Objective",
    "title": "GasModels.objective_max_load",
    "category": "Function",
    "text": "function for maximizing load \n\n\n\n"
},

{
    "location": "objective.html#GasModels.objective_min_ne_cost",
    "page": "Objective",
    "title": "GasModels.objective_min_ne_cost",
    "category": "Function",
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
    "location": "variables.html#GasModels.variable_compressor_ne",
    "page": "Variables",
    "title": "GasModels.variable_compressor_ne",
    "category": "Function",
    "text": "variables associated with building compressors \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_connection_direction",
    "page": "Variables",
    "title": "GasModels.variable_connection_direction",
    "category": "Function",
    "text": "variables associated with direction of flow on the connections \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_connection_direction_ne",
    "page": "Variables",
    "title": "GasModels.variable_connection_direction_ne",
    "category": "Function",
    "text": "variables associated with direction of flow on the connections \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_flux",
    "page": "Variables",
    "title": "GasModels.variable_flux",
    "category": "Function",
    "text": "variables associated with flux \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_flux_ne",
    "page": "Variables",
    "title": "GasModels.variable_flux_ne",
    "category": "Function",
    "text": "variables associated with flux in expansion planning \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_load",
    "page": "Variables",
    "title": "GasModels.variable_load",
    "category": "Function",
    "text": "variables associated with demand \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_pipe_ne",
    "page": "Variables",
    "title": "GasModels.variable_pipe_ne",
    "category": "Function",
    "text": "variables associated with building pipes \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_pressure_sqr",
    "page": "Variables",
    "title": "GasModels.variable_pressure_sqr",
    "category": "Function",
    "text": "variables associated with pressure squared \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_production",
    "page": "Variables",
    "title": "GasModels.variable_production",
    "category": "Function",
    "text": "variables associated with production \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_valve_operation",
    "page": "Variables",
    "title": "GasModels.variable_valve_operation",
    "category": "Function",
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
    "location": "constraints.html#GasModels.constraint_conserve_flow-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_conserve_flow",
    "category": "Method",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_conserve_flow_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_conserve_flow_ne",
    "category": "Method",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_flow_direction_choice-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_flow_direction_choice",
    "category": "Method",
    "text": "Constraint that states a flow direction must be chosen \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_flow_direction_choice_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_flow_direction_choice_ne",
    "category": "Method",
    "text": "Constraint that states a flow direction must be chosen for new edges \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance",
    "category": "Method",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance_ls-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance_ls",
    "category": "Method",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance_ne",
    "category": "Method",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance_ne_ls-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance_ne_ls",
    "category": "Method",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_flow_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction",
    "category": "Method",
    "text": "constraints on flow across compressors \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_flow_direction_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_fixed_direction",
    "category": "Method",
    "text": "constraints on flow across compressors when directions are constants \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_flow_direction_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne",
    "category": "Method",
    "text": "constraints on flow across compressors \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_flow_direction_ne_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne_fixed_direction",
    "category": "Method",
    "text": "constraints on flow across compressors when the directions are constants \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_ratios-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_ratios",
    "category": "Method",
    "text": "enforces pressure changes bounds that obey compression ratios \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_ratios_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_ratios_fixed_direction",
    "category": "Method",
    "text": "on/off constraint for compressors when the flow direction is constant \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_ratios_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_ratios_ne",
    "category": "Method",
    "text": "constraints on pressure drop across control valves \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_control_valve_flow_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction",
    "category": "Method",
    "text": "constraints on flow across control valves \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_control_valve_flow_direction_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction_fixed_direction",
    "category": "Method",
    "text": "constraints on flow across control valves when directions are constants \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_control_valve_pressure_drop-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop",
    "category": "Method",
    "text": "constraints on pressure drop across control valves \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_control_valve_pressure_drop_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop_fixed_direction",
    "category": "Method",
    "text": "constraints on pressure drop across control valves when directions are constants \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pipe_flow_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction",
    "category": "Method",
    "text": "constraints on flow across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pipe_flow_direction_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_fixed_direction",
    "category": "Method",
    "text": "constraints on flow across pipes where the directions are fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pipe_flow_direction_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne",
    "category": "Method",
    "text": "constraints on flow across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pipe_flow_direction_ne_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne_fixed_direction",
    "category": "Method",
    "text": "constraints on flow across pipes when directions are fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pressure_drop-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop",
    "category": "Method",
    "text": "constraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pressure_drop_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop_fixed_direction",
    "category": "Method",
    "text": "constraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pressure_drop_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop_ne",
    "category": "Method",
    "text": "constraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pressure_drop_ne_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop_ne_fixed_direction",
    "category": "Method",
    "text": "constraints on pressure drop across pipes when the direction is fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_short_pipe_flow_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction",
    "category": "Method",
    "text": "constraints on flow across short pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_short_pipe_flow_direction_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction_fixed_direction",
    "category": "Method",
    "text": "constraints on flow across short pipes when the directions are constants \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_valve_flow_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_valve_flow_direction",
    "category": "Method",
    "text": "constraints on flow across valves \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_valve_flow_direction_fixed_direction-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_valve_flow_direction_fixed_direction",
    "category": "Method",
    "text": "constraints on flow across valves when directions are constants \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_valve_pressure_drop-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_valve_pressure_drop",
    "category": "Method",
    "text": "constraints on pressure drop across valves \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_parallel_flow-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_parallel_flow",
    "category": "Method",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_parallel_flow_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_parallel_flow_ne",
    "category": "Method",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_short_pipe_pressure_drop-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_short_pipe_pressure_drop",
    "category": "Method",
    "text": "constraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_sink_flow-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_sink_flow",
    "category": "Method",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_sink_flow_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_sink_flow_ne",
    "category": "Method",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_source_flow-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_source_flow",
    "category": "Method",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_source_flow_ne-Tuple{GasModels.GenericGasModel{T},Int64,Any}",
    "page": "Constraints",
    "title": "GasModels.constraint_source_flow_ne",
    "category": "Method",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n"
},

{
    "location": "constraints.html#Constraints-1",
    "page": "Constraints",
    "title": "Constraints",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"core/constraint.jl\"]\nOrder   = [:function]\nPrivate  = true"
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
