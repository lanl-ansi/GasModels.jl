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
    "text": "The run commands in GasModels return detailed results data in the form of a dictionary. This dictionary can be saved for further processing as follows,run_soc_gf(\"../test/data/gaslib-40.json\", PajaritoSolver())For example, the algorithm\'s runtime and final objective value can be accessed with,result[\"solve_time\"]\nresult[\"objective\"]The \"solution\" field contains detailed information about the solution produced by the run method. For example, the following dictionary comprehension can be used to inspect the junction pressures in the solution,Dict(name => data[\"p\"] for (name, data) in result[\"solution\"][\"junction\"])For more information about GasModels result data see the GasModels Result Data Format section."
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
    "text": "Internally GasModels utilizes a dictionary to store network data. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The default I/O for GasModels utilizes this serialization direction as a text file.The network data dictionary structure is roughly as follows:{\n\"name\":<string>,        # a name for the model\n\"junction\":{\n    \"1\":{\n      \"pmax\": <float>,   # maximum pressure\n      \"pmin\": <float>,   # minimum pressure\n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"consumer\":{\n    \"1\":{\n      \"ql_junc\": <float>,  # junction id\n      \"qlmax\": <float>,  # the maximum gas demand that can be added to qlfirm\n      \"qlmin\": <float>,  # the minimum gas demand that can be added to qlfirm\n      \"qlfirm\": <float>, # constant gas demand\n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"producer\":{\n    \"1\":{\n      \"qg_junc\": <float>,  # junction id\n      \"qgmin\": <float>,  # the minimum gas production that can be added to qgfirm\n      \"qgmax\": <float>,  # the maximum gas production that can be added to qgfirm\n      \"qgfirm\": <float>, # constant gas production\n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"connection\":{\n    \"1\":{\n      \"length\": <float>,       # the length of the connection\n      \"f_junction\": <int>,     # the \"from\" side junction id\n      \"t_junction\": <int>,     # the \"to\" side junction id\n      \"resistance\": <float>,   # the resistance of the connection\n      \"diameter\": <float>,     # the diameter of the connection\n      \"c_ratio_min\": <float>,  # minimum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 is flow reverses).\n      \"c_ratio_max\": <float>,  # maximum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 is flow reverses).      \n      \"type\": <string>,        # the type of the connection. Can be \"pipe\", \"compressor\", \"short_pipe\", \"control_valve\", \"valve\"\n        ...\n    },\n    \"2\":{...},\n    ...\n}\n}All data is assumed to have consistent units (i.e. metric, English, etc.)The following commands can be used to explore the network data dictionary,network_data = GasModels.parse_file(\"gaslib-40.json\")\ndisplay(network_data)"
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
    "text": ""
},

{
    "location": "result-data.html#The-Result-Data-Dictionary-1",
    "page": "Result Data Format",
    "title": "The Result Data Dictionary",
    "category": "section",
    "text": "GasModels utilizes a dictionary to organize the results of a run command. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The data dictionary organization is designed to be consistent with the GasModels The Network Data Dictionary.At the top level the results data dictionary is structured as follows:{\n\"solver\":<string>,       # name of the Julia class used to solve the model\n\"status\":<julia symbol>, # solver status at termination\n\"solve_time\":<float>,    # reported solve time (seconds)\n\"objective\":<float>,     # the final evaluation of the objective function\n\"objective_lb\":<float>,  # the final lower bound of the objective function (if available)\n\"machine\":{...},         # computer hardware information (details below)\n\"data\":{...},            # test case information (details below)\n\"solution\":{...}         # complete solution information (details below)\n}"
},

{
    "location": "result-data.html#Machine-Data-1",
    "page": "Result Data Format",
    "title": "Machine Data",
    "category": "section",
    "text": "This object provides basic information about the hardware that was  used when the run command was called.{\n\"cpu\":<string>,    # CPU product name\n\"memory\":<string>  # the amount of system memory (units given)\n}"
},

{
    "location": "result-data.html#Case-Data-1",
    "page": "Result Data Format",
    "title": "Case Data",
    "category": "section",
    "text": "This object provides basic information about the network cases that was  used when the run command was called.{\n\"name\":<string>,      # the name from the network data structure\n\"junction_count\":<int>,    # the number of nodes in the network data structure\n\"connection_count\":<int>  # the number of edges in the network data structure\n}"
},

