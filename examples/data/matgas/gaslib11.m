function mgc = gaslib11

%% required global data
mgc.gas_specific_gravity         = 0.6     ; % dimensionless
mgc.specific_heat_capacity_ratio = 1.4     ; % dimensionless
mgc.temperature                  = 288.706 ; % K
mgc.compressibility_factor       = 1       ; % dimensionless
mgc.units                        = 'si'    ;
%% optional global data
mgc.is_per_unit        = 0     ;
mgc.base_length        = 1000  ; % m
mgc.base_pressure      = 1.0e6 ; % Pa
mgc.base_flow          = 100   ; % kg/s
mgc.economic_weighting = 1     ; % dimensionless

%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon
mgc.junction = [
4  3.0e6 8.0e6 5.5e6 0 1 '4.0'  '4.0'  0.0     0.4   
1  3.0e6 8.0e6 5.5e6 0 1 '1.0'  '1.0'  0.0     0.2   
2  3.0e6 8.0e6 5.5e6 0 1 '2.0'  '2.0'  0.05    0.3   
6  3.0e6 8.0e6 8.0e6 1 1 '6.0'  '6.0'  0.0     0.0   
11 3.0e6 8.0e6 5.5e6 0 1 '11.0' '11.0' -0.0705 0.5705
5  3.0e6 8.0e6 5.5e6 0 1 '5.0'  '5.0'  0.0     0.5   
7  3.0e6 8.0e6 5.5e6 0 1 '7.0'  '7.0'  -0.15   0.3   
8  3.0e6 8.0e6 5.5e6 0 1 '8.0'  '8.0'  0.0     0.1   
10 3.0e6 8.0e6 5.5e6 0 1 '10.0' '10.0' 0.0705  0.5705
9  3.0e6 8.0e6 5.5e6 0 1 '9.0'  '9.0'  0.15    0.3   
3  3.0e6 8.0e6 5.5e6 0 1 '3.0'  '3.0'  -0.05   0.3   
];

%% pipe data
% id fr_junction to_junction diameter length friction_factor p_min p_max status
mgc.pipe = [
3 7 3  0.5 55000 0.002589574 0 1.0e8 1
4 2 9  0.5 55000 0.002589574 0 1.0e8 1
1 6 8  0.5 55000 0.002589574 0 1.0e8 1
5 2 4  0.5 55000 0.002589574 0 1.0e8 1
2 1 2  0.5 55000 0.002589574 0 1.0e8 1
6 3 4  0.5 55000 0.002589574 0 1.0e8 1
7 5 10 0.5 55000 0.002589574 0 1.0e8 1
8 5 11 0.5 55000 0.002589574 0 1.0e8 1
9 1 3  1.0 1000  0.01        0 1.0e8 1
];

%% compressor data
% id fr_junction to_junction c_ratio_min c_ratio_max power_max flow_min flow_max inlet_p_min inlet_p_max outlet_p_min outlet_p_max status operating_cost directionality
mgc.compressor = [
1 8 1 1 1.6 100000 0 2000 0 1.0e8 0 1.0e8 1 1 1
2 4 5 1 1.6 100000 0 2000 0 1.0e8 0 1.0e8 1 1 1
];

%% receipt data
% id junction_id injection_min injection_max injection_nominal is_dispatchable status offer_price
mgc.receipt = [
1 10 0 100 0 1 1 2   
2 7  0 0   0 1 1 2   
3 11 0 100 0 1 1 1.25
4 9  0 0   0 1 1 1   
5 6  0 300 0 1 1 1.25
];

%% delivery data
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price
mgc.delivery = [
1 10 0 50  0 1 1 3
2 7  0 100 0 1 1 3
3 11 0 100 0 1 1 5
4 9  0 150 0 1 1 3
5 6  0 0   0 1 1 0
];

end

