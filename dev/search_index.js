var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#GasModels.jl-Documentation-1",
    "page": "Home",
    "title": "GasModels.jl Documentation",
    "category": "section",
    "text": "CurrentModule = GasModels"
},

{
    "location": "#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "GasModels.jl is a Julia/JuMP package for Steady-State Gas Network Optimization. It provides utilities for parsing and modifying network data (see GasModels Network Data Format for details), and is designed to enable computational evaluation of emerging gas network formulations and algorithms in a common platform.The code is engineered to decouple Problem Specifications (e.g. Gas Flow, Expansion Planning, ...) from Network Formulations (e.g. MINLP, MISOC-relaxation, ...). This enables the definition of a wide variety of gas network formulations and their comparison on common problem specifications."
},

{
    "location": "#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "The latest stable release of GasModels will be installed using the Julia package manager withPkg.add(\"GasModels\")For the current development version, \"checkout\" this package withPkg.checkout(\"GasModels\")At least one solver is required for running GasModels.  The open-source solver Pajarito is recommended and can be used to solve a wide variety of the problems and network formulations provided in GasModels.  The Pajarito solver can be installed via the package manager withPkg.add(\"Pajarito\")Test that the package works by runningPkg.test(\"GasModels\")"
},

{
    "location": "quickguide/#",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "page",
    "text": ""
},

{
    "location": "quickguide/#Quick-Start-Guide-1",
    "page": "Getting Started",
    "title": "Quick Start Guide",
    "category": "section",
    "text": "Once Gas Models is installed, Pajarito is installed, and a network data file (e.g. \"test/data/gaslib-40.json\") has been acquired, a Gas Flow with SOC relaxation can be executed with,using GasModels\nusing Pajarito\n\nrun_soc_gf(\"../test/data/gaslib-40.json\", PajaritoSolver())Similarly, a full non-convex Gas Flow can be executed with a MINLP solver likerun_nl_gf(\"../test/data/gaslib-40.json\", CouenneNLSolver())"
},

{
    "location": "quickguide/#Getting-Results-1",
    "page": "Getting Started",
    "title": "Getting Results",
    "category": "section",
    "text": "The run commands in GasModels return detailed results data in the form of a dictionary. This dictionary can be saved for further processing as follows,run_soc_gf(\"../test/data/gaslib-40.json\", PajaritoSolver())For example, the algorithm\'s runtime and final objective value can be accessed with,result[\"solve_time\"]\nresult[\"objective\"]The \"solution\" field contains detailed information about the solution produced by the run method. For example, the following dictionary comprehension can be used to inspect the junction pressures in the solution,Dict(name => data[\"p\"] for (name, data) in result[\"solution\"][\"junction\"])For more information about GasModels result data see the GasModels Result Data Format section."
},

{
    "location": "quickguide/#Accessing-Different-Formulations-1",
    "page": "Getting Started",
    "title": "Accessing Different Formulations",
    "category": "section",
    "text": "The function \"runsocgf\" and \"runnlgf\" are shorthands for a more general formulation-independent gas flow execution, \"rungf\". For example, `runsoc_gf` is equivalent to,run_gf(\"test/data/gaslib-40.json\", MISOCPGasModel, PajaritoSolver())where \"MISOCPGasModel\" indicates an SOC formulation of the gas flow equations.  This more generic run_gf() allows one to solve a gas flow feasability problem with any gas network formulation implemented in GasModels.  For example, the full non convex Gas Flow can be run with,run_gf(\"test/data/gaslib-40.json\", MINLPGasModel, CouenneNLSolver())"
},

{
    "location": "quickguide/#Modifying-Network-Data-1",
    "page": "Getting Started",
    "title": "Modifying Network Data",
    "category": "section",
    "text": "The following example demonstrates one way to perform multiple GasModels solves while modify the network data in Julia,network_data = GasModels.parse_file(\"test/data/gaslib-40.json\")\n\nrun_gf(network_data, MISOCPGasModel, PajaritoSolver())\n\nnetwork_data[\"junction\"][\"24\"][\"pmin\"] = 30.0\n\nrun_gf(network_data, MISOCPGasModel, PajaritoSolver())For additional details about the network data, see the GasModels Network Data Format section."
},

{
    "location": "quickguide/#Inspecting-the-Formulation-1",
    "page": "Getting Started",
    "title": "Inspecting the Formulation",
    "category": "section",
    "text": "The following example demonstrates how to break a run_gf call into separate model building and solving steps.  This allows inspection of the JuMP model created by GasModels for the gas flow problem,gm = build_generic_model(\"test/data/gaslib-40.json\", MISOCPGasModel, GasModels.post_gf)\n\nprint(gm.model)\n\nsolve_generic_model(gm, PajaritoSolver())"
},

{
    "location": "network-data/#",
    "page": "Network Data Format",
    "title": "Network Data Format",
    "category": "page",
    "text": ""
},

{
    "location": "network-data/#GasModels-Network-Data-Format-1",
    "page": "Network Data Format",
    "title": "GasModels Network Data Format",
    "category": "section",
    "text": ""
},

{
    "location": "network-data/#The-Network-Data-Dictionary-1",
    "page": "Network Data Format",
    "title": "The Network Data Dictionary",
    "category": "section",
    "text": "Internally GasModels utilizes a dictionary to store network data. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The default I/O for GasModels utilizes this serialization as a text file. When used as serialization, the data is assumed to be in per_unit (non dimenisionalized) or SI units.The network data dictionary structure is roughly as follows:{\n\"name\":<string>,                   # a name for the model\n\"temperature\":<float>,             # gas temperature. SI units are kelvin\n\"multinetwork\":<boolean>,          # flag for whether or not this is multiple networks\n\"gas_molar_mass\":<float>,          # molecular mass of the gas. SI units are kg/mol\n\"standard_density\":<float>,        # Standard (nominal) density of the gas. SI units are kg/m^3\n\"per_unit\":<boolean>,              # Whether or not the file is in per unit (non dimensional units) or SI units.  Note that the only quantities that are non-dimensionalized are pressure and flux.  \n\"compressibility_factor\":<float>,  # Gas compressability. Non-dimensional.\n\"baseQ\":<float>,                   # Base for non-dimensionalizing volumetric flow at standard density. SI units are m^3/s\n\"baseP\":<float>,                   # Base for non-dimensionalizing pressure. SI units are pascal.\n\"junction\":{\n    \"1\":{\n      \"pmax\": <float>,   # maximum pressure. SI units are pascals\n      \"pmin\": <float>,   # minimum pressure. SI units are pascals\n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"consumer\":{\n    \"1\":{\n      \"ql_junc\": <float>,  # junction id\n      \"qlmax\": <float>,  # the maximum volumetric gas demand at standard density that can be added to qlfirm. SI units are m^3/s.\n      \"qlmin\": <float>,  # the minimum volumetric gas demand gas demand at standard density that can be added to qlfirm. SI units are m^3/s.\n      \"qlfirm\": <float>, # constant volumetric gas demand gas demand at standard density. SI units are m^3/s.\n      \"priority\": <float>, # priority for serving the variable load. High numbers reflect a higher desired to serve this load.\n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"producer\":{\n    \"1\":{\n      \"qg_junc\": <float>,  # junction id\n      \"qgmin\": <float>,  # the minimum volumetric gas production at standard density that can be added to qgfirm. SI units are m^3/s.\n      \"qgmax\": <float>,  # the maximum volumetric gas production at standard density that can be added to qgfirm. SI units are m^3/s.\n      \"qgfirm\": <float>, # constant volumetric gas production at standard density. SI units are m^3/s.\n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"connection\":{\n    \"1\":{\n      \"length\": <float>,            # the length of the connection. SI units are m.\n      \"f_junction\": <int>,          # the \"from\" side junction id\n      \"t_junction\": <int>,          # the \"to\" side junction id\n      \"drag\": <float>,              # the drag factor of resistors. Non dimensional.\n      \"friction_factor\": <float>,   # the friction component of the resistance term of the pipe. Non dimensional.\n      \"diameter\": <float>,          # the diameter of the connection. SI units are m.\n      \"c_ratio_min\": <float>,       # minimum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).\n      \"c_ratio_max\": <float>,       # maximum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).      \n      \"type\": <string>,             # the type of the connection. Can be \"pipe\", \"compressor\", \"short_pipe\", \"control_valve\", \"valve\"\n        ...\n    },\n    \"2\":{...},\n    ...\n}\n}All data is assumed to have consistent units (i.e. metric, English, etc.)The following commands can be used to explore the network data dictionary,network_data = GasModels.parse_file(\"gaslib-40.json\")\ndisplay(network_data)"
},

{
    "location": "result-data/#",
    "page": "Result Data Format",
    "title": "Result Data Format",
    "category": "page",
    "text": ""
},

{
    "location": "result-data/#GasModels-Result-Data-Format-1",
    "page": "Result Data Format",
    "title": "GasModels Result Data Format",
    "category": "section",
    "text": ""
},

{
    "location": "result-data/#The-Result-Data-Dictionary-1",
    "page": "Result Data Format",
    "title": "The Result Data Dictionary",
    "category": "section",
    "text": "GasModels utilizes a dictionary to organize the results of a run command. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The data dictionary organization is designed to be consistent with the GasModels The Network Data Dictionary.At the top level the results data dictionary is structured as follows:{\n\"solver\":<string>,       # name of the Julia class used to solve the model\n\"status\":<julia symbol>, # solver status at termination\n\"solve_time\":<float>,    # reported solve time (seconds)\n\"objective\":<float>,     # the final evaluation of the objective function\n\"objective_lb\":<float>,  # the final lower bound of the objective function (if available)\n\"machine\":{...},         # computer hardware information (details below)\n\"data\":{...},            # test case information (details below)\n\"solution\":{...}         # complete solution information (details below)\n}"
},

{
    "location": "result-data/#Machine-Data-1",
    "page": "Result Data Format",
    "title": "Machine Data",
    "category": "section",
    "text": "This object provides basic information about the hardware that was  used when the run command was called.{\n\"cpu\":<string>,    # CPU product name\n\"memory\":<string>  # the amount of system memory (units given)\n}"
},

{
    "location": "result-data/#Case-Data-1",
    "page": "Result Data Format",
    "title": "Case Data",
    "category": "section",
    "text": "This object provides basic information about the network cases that was  used when the run command was called.{\n\"name\":<string>,      # the name from the network data structure\n\"junction_count\":<int>,    # the number of nodes in the network data structure\n\"connection_count\":<int>  # the number of edges in the network data structure\n}"
},

{
    "location": "result-data/#Solution-Data-1",
    "page": "Result Data Format",
    "title": "Solution Data",
    "category": "section",
    "text": "The solution object provides detailed information about the solution  produced by the run command.  The solution is organized similarly to  The Network Data Dictionary with the same nested structure and  parameter names, when available.  A network solution most often only includes a small subset of the data included in the network data.For example the data for a junction, data[\"junction\"][\"1\"] is structured as follows,{\n\"pmin\": 14000.0,\n\"pmax\": 80000.0,\n...\n}A solution specifying a pressure for the same case, i.e. result[\"solution\"][\"junction\"][\"1\"], would result in,{\n\"p\":50.5,\n}Because the data dictionary and the solution dictionary have the same structure  InfrastructureModels update_data! helper function can be used to  update a data dictionary with the values from a solution as follows,InfrastructureModels.update_data!(data, result[\"solution\"])By default, all results are reported in per-unit (non-dimenionalized). Below are common outputs of implemented optimization models{\n\"junction\":{\n    \"1\":{\n      \"p\": <float>,      # pressure. Non-dimensional quantity. Multiply by baseP to get pascals\n      \"psqr\": <float>,   # pressure squared. Non-dimensional quantity. Multiply by baseP^2 to get pascals^2      \n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"consumer\":{\n    \"1\":{\n      \"fl\": <float>,  # variable mass flow consumed. Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. \n      \"ql\": <float>,  # the varible volumetric gas demand at standard density. Non-dimensional quantity. Multiply by baseQ to get m^3/s. \n       ...\n    },\n    \"2\":{...},\n    ...\n},\n\"producer\":{\n    \"1\":{\n      \"fg\": <float>,  # variable mass flow produced. Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. \n      \"qg\": <float>,  # the varible volumetric gas produced at standard density. Non-dimensional quantity. Multiply by baseQ to get m^3/s.        ...\n    },\n    \"2\":{...},\n    ...\n},\n\"connection\":{\n    \"1\":{\n      \"f\": <float>,                 # mass flow through the pipe.  Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. Mass flux is obtained through division of the cross-sectional area (A) of the pipe. A= (pi*diameter^2)/4\n      \"yp\": <int>,                  # 1 if flux flows from f_junction. 0 otherwise\n      \"yn\": <int>,                  # 1 if flux flows from t_junction. 0 otherwise\n      \"v\": <int>,                   # 1 if valve is open. 0 otherwise      \n      \"ratio\": <float>,             # multiplicative (de)compression ratio\n        ...\n    },\n    \"2\":{...},\n    ...\n},\n\"ne_connection\":{\n    \"1\":{\n      \"f\": <float>,                 # mass flow through the pipe.  Non-dimensional quantity. Multiply by baseQ/standard_density to get kg/s. Mass flux is obtained through division of the cross-sectional area (A) of the pipe. A= (pi*diameter^2)/4\n      \"yp\": <int>,                  # 1 if flux flows from f_junction. 0 otherwise\n      \"yn\": <int>,                  # 1 if flux flows from t_junction. 0 otherwise\n      \"v\": <int>,                   # 1 if valve is open. 0 otherwise      \n      \"ratio\": <float>,             # multiplicative (de)compression ratio\n      \"built_zp\": <float>,          # 1 if the pipe was built. 0 otherwise.\n      \"built_zc\": <float>,          # 1 if compressor was built. 0 otherwise.      \n        ...\n    },\n    \"2\":{...},\n    ...\n}\n}"
},

{
    "location": "math-model/#",
    "page": "Mathematical Model",
    "title": "Mathematical Model",
    "category": "page",
    "text": ""
},

{
    "location": "math-model/#The-GasModels-Mathematical-Model-1",
    "page": "Mathematical Model",
    "title": "The GasModels Mathematical Model",
    "category": "section",
    "text": "As GasModels implements a variety of gas network optimization problems, the implementation is the best reference for precise mathematical formulations.  This section provides a mathematical specification for a prototypical Gas Flow problem, to provide an overview of the typical mathematical models in GasModels."
},

{
    "location": "math-model/#Gas-Flow-1",
    "page": "Mathematical Model",
    "title": "Gas Flow",
    "category": "section",
    "text": "GasModels implements a steady-state model of gas flow based on the Weymouth formulation that uses the 1-D hydrodynamic equations for natural gas flow in a pipe. In the following paragraphs, a derivation of the steady state equations used in GasModels is shown. To that end, we first assume that the flow is steady. Given this assumption, the conservation of momentum equation for the flow of gas in a pipe is given by p fracpartial ppartial x = -fraclambda a^2 phi phi2 Dwhere p is pressure, lambda is a non dimensional friction factor, phi is mass flux, and D is the diameter of the pipe. Here, a^2=fracZRTm where Z is the gas compressibility factor, R is the universal gas constant, m is the molar mass of the gas, and T is the gas temperature. Again, for steady flow, the mass conservation reduces to:    fracpartial phipartial x=0 where we have assumed the pipe area does not change with x. We also assume that gas pressure and gas density (rho) satisfy the equation of state, i.e. p = a^2 rho Given that p fracpartial ppartial x= frac12 fracpartial p^2partial x and phi is a constant througout the pipe (from the mass conservation), the conservation of momentum equation is integrated from the start of the pipe at x=0 to the end of the pipe at x=L, where L is the length of the pipe. Then, the equation for flux across the pipe is stated as    p^2(L)-p^2(0) = frac-lambda L a^2 phi phi D  We typically express the mass flux through the pipe in terms of mass flow, f, where f=phi A. Here, A=fracpi D^24 is the cross-sectional area of the pipe. Thus, the equation for mass flow through the pipe is stated as     p^2(L)-p^2(0) = frac-lambda L a^2 f f D A^2 To create a better numerically conditioned problem, it is very useful to non-dimensionalize the units. Here we use a typical pressure p_0 and a typical mass flow f_0 and normalize the equations. This yields    tildep^2(L)-tildep^2(0) = -tildef tildef left(fraclambda L Dright) left(fracf_0^2a^2A^2p_0^2right)where tildef=fracff_0 and tildep=fracpp_0 are the dimensionless mass flow and pressure, respectively, and are both of order one. Note that both terms in parenthesis on the right hand side of this equation are dimensionless.  For the purposes of convenience, we define resistance, w, as the constant w=left(fraclambda L Dright) left(fracf_0^2a^2A^2p_0^2right)Finally, in most data sets, nodal injections and withdrawals are defined in terms of volumetric flow, q, at a STP conditions. Given this data, we non-dimensionalize based on q. At STP conditions, the mass flow is derived as f=fracqrho_s, where  rho_s is the gas density at STP conditions.A complete gas flow mathematical model is the defined bybeginaligned\ntextsets \n N  textjunctions \n A^p  textpipes  \n A^c  textcompressors  \n A^v  textvalves  \n A = A^p cup A^c cup A^v  textedges   \n P P_i  textproducers and producers at junction i   \n C C_i  textconsumers and consumers at junction i    \n\ntextdata \n w_a  textresistance factor of pipeline a \n fl_j  textconsumption (mass flow) at consumer j \n fg_j  textproduction (mass flow) at producer j \n underlinealpha_a=1 overlinealpha_a  text(de)compression limits (squared) of edge a \n underlinep_i ge 0overlinep_i  textlimits on pressure squared at node i \n\ntextvariables \n p_i  textpressure squared at node i \n f_a  textmass flow on edge a \n alpha_a  textcompression ratio on compressor a\n v_a  textvalve status for valve a 1 if valve is open\n\ntextconstraints \n (p_i - p_j) = w_a f_af_a textWeymouth equation for pipe a \n textconnected from junction i to junction j  \nsumlimits_a=a_ijin A f_a - sumlimits_a=a_ji in A f_a = sum_j in P_i fg_j- sum_j in C_i fl_j  textmass flow balance at junction i \n alpha_a p_i = p_j  textcompression boost at compressor a \ntextmass flux balance at junction i \n f_a (1-alpha_a) le 0 textcompression ratio is forced to 1 \n textwhen flow is reversed through compressor a \nunderlinep_i leq p_i leq overlinep_i  textpressure limits at junction i \nunderlinealpha_a leq alpha_a leq overlinealpha_a  textcompression limits at compressor i \n-v_a M leq f_a leq v_a M  textonoff operations for valve a \n textwhere M is the maximum flow through the valve \np_j - v_a overlinep_j leq p_i leq p_j + v_a overlinep_i  textlinks junction pressures of valve a \n textconnected from junction i to junction j\nendalignedmost of the optimization models of GasModels are variations of this formulation. In practice, we discretize on flow direction to reduce the non convexities of this model and relax the assumption that the minimum compression ratio is 1.SI Units for various parametersParameter Description SI Units\nD Pipe Diameter m\nL Pipe Length m\nA Pipe Area Cross Section m^2\np Gas Pressure pascals\nrho Gas Density kg/m^3\nZ Gas compressibility factor none\nm Gas Molar Mass kg/mol\nT Gas Temperature K\nR Universal Gas Constant J/mol/K\nphi Gas Mass Flux kg/m^2/s\nf Gas Mass Flow kg/s\nlambda Pipe friction factor none"
},

{
    "location": "formulations/#",
    "page": "Network Formulations",
    "title": "Network Formulations",
    "category": "page",
    "text": ""
},

{
    "location": "formulations/#Network-Formulations-1",
    "page": "Network Formulations",
    "title": "Network Formulations",
    "category": "section",
    "text": ""
},

{
    "location": "formulations/#Type-Hierarchy-1",
    "page": "Network Formulations",
    "title": "Type Hierarchy",
    "category": "section",
    "text": "We begin with the top of the hierarchy, where we can distinguish between gas flow models. Currently, there are two variations of the weymouth equations, one where the directions of flux are known and one where they are unknown.AbstractDirectedGasFormulation <: AbstractGasFormulation\nAbstractUndirectedGasFormulation <: AbstractGasFormulationEach of these have a disjunctive form of the weymouth equations: The full non convex formulation and its conic relaxation.AbstractMINLPForm <: AbstractUndirectedGasFormulation\nAbstractMISOCPForm <: AbstractUndirectedGasFormulation\nAbstractMINLPDirectedForm <: AbstractDirectedGasFormulation\nAbstractMISOCPDirectedForm <: AbstractDirectedGasFormulation"
},

{
    "location": "formulations/#Gas-Models-1",
    "page": "Network Formulations",
    "title": "Gas Models",
    "category": "section",
    "text": "Each of these forms can be used as the type parameter for a GasModel, i.e.:MINLPGasModel = GenericGasModel(StandardMINLPForm)\nMISOCPGasModel = GenericGasModel(StandardMISOCPForm)For details on GenericGasModel, see the section on Gas Model."
},

{
    "location": "formulations/#User-Defined-Abstractions-1",
    "page": "Network Formulations",
    "title": "User-Defined Abstractions",
    "category": "section",
    "text": "The user-defined abstractions begin from a root abstract like the AbstractGasFormulation abstract type, i.e. AbstractMyFooForm <: AbstractGasFormulation\n\nStandardMyFooForm <: AbstractFooForm\nFooGasModel = GenericGasModel{StandardFooForm}"
},

{
    "location": "formulations/#GasModels.constraint_on_off_compressor_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction",
    "category": "method",
    "text": "constraints on flow across compressors when directions are constants \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_compressor_flow_direction_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across compressors when the directions are constants \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_compressor_ratios-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_ratios",
    "category": "method",
    "text": "on/off constraint for compressors when the flow direction is constant \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_control_valve_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across control valves when directions are constants \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_control_valve_pressure_drop-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across control valves when directions are constants \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pipe_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across pipes where the directions are fixed \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pipe_flow_direction_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across pipes when directions are fixed \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pressure_drop-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across pipes \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pressure_drop_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop_ne",
    "category": "method",
    "text": "constraints on pressure drop across pipes when the direction is fixed \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_short_pipe_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across short pipes when the directions are constants \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_valve_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractDirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across valves when directions are constants \n\n\n\n\n\n"
},

{
    "location": "formulations/#Directed-Models-1",
    "page": "Network Formulations",
    "title": "Directed Models",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/directed.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "formulations/#GasModels.constraint_conserve_flow-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_conserve_flow",
    "category": "method",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_conserve_flow_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_conserve_flow_ne",
    "category": "method",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_compressor_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction",
    "category": "method",
    "text": "constraints on flow across compressors \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_compressor_flow_direction_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across compressors \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_compressor_ratios-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_compressor_ratios",
    "category": "method",
    "text": "enforces pressure changes bounds that obey compression ratios \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_control_valve_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across control valves \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_control_valve_pressure_drop-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across control valves \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pipe_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across pipes \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pipe_flow_direction_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne",
    "category": "method",
    "text": "constraints on flow across pipes \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pressure_drop-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop",
    "category": "method",
    "text": "constraints on pressure drop across pipes \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_pressure_drop_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_pressure_drop_ne",
    "category": "method",
    "text": "constraints on pressure drop across pipes \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_short_pipe_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction",
    "category": "method",
    "text": "constraints on flow across short pipes \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_on_off_valve_flow_direction-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_on_off_valve_flow_direction",
    "category": "method",
    "text": "constraints on flow across valves \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_parallel_flow-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_parallel_flow",
    "category": "method",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_parallel_flow_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_parallel_flow_ne",
    "category": "method",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_sink_flow-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_sink_flow",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_sink_flow_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_sink_flow_ne",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_source_flow-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_source_flow",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_source_flow_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.constraint_source_flow_ne",
    "category": "method",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.variable_connection_direction-Union{Tuple{GenericGasModel{T}}, Tuple{T}, Tuple{GenericGasModel{T},Int64}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.variable_connection_direction",
    "category": "method",
    "text": "variables associated with direction of flow on the connections. yp = 1 imples flow goes from fjunction to tjunction. yn = 1 imples flow goes from tjunction to fjunction \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.variable_connection_direction_ne-Union{Tuple{GenericGasModel{T}}, Tuple{T}, Tuple{GenericGasModel{T},Int64}} where T<:GasModels.AbstractUndirectedGasFormulation",
    "page": "Network Formulations",
    "title": "GasModels.variable_connection_direction_ne",
    "category": "method",
    "text": "variables associated with direction of flow on the connections \n\n\n\n\n\n"
},

{
    "location": "formulations/#Undirected-Models-1",
    "page": "Network Formulations",
    "title": "Undirected Models",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/undirected.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "formulations/#GasModels.constraint_weymouth-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMINLPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with fixed direction variables\n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_weymouth-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMINLPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_weymouth_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMINLPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with fixed directions for MINLP\n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_weymouth_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMINLPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables for MINLP \n\n\n\n\n\n"
},

{
    "location": "formulations/#MINLP-1",
    "page": "Network Formulations",
    "title": "MINLP",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/minlp.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "formulations/#GasModels.constraint_weymouth-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMISOCPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with directed flow\n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_weymouth-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMISOCPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables \n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_weymouth_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMISOCPDirectedForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with fixed direction\n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.constraint_weymouth_ne-Union{Tuple{T}, Tuple{GenericGasModel{T},Int64,Any,Any,Any,Any,Any,Any,Any}} where T<:GasModels.AbstractMISOCPForm",
    "page": "Network Formulations",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "method",
    "text": "Weymouth equation with discrete direction variables for MINLP\n\n\n\n\n\n"
},

{
    "location": "formulations/#GasModels.variable_flow-Union{Tuple{GenericGasModel{T}}, Tuple{T}, Tuple{GenericGasModel{T},Int64}} where T<:GasModels.AbstractMISOCPForm",
    "page": "Network Formulations",
    "title": "GasModels.variable_flow",
    "category": "method",
    "text": "\n\n\n\n"
},

{
    "location": "formulations/#GasModels.variable_mass_flow-Union{Tuple{GenericGasModel{T}}, Tuple{T}, Tuple{GenericGasModel{T},Int64}} where T<:Union{AbstractMISOCPDirectedForm, AbstractMISOCPForm}",
    "page": "Network Formulations",
    "title": "GasModels.variable_mass_flow",
    "category": "method",
    "text": "\n\n\n\n"
},

{
    "location": "formulations/#GasModels.variable_mass_flow_ne-Union{Tuple{GenericGasModel{T}}, Tuple{T}, Tuple{GenericGasModel{T},Int64}} where T<:Union{AbstractMISOCPDirectedForm, AbstractMISOCPForm}",
    "page": "Network Formulations",
    "title": "GasModels.variable_mass_flow_ne",
    "category": "method",
    "text": "\n\n\n\n"
},

{
    "location": "formulations/#MISOCP-1",
    "page": "Network Formulations",
    "title": "MISOCP",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"form/misocp.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "specifications/#",
    "page": "Problem Specifications",
    "title": "Problem Specifications",
    "category": "page",
    "text": ""
},

{
    "location": "specifications/#Problem-Specifications-1",
    "page": "Problem Specifications",
    "title": "Problem Specifications",
    "category": "section",
    "text": ""
},

{
    "location": "specifications/#Gas-Flow-(GF)-1",
    "page": "Problem Specifications",
    "title": "Gas Flow (GF)",
    "category": "section",
    "text": ""
},

{
    "location": "specifications/#Variables-1",
    "page": "Problem Specifications",
    "title": "Variables",
    "category": "section",
    "text": "variable_pressure_sqr(gm)\nvariable_flow(gm)\nvariable_valve_operation(gm)"
},

{
    "location": "specifications/#Constraints-1",
    "page": "Problem Specifications",
    "title": "Constraints",
    "category": "section",
    "text": "for i in ids(gm, :junction)\n    constraint_junction_flow(gm, i)\nend\n    \nfor i in [collect(ids(gm, :pipe)); collect(ids(gm, :resistor))] \n    constraint_pipe_flow(gm, i) \nend\n\nfor i in ids(gm, :short_pipe)\n    constraint_short_pipe_flow(gm, i) \nend\n        \nfor i in ids(gm, :compressor)\n    constraint_compressor_flow(gm, i) \nend\n    \nfor i in ids(gm, :valve)\n    constraint_valve_flow(gm, i) \nend\n    \nfor i in ids(gm, :control_valve)     \n    constraint_control_valve_flow(gm, i) \nend"
},

{
    "location": "specifications/#Maximum-Load-(LS)-1",
    "page": "Problem Specifications",
    "title": "Maximum Load (LS)",
    "category": "section",
    "text": ""
},

{
    "location": "specifications/#Variables-2",
    "page": "Problem Specifications",
    "title": "Variables",
    "category": "section",
    "text": "variable_flow(gm)  \nvariable_pressure_sqr(gm)\nvariable_valve_operation(gm)\nvariable_load(gm)\nvariable_production(gm)"
},

{
    "location": "specifications/#Objective-1",
    "page": "Problem Specifications",
    "title": "Objective",
    "category": "section",
    "text": "objective_max_load(gm)"
},

{
    "location": "specifications/#Constraints-2",
    "page": "Problem Specifications",
    "title": "Constraints",
    "category": "section",
    "text": "for i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] \n    constraint_pipe_flow(gm, i) \nend\n    \nfor i in ids(gm, :junction)\n    constraint_junction_flow_ls(gm, i)      \nend\n    \nfor i in ids(gm, :short_pipe)\n    constraint_short_pipe_flow(gm, i) \nend\n        \nfor i in ids(gm, :compressor) \n    constraint_compressor_flow(gm, i) \nend\n    \nfor i in ids(gm, :valve)     \n    constraint_valve_flow(gm, i) \nend\n    \nfor i in ids(gm, :control_valve) \n    constraint_control_valve_flow(gm, i) \nend"
},

{
    "location": "specifications/#Expansion-Planning-(NE)-1",
    "page": "Problem Specifications",
    "title": "Expansion Planning (NE)",
    "category": "section",
    "text": ""
},

{
    "location": "specifications/#Objective-2",
    "page": "Problem Specifications",
    "title": "Objective",
    "category": "section",
    "text": "objective_min_ne_cost(gm)"
},

{
    "location": "specifications/#Variables-3",
    "page": "Problem Specifications",
    "title": "Variables",
    "category": "section",
    "text": "variable_pressure_sqr(gm)\nvariable_flow(gm)\nvariable_flow_ne(gm)    \nvariable_valve_operation(gm)\nvariable_pipe_ne(gm)\nvariable_compressor_ne(gm)"
},

{
    "location": "specifications/#Constraints-3",
    "page": "Problem Specifications",
    "title": "Constraints",
    "category": "section",
    "text": "for i in ids(gm, :junction)\n    constraint_junction_flow_ne(gm, i) \nend\n\nfor i in [collect(ids(gm,:pipe)); collect(ids(gm,:resistor))] \n    constraint_pipe_flow_ne(gm, i)\nend\n\nfor i in ids(gm,:ne_pipe) \n    constraint_new_pipe_flow_ne(gm, i)\nend\n    \nfor i in ids(gm, :short_pipe) \n    constraint_short_pipe_flow_ne(gm, i)\nend\n    \nfor i in ids(gm, :compressor)\n    constraint_compressor_flow_ne(gm, i)\nend\n    \nfor i in ids(gm, :ne_compressor) \n    constraint_new_compressor_flow_ne(gm, i)\nend  \n         \nfor i in ids(gm, :valve)  \n    constraint_valve_flow(gm, i)       \nend\n    \nfor i in ids(gm, :control_valve)\n    constraint_control_valve_flow(gm, i)       \nend\n    \nexclusive = Dict()\nfor (idx, pipe) in gm.ref[:nw][gm.cnw][:ne_pipe]\n    i = min(pipe[\"f_junction\"],pipe[\"t_junction\"])\n    j = max(pipe[\"f_junction\"],pipe[\"t_junction\"])\n   \n    if haskey(exclusive, i) == false  \n        exclusive[i] = Dict()\n    end  \n           \n    if haskey(exclusive[i], j) == false \n        constraint_exclusive_new_pipes(gm, i, j)         \n        exclusive[i][j] = true\n    end             \nend"
},

{
    "location": "model/#",
    "page": "GasModel",
    "title": "GasModel",
    "category": "page",
    "text": ""
},

{
    "location": "model/#GasModels.GenericGasModel",
    "page": "GasModel",
    "title": "GasModels.GenericGasModel",
    "category": "type",
    "text": "mutable struct GenericGasModel{T<:AbstractGasFormulation}\n    model::JuMP.Model\n    data::Dict{String,Any}\n    setting::Dict{String,Any}\n    solution::Dict{String,Any}\n    var::Dict{Symbol,Any} # model variable lookup\n    constraint::Dict{Symbol, Dict{Any, ConstraintRef}} # model constraint lookup\n    ref::Dict{Symbol,Any} # reference data\n    ext::Dict{Symbol,Any} # user extensions\nend\n\nwhere\n\ndata is the original data, usually from reading in a .json file,\nsetting usually looks something like Dict(\"output\" => Dict(\"flows\" => true)), and\nref is a place to store commonly used pre-computed data from of the data dictionary,   primarily for converting data-types, filtering out deactivated components, and storing   system-wide values that need to be computed globally. See build_ref(data) for further details.\n\nMethods on GenericGasModel for defining variables and adding constraints should\n\nwork with the ref dict, rather than the original data dict,\nadd them to model::JuMP.Model, and\nfollow the conventions for variable and constraint names.\n\n\n\n\n\n"
},

{
    "location": "model/#GasModels.build_ref",
    "page": "GasModel",
    "title": "GasModels.build_ref",
    "category": "function",
    "text": "Returns a dict that stores commonly used pre-computed data from of the data dictionary, primarily for converting data-types, filtering out deactivated components, and storing system-wide values that need to be computed globally.\n\nSome of the common keys include:\n\n:max_mass_flow (see max_mass_flow(data)),\n:connection – the set of connections that are active in the network (based on the component status values),\n:pipe – the set of connections that are pipes (based on the component type values),\n:short_pipe – the set of connections that are short pipes (based on the component type values),\n:compressor – the set of connections that are compressors (based on the component type values),\n:valve – the set of connections that are valves (based on the component type values),\n:control_valve – the set of connections that are control valves (based on the component type values),\n:resistor – the set of connections that are resistors (based on the component type values),\n:parallel_connections – the set of all existing connections between junction pairs (i,j),\n:all_parallel_connections – the set of all existing and new connections between junction pairs (i,j),\n:junction_connections – the set of all existing connections of junction i,\n:junction_ne_connections – the set of all new connections of junction i,\n:junction_consumers – the mapping Dict(i => [consumer[\"ql_junc\"] for (i,consumer) in ref[:consumer]]).\n:junction_producers – the mapping Dict(i => [producer[\"qg_junc\"] for (i,producer) in ref[:producer]]).\njunction[degree] – the degree of junction i using existing connections (see add_degree)),\njunction[all_degree] – the degree of junction i using existing and new connections (see add_degree)),\nconnection[pd_min,pd_max] – the max and min square pressure difference (see add_pd_bounds_swr)),\n\nIf :ne_connection does not exist, then an empty reference is added If status does not exist in the data, then 1 is added If construction cost does not exist in the :ne_connection, then 0 is added\n\n\n\n\n\n"
},

{
    "location": "model/#Gas-Model-1",
    "page": "GasModel",
    "title": "Gas Model",
    "category": "section",
    "text": "CurrentModule = GasModelsAll methods for constructing gasmodels should be defined on the following type:GenericGasModelwhich utilizes the following (internal) functions:build_ref"
},

{
    "location": "objective/#",
    "page": "Objective",
    "title": "Objective",
    "category": "page",
    "text": ""
},

{
    "location": "objective/#GasModels.objective_max_load",
    "page": "Objective",
    "title": "GasModels.objective_max_load",
    "category": "function",
    "text": "function for maximizing load \n\n\n\n\n\n"
},

{
    "location": "objective/#GasModels.objective_min_ne_cost",
    "page": "Objective",
    "title": "GasModels.objective_min_ne_cost",
    "category": "function",
    "text": "function for costing expansion of pipes and compressors \n\n\n\n\n\n"
},

{
    "location": "objective/#Objective-1",
    "page": "Objective",
    "title": "Objective",
    "category": "section",
    "text": "Modules = [GasModels]\nPages   = [\"core/objective.jl\"]\nOrder   = [:function]\nPrivate  = true"
},

{
    "location": "variables/#",
    "page": "Variables",
    "title": "Variables",
    "category": "page",
    "text": ""
},

{
    "location": "variables/#GasModels.getstart",
    "page": "Variables",
    "title": "GasModels.getstart",
    "category": "function",
    "text": "extracts the start value\n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_compressor_ne",
    "page": "Variables",
    "title": "GasModels.variable_compressor_ne",
    "category": "function",
    "text": "variables associated with building compressors \n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_load_mass_flow",
    "page": "Variables",
    "title": "GasModels.variable_load_mass_flow",
    "category": "function",
    "text": "variables associated with demand \n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_mass_flow",
    "page": "Variables",
    "title": "GasModels.variable_mass_flow",
    "category": "function",
    "text": "variables associated with mass flow \n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_mass_flow_ne",
    "page": "Variables",
    "title": "GasModels.variable_mass_flow_ne",
    "category": "function",
    "text": "variables associated with mass flow in expansion planning \n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_pipe_ne",
    "page": "Variables",
    "title": "GasModels.variable_pipe_ne",
    "category": "function",
    "text": "variables associated with building pipes \n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_pressure_sqr",
    "page": "Variables",
    "title": "GasModels.variable_pressure_sqr",
    "category": "function",
    "text": "variables associated with pressure squared \n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_production_mass_flow",
    "page": "Variables",
    "title": "GasModels.variable_production_mass_flow",
    "category": "function",
    "text": "variables associated with production \n\n\n\n\n\n"
},

{
    "location": "variables/#GasModels.variable_valve_operation",
    "page": "Variables",
    "title": "GasModels.variable_valve_operation",
    "category": "function",
    "text": "0-1 variables associated with operating valves \n\n\n\n\n\n"
},

{
    "location": "variables/#Variables-1",
    "page": "Variables",
    "title": "Variables",
    "category": "section",
    "text": "We provide the following methods to provide a compositional approach for defining common variables used in gas flow models. These methods should always be defined over \"GenericGasModel\".Modules = [GasModels]\nPages   = [\"core/variable.jl\"]\nOrder   = [:type, :function]\nPrivate  = true"
},

{
    "location": "constraints/#",
    "page": "Constraints",
    "title": "Constraints",
    "category": "page",
    "text": ""
},

{
    "location": "constraints/#Constraints-1",
    "page": "Constraints",
    "title": "Constraints",
    "category": "section",
    "text": "CurrentModule = GasModels"
},

{
    "location": "constraints/#Constraint-Templates-1",
    "page": "Constraints",
    "title": "Constraint Templates",
    "category": "section",
    "text": "Constraint templates help simplify data wrangling across multiple Gas Flow formulations by providing an abstraction layer between the network data and network constraint definitions. The constraint template\'s job is to extract the required parameters from a given network data structure and pass the data as named arguments to the Gas Flow formulations.These templates should be defined over GenericGasModel and should not refer to model variables. For more details, see the files: core/constraint_template.jl and core/constraint.jl."
},

{
    "location": "constraints/#Junction-Constraints-1",
    "page": "Constraints",
    "title": "Junction Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints/#Flow-Balance-Constraints-1",
    "page": "Constraints",
    "title": "Flow Balance Constraints",
    "category": "section",
    "text": "constraint_junction_flow_balance"
},

{
    "location": "constraints/#Load-Shedding-Constraints-1",
    "page": "Constraints",
    "title": "Load Shedding Constraints",
    "category": "section",
    "text": "constraint_junction_flow_balance_ls"
},

{
    "location": "constraints/#Network-Expansion-Constraints-1",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_junction_flow_balance_ne\nconstraint_junction_flow_balance_ne_ls"
},

{
    "location": "constraints/#Pipe-Constraints-1",
    "page": "Constraints",
    "title": "Pipe Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints/#GasModels.constraint_weymouth",
    "page": "Constraints",
    "title": "GasModels.constraint_weymouth",
    "category": "function",
    "text": "Weymouth equation with discrete direction variables \n\n\n\n\n\nWeymouth equation with discrete direction variables \n\n\n\n\n\nWeymouth equation with fixed direction variables\n\n\n\n\n\nWeymouth equation with discrete direction variables \n\n\n\n\n\nWeymouth equation with directed flow\n\n\n\n\n\n"
},

{
    "location": "constraints/#Weymouth\'s-Law-Constraints-1",
    "page": "Constraints",
    "title": "Weymouth\'s Law Constraints",
    "category": "section",
    "text": "constraint_weymouth"
},

{
    "location": "constraints/#GasModels.constraint_on_off_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across pipes \n\n\n\n\n\nconstraints on pressure drop across pipes \n\n\n\n\n\nconstraints on pressure drop across pipes \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_on_off_pipe_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction",
    "category": "function",
    "text": "constraints on flow across pipes \n\n\n\n\n\nconstraints on flow across pipes where the directions are fixed \n\n\n\n\n\nconstraints on flow across pipes \n\n\n\n\n\n"
},

{
    "location": "constraints/#Direction-On/off-Constraints-1",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_pressure_drop\nconstraint_on_off_pipe_flow_direction"
},

{
    "location": "constraints/#GasModels.constraint_weymouth_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_weymouth_ne",
    "category": "function",
    "text": "Weymouth equation with discrete direction variables for MINLP \n\n\n\n\n\nWeymouth equation with discrete direction variables for MINLP \n\n\n\n\n\nWeymouth equation with fixed directions for MINLP\n\n\n\n\n\nWeymouth equation with discrete direction variables for MINLP\n\n\n\n\n\nWeymouth equation with fixed direction\n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_on_off_pressure_drop_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pressure_drop_ne",
    "category": "function",
    "text": "constraints on pressure drop across pipes \n\n\n\n\n\nconstraints on pressure drop across pipes when the direction is fixed \n\n\n\n\n\nconstraints on pressure drop across pipes \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_on_off_pipe_flow_direction_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_pipe_flow_direction_ne",
    "category": "function",
    "text": "constraints on flow across pipes \n\n\n\n\n\nconstraints on flow across pipes when directions are fixed \n\n\n\n\n\nconstraints on flow across pipes \n\n\n\n\n\n"
},

{
    "location": "constraints/#Network-Expansion-Constraints-2",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_weymouth_ne\nconstraint_on_off_pressure_drop_ne\nconstraint_on_off_pipe_flow_direction_ne"
},

{
    "location": "constraints/#Compressor-Constraints-1",
    "page": "Constraints",
    "title": "Compressor Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints/#GasModels.constraint_on_off_compressor_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction",
    "category": "function",
    "text": "constraints on flow across compressors \n\n\n\n\n\nconstraints on flow across compressors when directions are constants \n\n\n\n\n\nconstraints on flow across compressors \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_on_off_compressor_ratios",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_ratios",
    "category": "function",
    "text": "enforces pressure changes bounds that obey compression ratios \n\n\n\n\n\non/off constraint for compressors when the flow direction is constant \n\n\n\n\n\nenforces pressure changes bounds that obey compression ratios \n\n\n\n\n\n"
},

{
    "location": "constraints/#Direction-On/off-Constraints-2",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_compressor_flow_direction\nconstraint_on_off_compressor_ratios"
},

{
    "location": "constraints/#GasModels.constraint_on_off_compressor_flow_direction_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_flow_direction_ne",
    "category": "function",
    "text": "constraints on flow across compressors \n\n\n\n\n\nconstraints on flow across compressors when the directions are constants \n\n\n\n\n\nconstraints on flow across compressors \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_on_off_compressor_ratios_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_compressor_ratios_ne",
    "category": "function",
    "text": "constraints on pressure drop across control valves \n\n\n\n\n\nconstraints on pressure drop across control valves \n\n\n\n\n\n"
},

{
    "location": "constraints/#Network-Expansion-Constraints-3",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_on_off_compressor_flow_direction_ne\nconstraint_on_off_compressor_ratios_ne"
},

{
    "location": "constraints/#Control-Valve-Constraints-1",
    "page": "Constraints",
    "title": "Control Valve Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints/#GasModels.constraint_on_off_control_valve_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_flow_direction",
    "category": "function",
    "text": "constraints on flow across control valves \n\n\n\n\n\nconstraints on flow across control valves when directions are constants \n\n\n\n\n\nconstraints on flow across control valves \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_on_off_control_valve_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_control_valve_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across control valves \n\n\n\n\n\nconstraints on pressure drop across control valves when directions are constants \n\n\n\n\n\nconstraints on pressure drop across control valves \n\n\n\n\n\n"
},

{
    "location": "constraints/#Direction-On/off-Constraints-3",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_control_valve_flow_direction\nconstraint_on_off_control_valve_pressure_drop"
},

{
    "location": "constraints/#Valve-Constraints-1",
    "page": "Constraints",
    "title": "Valve Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints/#GasModels.constraint_on_off_valve_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_valve_flow_direction",
    "category": "function",
    "text": "constraints on flow across valves \n\n\n\n\n\nconstraints on flow across valves when directions are constants \n\n\n\n\n\nconstraints on flow across valves \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_on_off_valve_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_valve_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across valves \n\n\n\n\n\nconstraints on pressure drop across valves \n\n\n\n\n\n"
},

{
    "location": "constraints/#Direction-On/off-Constraints-4",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_valve_flow_direction\nconstraint_on_off_valve_pressure_drop"
},

{
    "location": "constraints/#Short-Pipes-1",
    "page": "Constraints",
    "title": "Short Pipes",
    "category": "section",
    "text": ""
},

{
    "location": "constraints/#GasModels.constraint_on_off_short_pipe_flow_direction",
    "page": "Constraints",
    "title": "GasModels.constraint_on_off_short_pipe_flow_direction",
    "category": "function",
    "text": "constraints on flow across short pipes \n\n\n\n\n\nconstraints on flow across short pipes when the directions are constants \n\n\n\n\n\nconstraints on flow across short pipes \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_short_pipe_pressure_drop",
    "page": "Constraints",
    "title": "GasModels.constraint_short_pipe_pressure_drop",
    "category": "function",
    "text": "constraints on pressure drop across pipes \n\n\n\n\n\nconstraints on pressure drop across pipes \n\n\n\n\n\n"
},

{
    "location": "constraints/#Direction-On/off-Constraints-5",
    "page": "Constraints",
    "title": "Direction On/off Constraints",
    "category": "section",
    "text": "constraint_on_off_short_pipe_flow_direction\nconstraint_short_pipe_pressure_drop"
},

{
    "location": "constraints/#GasModels.constraint_source_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_source_flow",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n\n\nMake sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_sink_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_sink_flow",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n\n\nMake sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_conserve_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_conserve_flow",
    "category": "function",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n\n\nThis constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_parallel_flow",
    "page": "Constraints",
    "title": "GasModels.constraint_parallel_flow",
    "category": "function",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n\n\nensures that parallel lines have flow in the same direction \n\n\n\n\n\n"
},

{
    "location": "constraints/#Direction-Cutting-Constraints-1",
    "page": "Constraints",
    "title": "Direction Cutting Constraints",
    "category": "section",
    "text": "constraint_source_flow\nconstraint_sink_flow\nconstraint_conserve_flow\nconstraint_parallel_flow"
},

{
    "location": "constraints/#GasModels.constraint_source_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_source_flow_ne",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n\n\nMake sure there is at least one direction set to take flow away from a junction (typically used on source nodes) \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_sink_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_sink_flow_ne",
    "category": "function",
    "text": "Make sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n\n\nMake sure there is at least one direction set to take flow to a junction (typically used on sink nodes) \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_conserve_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_conserve_flow_ne",
    "category": "function",
    "text": "This constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n\n\nThis constraint is intended to ensure that flow is on direction through a node with degree 2 and no production or consumption \n\n\n\n\n\n"
},

{
    "location": "constraints/#GasModels.constraint_parallel_flow_ne",
    "page": "Constraints",
    "title": "GasModels.constraint_parallel_flow_ne",
    "category": "function",
    "text": "ensures that parallel lines have flow in the same direction \n\n\n\n\n\nensures that parallel lines have flow in the same direction \n\n\n\n\n\n"
},

{
    "location": "constraints/#Network-Expansion-Constraints-4",
    "page": "Constraints",
    "title": "Network Expansion Constraints",
    "category": "section",
    "text": "constraint_source_flow_ne\nconstraint_sink_flow_ne\nconstraint_conserve_flow_ne\nconstraint_parallel_flow_ne"
},

{
    "location": "parser/#",
    "page": "File IO",
    "title": "File IO",
    "category": "page",
    "text": ""
},

{
    "location": "parser/#File-IO-1",
    "page": "File IO",
    "title": "File IO",
    "category": "section",
    "text": "TODO"
},

{
    "location": "developer/#",
    "page": "Developer",
    "title": "Developer",
    "category": "page",
    "text": ""
},

{
    "location": "developer/#Developer-Documentation-1",
    "page": "Developer",
    "title": "Developer Documentation",
    "category": "section",
    "text": "Nothing yet."
},

]}