{
    "location": "result-data.html#Solution-Data-1",
    "page": "Result Data Format",
    "title": "Solution Data",
    "category": "section",
    "text": "The solution object provides detailed information about the solution  produced by the run command.  The solution is organized similarly to  The Network Data Dictionary with the same nested structure and  parameter names, when available.  A network solution most often only includes a small subset of the data included in the network data.For example the data for a junction, data[\"junction\"][\"1\"] is structured as follows,{\n\"pmin\": 14.0,\n\"pmax\": 80.0,\n...\n}A solution specifying a pressure for the same case, i.e. result[\"solution\"][\"junction\"][\"1\"], would result in,{\n\"p\":50.5,\n}Because the data dictionary and the solution dictionary have the same structure  GasModels provides an update_data helper function which can be used to  update a data diction with the values from a solution as follows,GasModels.update_data(data, result[\"solution\"])"
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
    "text": "We begin with the top of the hierarchy, where we can distinguish between gas flow models. Currently, there are two variations of the weymouth equations, one where the directions of flux are known and one where they are unknown.AbstractDirectedGasFormulation <: AbstractGasFormulation\nAbstractUndirectedGasFormulation <: AbstractGasFormulationEach of these have a disjunctive form of the weymouth equations: The full non convex formulation and its conic relaxation.AbstractMINLPForm <: AbstractUndirectedGasFormulation\nAbstractMISOCPForm <: AbstractUndirectedGasFormulation\nAbstractMINLPDirectedForm <: AbstractDirectedGasFormulation\nAbstractMISOCPDirectedForm <: AbstractDirectedGasFormulation"
},

{
    "location": "formulations.html#Gas-Models-1",
    "page": "Network Formulations",
    "title": "Gas Models",
    "category": "section",
    "text": "Each of these forms can be used as the type parameter for a GasModel, i.e.:MINLPGasModel = GenericGasModel(StandardMINLPForm)\nMISOCPGasModel = GenericGasModel(StandardMISOCPForm)For details on GenericGasModel, see the section on Gas Model."
},

{
    "location": "formulations.html#User-Defined-Abstractions-1",
    "page": "Network Formulations",
    "title": "User-Defined Abstractions",
    "category": "section",
    "text": "The user-defined abstractions begin from a root abstract like the AbstractGasFormulation abstract type, i.e. AbstractMyFooForm <: AbstractGasFormulation\n\nStandardMyFooForm <: AbstractFooForm\nFooGasModel = GenericGasModel{StandardFooForm}"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_compressor_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction",
    "category": "method",
    "text": "constraints on flow across compressors when directions are constants \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_compressor_flow_direction_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across compressors when the directions are constants \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_compressor_ratios-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_ratios",
    "category": "method",
    "text": "on/off constraint for compressors when the flow direction is constant \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_control_valve_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across control valves when directions are constants \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_control_valve_pressure_drop-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across control valves when directions are constants \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pipe_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across pipes where the directions are fixed \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pipe_flow_direction_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across pipes when directions are fixed \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pressure_drop-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pressure_drop_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop_ne",
    "category": "method",
    "text": "constraints on pressure drop across pipes when the direction is fixed \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_short_pipe_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across short pipes when the directions are constants \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_valve_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across valves when directions are constants \n\n\n\n"
},

{
    "location": "formulations.html#Directed-Models-1",
    "page": "Network Formulations",
    "title": "Directed Models",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/directed.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "formulations.html#GasModels.constraint_conserve_flow-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_conserve_flow",
    "category": "method",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_conserve_flow_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_conserve_flow_ne",
    "category": "method",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_compressor_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction",
    "category": "method",
    "text": "constraints on flow across compressors \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_compressor_flow_direction_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across compressors \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_compressor_ratios-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_ratios",
    "category": "method",
    "text": "enforces pressure changes bounds that obey compression ratios \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_control_valve_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across control valves \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_control_valve_pressure_drop-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across control valves \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pipe_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across pipes \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pipe_flow_direction_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across pipes \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pressure_drop-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_pressure_drop_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop_ne",
    "category": "method",
    "text": "constraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_short_pipe_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across short pipes \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_on_off_valve_flow_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across valves \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_parallel_flow-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_parallel_flow",
    "category": "method",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_parallel_flow_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_parallel_flow_ne",
    "category": "method",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_sink_flow-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_sink_flow",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_sink_flow_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_sink_flow_ne",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_source_flow-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_source_flow",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_source_flow_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_source_flow_ne",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.variable_connection_direction-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.variable_connection_direction",
    "category": "method",
    "text": "variables associated with direction of flow on the connections. yp = 1 imples flow goes from f_junction to t_junction. yn = 1 imples flow goes from t_junction to f_junction \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.variable_connection_direction_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.variable_connection_direction_ne",
    "category": "method",
    "text": "variables associated with direction of flow on the connections \n\n\n\n"
},

