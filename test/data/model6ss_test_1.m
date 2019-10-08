function mgc = model6ss_test_1

mgc.sound_speed = 371.6643;
mgc.temperature = 288.7060;
mgc.R = 8.314;
mgc.compressibility_factor = 1;
mgc.gas_molar_mass = 0.01737756;
mgc.gas_specific_gravity = 0.6;
mgc.specific_heat_capacity_ratio = 1.4;
mgc.standard_density = 1;
mgc.baseP = 3000000;
mgc.baseF = 8071.8;
mgc.per_unit= 0;
mgc.economic_weighting = 0.95;


%% junction data
%  junction_i type pmin pmax status p
mgc.junction = [
1	1	3000000	6000000	1   4000000
2	0	3000000	6000000	1	3000000
3	0	3000000	6000000	1	3000000
4	0	3000000	6000000	1	3000000
5	0	3000000	6000000	1	3000000
6	0	3000000	6000000	1	3000000
];

%% pipeline data
% pipeline_i f_junction t_junction diameter length friction_factor status
mgc.pipe = [
1	5	2	0.6	50000	0.01	1
2	2	3	0.6	80000	0.01	1
3	6	4	0.6	80000	0.01	1
4	3	4	0.3	80000	0.01	1
];

%% compressor data
% compressor_i f_junction t_junction cmin cmax power_max fmin fmax status
mgc.compressor = [
1	1	5	1	1.4     3000000 	0	1000    1
2	2	6	1	1.35	2000000 	0	1000    1
];

%% producer
% producer_i junction fgmin fgmax fg status dispatchable
mgc.producer = [
6    1    0    1000    500    1     1
];

%% consumer
% consumer_i junction fd status dispatchable
mgc.consumer = [
1    2    30    1     1
2    3    40    1     1
3    4    20    1     1
4    3    30    1     1
5    4    10    1     1
];


%% prices
%column_names% priroity price
mgc.consumer_prices = [
   3   -3
   4   -4
   5   -5
   2.5 -2.5
   3   -3
];

%% prices
%column_names% price
mgc.producer_prices = [
   -1000
];
