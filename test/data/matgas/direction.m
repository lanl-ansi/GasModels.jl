%% a simple model for testing the logic of directionality


function mgc = direction

mgc.gas_specific_gravity         = 0.6;
mgc.specific_heat_capacity_ratio = 1.4;
mgc.temperature                  = 288.706;
mgc.R                            = 8.314;
mgc.compressibility_factor       = 1;
mgc.base_pressure                = 3000000; % all base values are in same units as specified by units field
mgc.base_length                  = 5000; % all base values are in same units as specified by units field
mgc.units                        = 'si';
mgc.is_per_unit                  = 0;
mgc.economic_weighting           = 0.95;
mgc.gas_molar_mass               = 0.0185674; % kg/mol
mgc.sound_speed                  = 371.6643;

%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon
mgc.junction = [
1	  3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
10	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
11	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
12	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
13	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
14	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
20	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
21	3000000	8000000 4000000 1  1  'direction'  '1'   0.0  0.0
22	7000000	8000000 7000000 1  1  'direction'  '1'   0.0  0.0
23	3000000	8000000 4000000 1  1  'direction'  '1'   0.0  0.0
24	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
30	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
31	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
32	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
33	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
34	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
40	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
41	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
42	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
43	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
44	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
50	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
51	1000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
52	1000000	2000000 1000000 1  1  'direction'  '1'   0.0  0.0
53	1000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
54	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
60	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
61	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
62	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
63	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
64	3000000	6000000 4000000 1  1  'direction'  '1'   0.0  0.0
];

%% valve data
% id	fr_junction	to_junction	status
mgc.valve = [
10 1	10 1
12 11	12 1
13 12	13 1
14 14	1  1
20 1	20 1
22 21	22 1
23 22	23 1
24 24	1  1
30 1	30 1
32 31	32 1
33 32	33 1
34 34	1  1
40 1	40 1
42 41	42 1
43 42	43 1
44 44	1  1
50 1	50 1
52 51	52 1
53 52	53 1
54 54	1  1
60 1	60 1
62 61	62 1
63 62	63 1
64 64	1  1
1060 60	61	1
1063 63	64	1
];

%% pipeline data
% id fr_junction to_junction diameter length friction_factor p_min p_max status is_bidirectional pipeline_name num_spatial_discretization_points
mgc.pipe = [
10 10	11	0.6	50000	0.01	3000000	6000000	1  1  'direction'  1
13 13	14	0.6	80000	0.01	3000000	6000000	1  1  'direction'  1
];

%% compressor data
% id fr_junction to_junction c_ratio_min c_ratio_max power_max flow_min flow_max inlet_p_min inlet_p_max outlet_p_min outlet_p_max status operating_cost directionality compressor_station_name pipeline_name totat_installed_power num_compressor_units compressor_type design_suction_pressure design_discharge_pressure max_compressed_volumne design_fuel_required design_electric_power_required num_units_for_peak_service peak_year
mgc.compressor = [
20 20	21	1	1.2   100000000 	0	1000  3000000	8000000  3000000	8000000  1  10 2
23 23	24	1	1.2	  100000000 	0	1000  3000000	8000000  3000000	8000000  1  10 2
];

%% short_pipe data
% id	fr_junction	to_junction	status	is_bidirectional
mgc.short_pipe = [
30 30	31	  1	1
33 33	34	  1	1
];

%% resistor data
% id	fr_junction	to_junction	drag	diameter	status	is_bidirectional
mgc.resistor = [
40 40	41	7377164597  1	  1	1
43 43	44	7377164597	1	  1	1
];

% id	fr_junction	to_junction	reduction_factor_min	reduction_factor_max	flow_min	flow_max	status
mgc.regulator = [
50 50	51	0	1	-8000 8000	1
53 53	54	0	1	-8000 8000	1
];

%% receipt data
% id junction_id injection_min injection_max injection_nominal is_dispatchable status offer_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.receipt = [
1    1    0    1000    500    1     1  -1000
];

%% delivery data
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.delivery = [
12   12   0 10.0  10.0  0  1  0
22   22   0 10.0  10.0  0  1  0
32   32   0 10.0  10.0  0  1  0
42   42   0 10.0  10.0  0  1  0
52   52   0 10.0  10.0  0  1  0
62   62   0 10.0  10.0  0  1  0
];