{
    "location": "formulations.html#Undirected-Models-1",
    "page": "Network Formulations",
    "title": "Undirected Models",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/undirected.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMINLPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with fixed direction variables\n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMINLPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMINLPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with fixed directions for MINLP\n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMINLPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables for MINLP \n\n\n\n"
},

{
    "location": "formulations.html#MINLP-1",
    "page": "Network Formulations",
    "title": "MINLP",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/minlp.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMISOCPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with directed flow\n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMISOCPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables \n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMISOCPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with fixed direction\n\n\n\n"
},

{
    "location": "formulations.html#GasModels.constraint_weymouth_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}, Tuple{T}} where T<:GasModels.AbstractMISOCPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables for MINLP\n\n\n\n"
},

{
    "location": "formulations.html#GasModels.variable_flow-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T<:GasModels.AbstractMISOCPForm",
    "page": "Network Formulations",
    "title": "GasModels.variable_flow",
    "category": "method",
    "text": "\n\n"
},

{
    "location": "formulations.html#GasModels.variable_flux-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T<:Union{GasModels.AbstractMISOCPDirectedForm, GasModels.AbstractMISOCPForm}",
    "page": "Network Formulations",
    "title": "GasModels.variable_flux",
    "category": "method",
    "text": "\n\n"
},

{
    "location": "formulations.html#GasModels.variable_flux_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T<:Union{GasModels.AbstractMISOCPDirectedForm, GasModels.AbstractMISOCPForm}",
    "page": "Network Formulations",
    "title": "GasModels.variable_flux_ne",
    "category": "method",
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
    "text": ""
},

{
    "location": "specifications.html#Gas-Flow-(GF)-1",
    "page": "Problem Specifications",
    "title": "Gas Flow (GF)",
    "category": "section",
    "text": ""
},

{
    "location": "specifications.html#Variables-1",
    "page": "Problem Specifications",
    "title": "Variables",
    "category": "section",
    "text": "variable_pressure_sqr(gm)\nvariable_flow(gm)\nvariable_valve_operation(gm)"
},

{
    "location": "specifications.html#Constraints-1",
    "page": "Problem Specifications",
    "title": "Constraints",
    "category": "section",
    "text": "for i in ids(gm, :junction)\n    constraint_junction_flow(gm, i)\nend\n    \nfor i in [collect(ids(gm, :pipe)); collect(ids(gm, :resistor))] \n    constraint_pipe_flow(gm, i) \nend\n\nfor i in ids(gm, :short_pipe)\n    constraint_short_pipe_flow(gm, i) \nend\n        \nfor i in ids(gm, :compressor)\n    constraint_compressor_flow(gm, i) \nend\n    \nfor i in ids(gm, :valve)\n    constraint_valve_flow(gm, i) \nend\n    \nfor i in ids(gm, :control_valve)     \n    constraint_control_valve_flow(gm, i) \nend"
},

{
    "location": "specifications.html#Maximum-Load-(LS)-1",
    "page": "Problem Specifications",
    "title": "Maximum Load (LS)",
    "category": "section",
    "text": ""
},

{
    "location": "specifications.html#Variables-2",
    "page": "Problem Specifications",
    "title": "Variables",
    "category": "section",
    "text": "variable_flow(gm)  \nvariable_pressure_sqr(gm)\nvariable_valve_operation(gm)\nvariable_load(gm)\nvariable_production(gm)"
},

{
    "location": "specifications.html#Objective-1",
    "page": "Problem Specifications",
    "title": "Objective",
    "category": "section",
    "text": "objective_max_load(gm)"
},

