function mgc = model30_new_format

mgc.gas_specific_gravity = 0.6;
mgc.specific_heat_capacity_ratio = 1.4;
mgc.temperature = 288.7060;
mgc.sound_speed = 371.6643;
mgc.R = 8.314;
mgc.gas_molar_mass = 0.01737756;
mgc.compressibility_factor = 1;
mgc.base_pressure = 3000000; % all base values are in same units as specified by units field
mgc.base_length = 5000; % all base values are in same units as specified by units field
mgc.units = 1;
mgc.is_per_unit = 0;
mgc.economic_weighting = 0.95;


%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon 
mgc.junction = [
1   3447378.645 5515805.832 3447378.645 1  1    'synthetic30'  1    0.8714  -0.755
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
];

%% pipeline data
% id f_junction t_junction diameter length friction_factor p_min p_max status is_bidirectional pipeline_name num_spatial_discretization_points
mgc.pipe = [
1   26  2	0.9144	100000	0.01    3447378.645 5515805.832	1  1  'synthetic30'  1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
];

%% compressor data
% id f_junction t_junction c_ratio_min c_ratio_max power_max flow_min flow_max inlet_p_min inlet_p_max outlet_p_min outlet_p_max status operating_cost directionality compressor_station_name pipeline_name total_installed_power num_compressor_units compressor_type design_suction_pressure design_discharge_pressure max_compressed_volume design_fuel_required design_electric_power_required num_units_for_peak_service peak_year
mgc.compressor = [
1	1	5	1	1.40    3000000 	0	1000  3000000	6000000  3000000	6000000  1  10 2
2	2	6	1	1.35	2000000 	0	1000  3000000	6000000  3000000	6000000  1  10 2
];

%% transfer 
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price offer_price exchange_point_name pipeline_name other_pipeline_name design_pressure meter_capacity daily_scheduled_flow
mgc.transfer = [
1  2  0  30 0  1  1  3.0   2.0   'LDC_A'
2  3  0  40 0  1  1  4.0   2.0   'LDC_B'
3  4  0  20 0  1  1  5.0   2.0   'LDC_C'
4  3  0  30 0  1  1  2.5   2.0   'PP_A'
5  4  0  10 0  1  1  3.0   2.0   'PP_B'
];

%% receipt
% id junction_id injection_min injection_max injection_nominal is_dispatchable status offer_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.receipt = [
1    1    0    1000    500    1     1  1.25
];

%% delivery
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.consumer = [
1    2    0 1.0  0  0  1  0
2    3    0 2.0  0  0  1  0
3    4    0 1.5  0  0  1  0
4    5    0 2.0  0  0  1  0
5    6    0 1.0  0  0  1  0
];
