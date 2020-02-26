function mgc = warnings

%% required global data
mgc.gas_specific_gravity = 0.6000;
mgc.specific_heat_capacity_ratio = 1.4000;  % unitless
mgc.temperature = 288.7060;  % K
mgc.compressibility_factor = 1.0000;  % unitless
mgc.units = 'si';

%% optional global data (that was either provided or computed based on required global data)
mgc.sound_speed = 371.6643;  % m/s
mgc.R = 8.3140;  % J/(mol K)
mgc.base_pressure = 1000000;  % Pa
mgc.base_length = 5000.0000;  % m
mgc.is_per_unit = 0;

%% junction data
% id	p_min	p_max	p_nominal	junction_type	status	pipeline_name	edi_id	lat	lon
mgc.junction = [
1	3000000.0000	6000000.0000	3000000.0000	1	1	'warnings'	1	0.0000	0.0000
2	3000000.0000	6000000.0000	3000000.0000	0	1	'warnings'	2	0.0000	0.0000
3	3000000.0000	6000000.0000	3000000.0000	0	1	'warnings'	3	0.0000	0.0000
4	3000000.0000	6000000.0000	3000000.0000	0	1	'warnings'	4	0.0000	0.0000
5	3000000.0000	6000000.0000	3000000.0000	0	1	'warnings'	5	0.0000	0.0000
6	3000000.0000	6000000.0000	3000000.0000	0	1	'warnings'	6	0.0000	0.0000
];

%% pipe data
% id	fr_junction	to_junction	diameter	length	friction_factor	p_min	p_max	status
mgc.pipe = [
1	5	2	0.6000	50000.0000	0.0100	3000000.0000	6000000.0000	1
2	2	3	0.6000	80000.0000	0.0100	3000000.0000	6000000.0000	1
3	6	4	0.6000	80000.0000	0.0100	3000000.0000	6000000.0000	1
4	3	4	0.3000	80000.0000	0.0100	3000000.0000	6000000.0000	1
];

%% compressor data
% id	fr_junction	to_junction	c_ratio_min	c_ratio_max	power_max	flow_min	flow_max	inlet_p_min	inlet_p_max	outlet_p_min	outlet_p_max	status	operating_cost	directionality
mgc.compressor = [
1	1	5	0.5000	2.5000	100000000.0000	0.0000	70000000.0000	3000000.0000	6000000.0000	3000000.0000	6000000.0000	1	10.0000	2
2	2	6	0.5000	2.5000	100000000.0000	0.0000	70000000.0000	3000000.0000	6000000.0000	3000000.0000	6000000.0000	1	10.0000	2
];

%% receipt data
% id	junction_id	injection_min	injection_max	injection_nominal	is_dispatchable	status
mgc.receipt = [
6	1	0.0000	1000.0000	500.0000	1	1
];

%% delivery data
% id	junction_id	withdrawal_min	withdrawal_max	withdrawal_nominal	is_dispatchable	status
mgc.delivery = [
1	2	0.0000	30.0000	30.0000	1	1
2	3	0.0000	40.0000	40.0000	1	1
3	4	0.0000	20.0000	20.0000	1	1
4	3	0.0000	30.0000	30.0000	1	1
5	4	0.0000	10.0000	10.0000	1	1
];

end