{
    "location": "specifications.html#Constraints-2",
    "page": "Problem Specifications",
    "title": "Constraints",
    "category": "section",
    "text": "for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] \n    constraint_pipe_flow(gm, i) \nend\n    \nfor i in ids(gm, :junction)\n    constraint_junction_flow_ls(gm, i)      \nend\n    \nfor i in ids(gm, :short_pipe)\n    constraint_short_pipe_flow(gm, i) \nend\n        \nfor i in ids(gm, :compressor) \n    constraint_compressor_flow(gm, i) \nend\n    \nfor i in ids(gm, :valve)     \n    constraint_valve_flow(gm, i) \nend\n    \nfor i in ids(gm, :control_valve) \n    constraint_control_valve_flow(gm, i) \nend"
},

{
    "location": "specifications.html#Expansion-Planning-(NE)-1",
    "page": "Problem Specifications",
    "title": "Expansion Planning (NE)",
    "category": "section",
    "text": ""
},

{
    "location": "specifications.html#Objective-2",
    "page": "Problem Specifications",
    "title": "Objective",
    "category": "section",
    "text": "objective_min_ne_cost(gm)"
},

{
    "location": "specifications.html#Variables-3",
    "page": "Problem Specifications",
    "title": "Variables",
    "category": "section",
    "text": "variable_pressure_sqr(gm)\nvariable_flow(gm)\nvariable_flow_ne(gm)    \nvariable_valve_operation(gm)\nvariable_pipe_ne(gm)\nvariable_compressor_ne(gm)"
},

{
    "location": "specifications.html#Constraints-3",
    "page": "Problem Specifications",
    "title": "Constraints",
    "category": "section",
    "text": "for i in ids(gm, :junction)\n    constraint_junction_flow_ne(gm, i) \nend\n\nfor i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] \n    constraint_pipe_flow_ne(gm, i)\nend\n\nfor i in ids(gm,:ne_pipe) \n    constraint_new_pipe_flow_ne(gm, i)\nend\n    \nfor i in ids(gm, :short_pipe) \n    constraint_short_pipe_flow_ne(gm, i)\nend\n    \nfor i in ids(gm, :compressor)\n    constraint_compressor_flow_ne(gm, i)\nend\n    \nfor i in ids(gm, :ne_compressor) \n    constraint_new_compressor_flow_ne(gm, i)\nend  \n         \nfor i in ids(gm, :valve)  \n    constraint_valve_flow(gm, i)       \nend\n    \nfor i in ids(gm, :control_valve)\n    constraint_control_valve_flow(gm, i)       \nend\n    \nexclusive = Dict()\nfor (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]\n    i = min(pipe[\"f_junction\"],pipe[\"t_junction\"])\n    j = max(pipe[\"f_junction\"],pipe[\"t_junction\"])\n   \n    if haskey(exclusive, i) == false  \n        exclusive[i] = Dict()\n    end  \n           \n    if haskey(exclusive[i], j) == false \n        constraint_exclusive_new_pipes(gm, i, j)         \n        exclusive[i][j] = true\n    end             \nend"
},

{
    "location": "model.html#",
    "page": "GasModel",
    "title": "GasModel",
    "category": "page",
    "text": ""
},

{
    "location": "model.html#GasModels.GenericGasModel",
    "page": "GasModel",
    "title": "GasModels.GenericGasModel",
    "category": "type",
    "text": "type GenericGasModel{T<:AbstractGasFormulation}\n    model::JuMP.Model\n    data::Dict{String,Any}\n    setting::Dict{String,Any}\n    solution::Dict{String,Any}\n    var::Dict{Symbol,Any} # model variable lookup\n    constraint::Dict{Symbol, Dict{Any, ConstraintRef}} # model constraint lookup\n    ref::Dict{Symbol,Any} # reference data\n    ext::Dict{Symbol,Any} # user extensions\nend\n\nwhere\n\ndata is the original data, usually from reading in a .json file,\nsetting usually looks something like Dict(\"output\" => Dict(\"flows\" => true)), and\nref is a place to store commonly used pre-computed data from of the data dictionary,   primarily for converting data-types, filtering out deactivated components, and storing   system-wide values that need to be computed globally. See build_ref(data) for further details.\n\nMethods on GenericGasModel for defining variables and adding constraints should\n\nwork with the ref dict, rather than the original data dict,\nadd them to model::JuMP.Model, and\nfollow the conventions for variable and constraint names.\n\n\n\n"
},

