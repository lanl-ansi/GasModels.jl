function mgc = model6_new_format

mgc.gas_specific_gravity         = 0.6;
mgc.specific_heat_capacity_ratio = 1.4;
mgc.temperature                  = 288.706;
mgc.R                            = 8.314;
mgc.compressibility_factor       = 1;
mgc.base_pressure                = 3000000; % all base values are in same units as specified by units field
mgc.base_length                  = 5000; % all base values are in same units as specified by units field
mgc.base_flow                    = 8071.8;
mgc.units                        = 'si';
mgc.is_per_unit                  = 0;
mgc.economic_weighting           = 0.95;
mgc.sound_speed                  = 371.6643;


%% sources data
%column_names% name agreement_year description
mgc.sources = [
    'test' 2020 'test data source'
]

%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon
mgc.junction = [
1	3000000	6000000 4000000 1  1  'synthetic6'  '1'  -0.6550  0
2	3000000	6000000 3000000	0  1  'synthetic6'  '2'  -0.0421  0
3	3000000	6000000 3000000	0  1	'synthetic6'  '3'  0.6400   0.5
4	3000000	6000000 3000000	0  1	'synthetic6'  '4'  0.9600   -0.5
5	3000000	6000000 3000000	0  1	'synthetic6'  '5'  -0.6050  0
6	3000000	6000000 3000000	0  1	'synthetic6'  '6'  -0.0021  -0.04
];

%% pipeline data
% id fr_junction to_junction diameter length friction_factor p_min p_max status is_bidirectional pipeline_name num_spatial_discretization_points
mgc.pipe = [
1	5	2	0.6	50000	0.01	3000000	6000000	1  1  'synthetic6'  1
2	2	3	0.6	80000	0.01	3000000	6000000	1  1  'synthetic6'  1
3	6	4	0.6	80000	0.01	3000000	6000000	1  1  'synthetic6'  1
4	3	4	0.3	80000	0.01	3000000	6000000	1  1  'synthetic6'  1
];

%% compressor data
% id fr_junction to_junction c_ratio_min c_ratio_max power_max flow_min flow_max inlet_p_min inlet_p_max outlet_p_min outlet_p_max status operating_cost directionality compressor_station_name pipeline_name totat_installed_power num_compressor_units compressor_type design_suction_pressure design_discharge_pressure max_compressed_volumne design_fuel_required design_electric_power_required num_units_for_peak_service peak_year
mgc.compressor = [
1	1	5	1	1.40    3000000 	0	1000  3000000	6000000  3000000	6000000  1  10 2
2	2	6	1	1.35	  2000000 	0	1000  3000000	6000000  3000000	6000000  1  10 2
];

%% transfer data
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price offer_price exchange_point_name pipeline_name other_pipeline_name design_pressure meter_capacity daily_scheduled_flow
mgc.transfer = [
1  2  0  30.0 0  1  1  3.0   2.0   'LDC_A'
2  3  0  40.0 0  1  1  4.0   2.0   'LDC_B'
3  4  0  20.0 0  1  1  5.0   2.0   'LDC_C'
4  3  0  30.0 0  1  1  2.5   2.0   'PP_A'
5  4  0  10.0 0  1  1  3.0   2.0   'PP_B'
];

%% receipt data
% id junction_id injection_min injection_max injection_nominal is_dispatchable status offer_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.receipt = [
1    1    0    1000.0    500    1     1  1.25
];

%% delivery data
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.delivery = [
1    2    0 1.0  0  0  1  0
2    3    0 2.0  0  0  1  0
3    4    0 1.5  0  0  1  0
4    5    0 2.0  0  0  1  0
5    6    0 1.0  0  0  1  0
];
