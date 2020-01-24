function mgc = model30_new_format

mgc.gas_specific_gravity = 0.6;
mgc.specific_heat_capacity_ratio = 1.4;
mgc.temperature = 288.7060;
mgc.compressibility_factor = 1;
mgc.base_pressure = 3447378.645; % all base values are in same units as specified by units field
mgc.base_length = 5000; % all base values are in same units as specified by units field
mgc.units = 'si';
mgc.is_per_unit = 0;
mgc.economic_weighting = 0.95;


%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon 
mgc.junction = [
1   3447378.645 5515805.832 3447378.645 1   1   'synthetic30'   1   0.8714  -0.755
2   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   2   0.4018  -0.2421
3   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   3   0.3762  0.1248
4   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   4   0.4099  0.2794
5   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   5   0.6983  0.2794
6   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   6   0.8161  0.139
7   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   7   0.72    0.6232
8   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   8   0.8401  0.7751
9   3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   9   0.1949  -0.245
10  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   10  -0.1382 -0.6576
11  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   11  -0.1502 -0.8639
12  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   12  0.0901  -0.9126
13  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   13  -0.3377 -0.9069
14  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   14  -0.2066 -0.3064
15  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   15  -0.4555 -0.2564
16  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   16  -0.7103 -0.4456
17  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   17  -0.7656 -0.6777
18  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   18  -0.869  -0.7092
19  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   19  -0.7993 -0.2994
20  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   20  -0.1264 0.2909
21  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   21  -0.3353 0.3539
22  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   22  -0.4363 0.6117
23  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   23  -0.4531 0.7436
24  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   24  -0.9228 0.7019
25  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   25  -0.2656 0.6146
26  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   26  0.8014  -0.685
27  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   27  0.3218  -0.2421
28  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   28  0.3762  0.1848
29  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   29  -0.2866 -0.3064
30  3447378.645 5515805.832 3447378.645 0   1   'synthetic30'   30  -0.1764 0.3009
];

%% pipeline data
% id f_junction t_junction diameter length friction_factor p_min p_max status is_bidirectional pipeline_name num_spatial_discretization_points
mgc.pipe = [
1   26  2	0.9144	100000	0.01    3447378.645 5515805.832	1  1  'synthetic30' 1
2   2   3   0.635   30000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
3   28  4   0.635   5000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1 
4   4   5   0.635   15000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1 
5   5   6   0.635   10000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
6   5   7   0.635   5000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1 
7   7   8   0.635   10000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1 
8   27  9   0.9144  5000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
9   9   10  0.9144  60000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
10  10  11  0.635   5000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
11  11  12  0.635   8000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
12  11  13  0.635   6000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
13  10  14  0.9144  80000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
14  29  15  0.9144  10000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
15  15  16  0.9144  20000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
16  16  17  0.635   3000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
17  17  18  0.635   6000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
18  16  19  0.635   5000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
19  15  20  0.9144  40000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
20  30  21  0.9144  5000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
21  21  22  0.9144  20000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
22  22  23  0.9144  5000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
23  23  24  0.9144  16000   0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
24  22  25  0.635   8000    0.01    3447378.645 5515805.832 1  1  'synthetic30' 1
];

%% compressor data
% id f_junction t_junction c_ratio_min c_ratio_max power_max flow_min flow_max inlet_p_min inlet_p_max outlet_p_min outlet_p_max status operating_cost directionality compressor_station_name pipeline_name total_installed_power num_compressor_units compressor_type design_suction_pressure design_discharge_pressure max_compressed_volume design_fuel_required design_electric_power_required num_units_for_peak_service peak_year
mgc.compressor = [
1	1	26	1	1.40    2609950     0	168.2844    3447378.645 5515805.832  3447378.645 5515805.832  1  10 2
2	2   27  1   1.40    1864250     0   144.243841  3447378.645 5515805.832  3447378.645 5515805.832  1  10 2
3   3   28  1   1.40    1118550     0   96.16256068 3447378.645 5515805.832  3447378.645 5515805.832  1  10 2
4   14  29  1   1.40    745700      0   144.243841  3447378.645 5515805.832  3447378.645 5515805.832  1  10 2
5   20  30  1   1.40    745700      0   144.243841  3447378.645 5515805.832  3447378.645 5515805.832  1  10 2
];

%% transfer 
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price offer_price exchange_point_name pipeline_name other_pipeline_name design_pressure meter_capacity daily_scheduled_flow
mgc.transfer = [
1   6   -1.7966  1.7966 0.0  1  1   11.979   10.781   'LDC_A'
2   8   -1.6468  1.6468 0.0  1  1   10.981   9.883    'LDC_B'
3   24  -1.4971  1.4971 0.0  1  1   13.310   11.979   'LDC_C'
4   25  -1.3474  1.3474 0.0  1  1   11.979   10.781   'LDC_D'
5   12  -1.6468  1.6468 0.0  1  1   12.811   11.530   'LDC_E'
6   13  -1.3474  1.3474 0.0  1  1   10.482   9.434    'LDC_F'
7   18  -1.4971  1.4971 0.0  1  1   13.310   11.979   'LDC_G'
8   19  -1.7966  1.7966 0.0  1  1   15.572   14.375   'LDC_H'
9   12  -0.7485  0.7485 0.0  1  1   5.832    5.241    'LDC_I'
10  25  -2.6533  2.6533 0.0  1  1   15.582   14.024   'PP_A'
11  6   -3.1839  3.1839 0.0  1  1   11.762   10.586   'PP_B'
12  18  -2.4584  2.4584 0.0  1  1   13.685   12.316   'PP_C'
13  24  -3.0047  3.0047 0.0  1  1   16.388   14.750   'PP_D'
14  24  -1.0926  1.0926 0.0  1  1   10.856   9.770    'PP_E'
15  25  -1.3658  1.3658 0.0  1  1   11.854   10.669   'PP_F'
];

%% receipt
% id junction_id injection_min injection_max injection_nominal is_dispatchable status offer_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.receipt = [
1    1    0    384.6502    0.0    1     1  6.2394
];

%% delivery
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price name company_name daily_scheduled_flow design_capacity operating_capacity is_firm edi_id
mgc.delivery = [
1   6   17.9666 17.9666 17.9666 0   1   0.0 'LDC_A'
2   8   16.4694 16.4694 16.4694 0   1   0.0 'LDC_B'
3   24  14.9722 14.9722 14.9722 0   1   0.0 'LDC_C'
4   25  13.4749 13.4749 13.4749 0   1   0.0 'LDC_D'
5   12  16.4695 16.4695 16.4695 0   1   0.0 'LDC_E'
6   13  13.4750 13.4750 13.4750 0   1   0.0 'LDC_F'
7   18  14.9722 14.9722 14.9722 0   1   0.0 'LDC_G'
8   19  17.9667 17.9667 17.9667 0   1   0.0 'LDC_H'
9   12  7.4861  7.4861  7.4861  0   1   0.0 'LDC_I'
10  25  5.9887  5.9887  5.9887  0   1   0.0 'PP_A'
11  6   7.1864  7.1864  7.1864  0   1   0.0 'PP_B'
12  18  5.3898  5.3898  5.3898  0   1   0.0 'PP_C'
13  24  6.5875  6.5875  6.5875  0   1   0.0 'PP_D'
14  24  2.3954  2.3954  2.3954  0   1   0.0 'PP_E'
15  25  2.9943  2.9943  2.9943  0   1   0.0 'PP_F'
];