{
    "location": "model.html#GasModels.build_ref",
    "page": "GasModel",
    "title": "GasModels.build_ref",
    "category": "function",
    "text": "Returns a dict that stores commonly used pre-computed data from of the data dictionary, primarily for converting data-types, filtering out deactivated components, and storing system-wide values that need to be computed globally.\n\nSome of the common keys include:\n\n:max_flow (see max_flow(data)),\n:connection – the set of connections that are active in the network (based on the component status values),\n:pipe – the set of connections that are pipes (based on the component type values),\n:short_pipe – the set of connections that are short pipes (based on the component type values),\n:compressor – the set of connections that are compressors (based on the component type values),\n:valve – the set of connections that are valves (based on the component type values),\n:control_valve – the set of connections that are control valves (based on the component type values),\n:resistor – the set of connections that are resistors (based on the component type values),\n:parallel_connections – the set of all existing connections between junction pairs (i,j),\n:all_parallel_connections – the set of all existing and new connections between junction pairs (i,j),\n:junction_connections – the set of all existing connections of junction i,\n:junction_ne_connections – the set of all new connections of junction i,\n:junction_consumers – the mapping Dict(i => [consumer[\"ql_junc\"] for (i,consumer) in ref[:consumer]]).\n:junction_producers – the mapping Dict(i => [producer[\"qg_junc\"] for (i,producer) in ref[:producer]]).\njunction[degree] – the degree of junction i using existing connections (see add_degree)),\njunction[all_degree] – the degree of junction i using existing and new connections (see add_degree)),\nconnection[pd_min,pd_max] – the max and min square pressure difference (see add_pd_bounds_swr)),\n\nIf :ne_connection does not exist, then an empty reference is added If status does not exist in the data, then 1 is added If construction cost does not exist in the :ne_connection, then 0 is added\n\n\n\n"
},

{
    "location": "model.html#Gas-Model-1",
    "page": "GasModel",
    "title": "Gas Model",
    "category": "section",
    "text": "CurrentModule = GasModelsAll methods for constructing gasmodels should be defined on the following type:GenericGasModelwhich utilizes the following (internal) functions:build_ref"
},

{
    "location": "objective.html#",
    "page": "Objective",
    "title": "Objective",
    "category": "page",
    "text": ""
},

{
    "location": "objective.html#GasModels.objective_max_load-Union{Tuple{GasModels.GenericGasModel{T},Any}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Objective",
    "title": "GasModels.objective_max_load",
    "category": "method",
    "text": "function for maximizing load \n\n\n\n"
},

{
    "location": "objective.html#GasModels.objective_min_ne_cost-Union{Tuple{GasModels.GenericGasModel{T},Any}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Objective",
    "title": "GasModels.objective_min_ne_cost",
    "category": "method",
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
    "category": "function",
    "text": "extracts the start value\n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_compressor_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_compressor_ne",
    "category": "method",
    "text": "variables associated with building compressors \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_flux-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_flux",
    "category": "method",
    "text": "variables associated with flux \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_flux_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_flux_ne",
    "category": "method",
    "text": "variables associated with flux in expansion planning \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_load-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_load",
    "category": "method",
    "text": "variables associated with demand \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_pipe_ne-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_pipe_ne",
    "category": "method",
    "text": "variables associated with building pipes \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_pressure_sqr-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_pressure_sqr",
    "category": "method",
    "text": "variables associated with pressure squared \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_production-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_production",
    "category": "method",
    "text": "variables associated with production \n\n\n\n"
},

{
    "location": "variables.html#GasModels.variable_valve_operation-Union{Tuple{GasModels.GenericGasModel{T},Int64}, Tuple{GasModels.GenericGasModel{T}}, Tuple{T}} where T",
    "page": "Variables",
    "title": "GasModels.variable_valve_operation",
    "category": "method",
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
    "text": "CurrentModule = GasModels"
},

{
    "location": "constraints.html#Constraint-Templates-1",
    "page": "Constraints",
    "title": "Constraint Templates",
    "category": "section",
    "text": "Constraint templates help simplify data wrangling across multiple Gas Flow formulations by providing an abstraction layer between the network data and network constraint definitions. The constraint template\'s job is to extract the required parameters from a given network data structure and pass the data as named arguments to the Gas Flow formulations.These templates should be defined over GenericGasModel and should not refer to model variables. For more details, see the files: core/constraint_template.jl and core/constraint.jl."
},

{
    "location": "constraints.html#Junction-Constraints-1",
    "page": "Constraints",
    "title": "Junction Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance",
    "category": "function",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\nstandard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#Flow-Balance-Constraints-1",
    "page": "Constraints",
    "title": "Flow Balance Constraints",
    "category": "section",
    "text": "constraint_junction_flow_balance"
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance_ls",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance_ls",
    "category": "function",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\nstandard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#Load-Shedding-Constraints-1",
    "page": "Constraints",
    "title": "Load Shedding Constraints",
    "category": "section",
    "text": "constraint_junction_flow_balance_ls"
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance_ne",
    "category": "function",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\nstandard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_junction_flow_balance_ne_ls",
    "page": "Constraints",
    "title": "GasModels.constraint_junction_flow_balance_ne_ls",
    "category": "function",
    "text": "standard flow balance equation where demand and production is fixed \n\n\n\nstandard flow balance equation where demand and production is fixed \n\n\n\n"
},

{
    "location": "constraints.html#Network-Expansion-Constraints-1",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_junction_flow_balance_ne\nconstraint_junction_flow_balance_ne_ls"
},

{
    "location": "constraints.html#Pipe-Constraints-1",
    "page": "Constraints",
    "title": "Pipe Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#GasModels.constraint_weymouth",
    "page": "Constraints",
    "title": "GasModels.constraint_weymouth",
    "category": "function",
    "text": "Weymouth equation with discrete direction variables \n\n\n\nWeymouth equation with discrete direction variables \n\n\n\nWeymouth equation with fixed direction variables\n\n\n\nWeymouth equation with discrete direction variables \n\n\n\nWeymouth equation with directed flow\n\n\n\n"
},

{
    "location": "constraints.html#Weymouth\'s-Law-Constraints-1",
    "page": "Constraints",
    "title": "Weymouth\'s Law Constraints",
    "category": "section",
    "text": "constraint_weymouth"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across pipes \n\n\n\nconstraints on pressure drop across pipes \n\n\n\nconstraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pipe_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction",
    "category": "function",
    "text": "constraints on flow across pipes \n\n\n\nconstraints on flow across pipes where the directions are fixed \n\n\n\nconstraints on flow across pipes \n\n\n\n"
},

{
    "location": "constraints.html#Direction-On/off-Constraints-1",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_pressure_drop\nconstraint_on_off_pipe_flow_direction"
},

{
    "location": "constraints.html#GasModels.constraint_weymouth_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "function",
    "text": "Weymouth equation with discrete direction variables for MINLP \n\n\n\nWeymouth equation with discrete direction variables for MINLP \n\n\n\nWeymouth equation with fixed directions for MINLP\n\n\n\nWeymouth equation with discrete direction variables for MINLP\n\n\n\nWeymouth equation with fixed direction\n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pressure_drop_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop_ne",
    "category": "function",
    "text": "constraints on pressure drop across pipes \n\n\n\nconstraints on pressure drop across pipes when the direction is fixed \n\n\n\nconstraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_pipe_flow_direction_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne",
    "category": "function",
    "text": "constraints on flow across pipes \n\n\n\nconstraints on flow across pipes when directions are fixed \n\n\n\nconstraints on flow across pipes \n\n\n\n"
},

{
    "location": "constraints.html#Network-Expansion-Constraints-2",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_weymouth_ne\nconstraint_on_off_pressure_drop_ne\nconstraint_on_off_pipe_flow_direction_ne"
},

{
    "location": "constraints.html#Compressor-Constraints-1",
    "page": "Constraints",
    "title": "Compressor Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction",
    "category": "function",
    "text": "constraints on flow across compressors \n\n\n\nconstraints on flow across compressors when directions are constants \n\n\n\nconstraints on flow across compressors \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_ratios",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_ratios",
    "category": "function",
    "text": "enforces pressure changes bounds that obey compression ratios \n\n\n\non/off constraint for compressors when the flow direction is constant \n\n\n\nenforces pressure changes bounds that obey compression ratios \n\n\n\n"
},

{
    "location": "constraints.html#Direction-On/off-Constraints-2",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_compressor_flow_direction\nconstraint_on_off_compressor_ratios"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_flow_direction_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne",
    "category": "function",
    "text": "constraints on flow across compressors \n\n\n\nconstraints on flow across compressors when the directions are constants \n\n\n\nconstraints on flow across compressors \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_compressor_ratios_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_ratios_ne",
    "category": "function",
    "text": "constraints on pressure drop across control valves \n\n\n\nconstraints on pressure drop across control valves \n\n\n\n"
},

{
    "location": "constraints.html#Network-Expansion-Constraints-3",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_on_off_compressor_flow_direction_ne\nconstraint_on_off_compressor_ratios_ne"
},

{
    "location": "constraints.html#Control-Valve-Constraints-1",
    "page": "Constraints",
    "title": "Control Valve Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#GasModels.constraint_on_off_control_valve_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction",
    "category": "function",
    "text": "constraints on flow across control valves \n\n\n\nconstraints on flow across control valves when directions are constants \n\n\n\nconstraints on flow across control valves \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_control_valve_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across control valves \n\n\n\nconstraints on pressure drop across control valves when directions are constants \n\n\n\nconstraints on pressure drop across control valves \n\n\n\n"
},

{
    "location": "constraints.html#Direction-On/off-Constraints-3",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_control_valve_flow_direction\nconstraint_on_off_control_valve_pressure_drop"
},

{
    "location": "constraints.html#Valve-Constraints-1",
    "page": "Constraints",
    "title": "Valve Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#GasModels.constraint_on_off_valve_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_valve_flow_direction",
    "category": "function",
    "text": "constraints on flow across valves \n\n\n\nconstraints on flow across valves when directions are constants \n\n\n\nconstraints on flow across valves \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_on_off_valve_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_valve_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across valves \n\n\n\nconstraints on pressure drop across valves \n\n\n\n"
},

{
    "location": "constraints.html#Direction-On/off-Constraints-4",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_valve_flow_direction\nconstraint_on_off_valve_pressure_drop"
},

{
    "location": "constraints.html#Short-Pipes-1",
    "page": "Constraints",
    "title": "Short Pipes",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#GasModels.constraint_on_off_short_pipe_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction",
    "category": "function",
    "text": "constraints on flow across short pipes \n\n\n\nconstraints on flow across short pipes when the directions are constants \n\n\n\nconstraints on flow across short pipes \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_short_pipe_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_short_pipe_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across pipes \n\n\n\nconstraints on pressure drop across pipes \n\n\n\n"
},

{
    "location": "constraints.html#Direction-On/off-Constraints-5",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_short_pipe_flow_direction\nconstraint_short_pipe_pressure_drop"
},

{
    "location": "constraints.html#GasModels.constraint_source_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_source_flow",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\nMake sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_sink_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_sink_flow",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\nMake sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_conserve_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_conserve_flow",
    "category": "function",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\nThis constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_parallel_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_parallel_flow",
    "category": "function",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\nensures that parallel lines have flow in the same direction \n\n\n\n"
},

{
    "location": "constraints.html#Direction-Cutting-Constraints-1",
    "page": "Constraints",
    "title": "Direction Cutting Constraints",
    "category": "section",
    "text": "constraint_source_flow\nconstraint_sink_flow\nconstraint_conserve_flow\nconstraint_parallel_flow"
},

{
    "location": "constraints.html#GasModels.constraint_source_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_source_flow_ne",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\nMake sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_sink_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_sink_flow_ne",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\nMake sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_conserve_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_conserve_flow_ne",
    "category": "function",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\nThis constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n"
},

{
    "location": "constraints.html#GasModels.constraint_parallel_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_parallel_flow_ne",
    "category": "function",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\nensures that parallel lines have flow in the same direction \n\n\n\n"
},

{
    "location": "constraints.html#Network-Expansion-Constraints-4",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_source_flow_ne\nconstraint_sink_flow_ne\nconstraint_conserve_flow_ne\nconstraint_parallel_flow_ne"
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
