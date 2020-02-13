function mgc = status

%% required global data
mgc.gas_specific_gravity = 0.6000;
mgc.specific_heat_capacity_ratio = 1.4000;  % unitless
mgc.temperature = 288.7060;  % K
mgc.compressibility_factor = 1.0000;  % unitless
mgc.units = 'si';

%% optional global data (that was either provided or computed based on required global data)
mgc.sound_speed = 371.6643;  % m/s
mgc.R = 8.3140;  % J/(mol K)
mgc.base_pressure = 8101325;  % Pa
mgc.base_length = 5000.0000;  % m
mgc.is_per_unit = 0;

%% junction data
% id	p_min	p_max	p_nominal	junction_type	status	pipeline_name	edi_id	lat	lon
mgc.junction = [
0	101325.0000	8101325.0000	101325.0000	0	1	'status'	0	0.0000	0.0000
1	3101325.0000	8101325.0000	3101325.0000	0	1	'status'	1	0.0000	0.0000
2	3101325.0000	8101325.0000	3101325.0000	0	1	'status'	2	0.0000	0.0000
3	101325.0000	8101325.0000	101325.0000	0	1	'status'	3	0.0000	0.0000
4	101325.0000	8101325.0000	101325.0000	0	1	'status'	4	0.0000	0.0000
5	3101325.0000	8101325.0000	3101325.0000	0	1	'status'	5	0.0000	0.0000
6	101325.0000	8101325.0000	101325.0000	0	1	'status'	6	0.0000	0.0000
7	101325.0000	8101325.0000	101325.0000	0	1	'status'	7	0.0000	0.0000
8	101325.0000	8101325.0000	101325.0000	0	1	'status'	8	0.0000	0.0000
9	101325.0000	8101325.0000	101325.0000	0	1	'status'	9	0.0000	0.0000
10	101325.0000	8101325.0000	101325.0000	0	1	'status'	10	0.0000	0.0000
11	101325.0000	8101325.0000	101325.0000	0	1	'status'	11	0.0000	0.0000
12	101325.0000	8101325.0000	101325.0000	0	1	'status'	12	0.0000	0.0000
13	3101325.0000	8101325.0000	3101325.0000	0	1	'status'	13	0.0000	0.0000
14	101325.0000	8101325.0000	101325.0000	0	1	'status'	14	0.0000	0.0000
15	101325.0000	8101325.0000	101325.0000	0	1	'status'	15	0.0000	0.0000
16	101325.0000	8101325.0000	101325.0000	0	1	'status'	16	0.0000	0.0000
17	101325.0000	8101325.0000	101325.0000	0	1	'status'	17	0.0000	0.0000
18	101325.0000	8101325.0000	101325.0000	0	1	'status'	18	0.0000	0.0000
19	101325.0000	8101325.0000	101325.0000	0	1	'status'	19	0.0000	0.0000
20	101325.0000	8101325.0000	101325.0000	0	1	'status'	20	0.0000	0.0000
21	3101325.0000	8101325.0000	3101325.0000	0	1	'status'	21	0.0000	0.0000
22	101325.0000	8101325.0000	101325.0000	0	1	'status'	22	0.0000	0.0000
23	101325.0000	8101325.0000	101325.0000	0	1	'status'	23	0.0000	0.0000
24	101325.0000	8101325.0000	101325.0000	0	1	'status'	24	0.0000	0.0000
25	101325.0000	8101325.0000	101325.0000	0	1	'status'	25	0.0000	0.0000
26	101325.0000	8101325.0000	101325.0000	0	1	'status'	26	0.0000	0.0000
27	101325.0000	7101325.0000	101325.0000	0	1	'status'	27	0.0000	0.0000
28	101325.0000	8101325.0000	101325.0000	0	1	'status'	28	0.0000	0.0000
29	101325.0000	8101325.0000	101325.0000	0	1	'status'	29	0.0000	0.0000
30	101325.0000	8101325.0000	101325.0000	0	1	'status'	30	0.0000	0.0000
31	101325.0000	8101325.0000	101325.0000	0	1	'status'	31	0.0000	0.0000
32	101325.0000	7101325.0000	101325.0000	0	1	'status'	32	0.0000	0.0000
33	101325.0000	7101325.0000	101325.0000	0	1	'status'	33	0.0000	0.0000
34	101325.0000	8101325.0000	101325.0000	0	1	'status'	34	0.0000	0.0000
35	101325.0000	7101325.0000	101325.0000	0	1	'status'	35	0.0000	0.0000
36	101325.0000	8101325.0000	101325.0000	0	1	'status'	36	0.0000	0.0000
37	3101325.0000	8101325.0000	3101325.0000	0	1	'status'	37	0.0000	0.0000
38	101325.0000	7101325.0000	101325.0000	0	1	'status'	38	0.0000	0.0000
39	101325.0000	7101325.0000	101325.0000	0	1	'status'	39	0.0000	0.0000
100021	101325.0000	8101325.0000	101325.0000	0	1	'status'	100021	0.0000	0.0000
200002	101325.0000	8101325.0000	101325.0000	0	1	'status'	200002	0.0000	0.0000
300001	101325.0000	8101325.0000	101325.0000	0	1	'status'	300001	0.0000	0.0000
400037	101325.0000	8101325.0000	101325.0000	0	1	'status'	400037	0.0000	0.0000
500005	101325.0000	8101325.0000	101325.0000	0	1	'status'	500005	0.0000	0.0000
600013	101325.0000	8101325.0000	101325.0000	0	1	'status'	600013	0.0000	0.0000
];

%% pipe data
% id	fr_junction	to_junction	diameter	length	friction_factor	p_min	p_max	status
mgc.pipe = [
0	0	5	1.0000	13071.0852	0.0069	101325.0000	8101325.0000	1
1	32	18	0.8000	76893.5508	0.0072	101325.0000	8101325.0000	1
2	37	15	1.0000	21557.5662	0.0069	101325.0000	8101325.0000	1
3	15	16	1.0000	6998.0538	0.0069	101325.0000	8101325.0000	1
4	16	12	0.8000	58218.9696	0.0072	101325.0000	8101325.0000	1
5	27	28	0.8000	86690.2656	0.0072	101325.0000	8101325.0000	1
6	28	11	0.6000	16579.3260	0.0076	101325.0000	8101325.0000	1
7	11	20	0.6000	10022.7830	0.0076	101325.0000	8101325.0000	1
8	28	6	0.6000	35218.8391	0.0076	101325.0000	8101325.0000	1
9	6	22	0.6000	20322.2054	0.0076	101325.0000	8101325.0000	1
10	20	8	0.8000	32868.2025	0.0072	101325.0000	8101325.0000	1
11	27	39	0.8000	47488.2838	0.0072	101325.0000	7101325.0000	1
12	8	9	0.6000	3802.5867	0.0076	101325.0000	8101325.0000	1
13	8	24	0.8000	39036.0418	0.0072	101325.0000	8101325.0000	1
14	9	26	0.4000	38659.8244	0.0082	101325.0000	8101325.0000	1
15	24	3	0.6000	18017.8496	0.0076	101325.0000	8101325.0000	1
16	26	23	0.6000	3067.5474	0.0076	101325.0000	8101325.0000	1
17	23	14	0.4000	12015.8748	0.0082	101325.0000	8101325.0000	1
18	9	7	0.4000	14043.1135	0.0082	101325.0000	8101325.0000	1
19	7	19	0.6000	20634.6983	0.0076	101325.0000	8101325.0000	1
20	19	6	0.6000	10586.1295	0.0076	101325.0000	8101325.0000	1
21	19	10	0.6000	10452.0312	0.0076	101325.0000	8101325.0000	1
22	5	25	0.8000	12397.3522	0.0072	101325.0000	8101325.0000	1
23	10	22	0.6000	19303.1920	0.0076	101325.0000	8101325.0000	1
24	27	22	0.6000	66036.5946	0.0076	101325.0000	8101325.0000	1
25	27	17	1.0000	18969.4127	0.0069	101325.0000	8101325.0000	1
26	17	31	0.8000	36061.0099	0.0072	101325.0000	8101325.0000	1
27	31	30	0.8000	22224.1532	0.0072	101325.0000	8101325.0000	1
28	31	4	0.8000	31179.6191	0.0072	101325.0000	8101325.0000	1
29	4	17	1.0000	12766.7034	0.0069	101325.0000	8101325.0000	1
30	31	38	0.8000	32921.2598	0.0072	101325.0000	8101325.0000	1
31	35	21	0.8000	49866.1484	0.0072	101325.0000	8101325.0000	1
32	21	34	0.8000	3479.4547	0.0072	101325.0000	8101325.0000	1
33	35	36	1.0000	3418.0083	0.0069	101325.0000	8101325.0000	1
34	29	36	1.0000	32449.3721	0.0069	101325.0000	8101325.0000	1
35	29	21	0.8000	26427.4817	0.0072	101325.0000	8101325.0000	1
36	12	13	1.0000	18136.5973	0.0069	101325.0000	8101325.0000	1
37	12	33	0.8000	65057.1743	0.0072	101325.0000	8101325.0000	1
38	12	34	0.8000	65532.2127	0.0072	101325.0000	8101325.0000	1
];

%% compressor data
% id	fr_junction	to_junction	c_ratio_min	c_ratio_max	power_max	flow_min	flow_max	inlet_p_min	inlet_p_max	outlet_p_min	outlet_p_max	status	operating_cost	directionality
mgc.compressor = [
39	37	400037	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
40	13	600013	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
41	21	100021	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
42	2	200002	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
43	1	300001	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
44	5	500005	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
100000	33	100021	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
100001	35	200002	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
100002	38	300001	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
100003	27	400037	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
100004	39	500005	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
100005	32	600013	1.0000	5.0000	1000000000.0000	0.0000	627314814814.8101	101325.0000	8101325.0000	101325.0000	8101325.0000	1	10.0000	2
];

%% receipt data
% id	junction_id	injection_min	injection_max	injection_nominal	is_dispatchable	status
mgc.receipt = [
0	0	201.3889	201.3889	201.3889	0	1
1	1	201.3889	201.3889	201.3889	0	1
2	2	201.3889	201.3889	201.3889	0	1
10001	1	0.0000	11.5741	0.0000	1	1
10002	2	0.0000	11.5741	0.0000	1	1
];

%% delivery data
% id	junction_id	withdrawal_min	withdrawal_max	withdrawal_nominal	is_dispatchable	status
mgc.delivery = [
3	3	0.0000	20.8333	20.8333	0	1
4	4	0.0000	20.8333	20.8333	0	1
5	5	0.0000	20.8333	20.8333	0	1
6	6	0.0000	20.8333	20.8333	0	1
7	7	0.0000	20.8333	20.8333	0	1
8	8	0.0000	20.8333	20.8333	0	1
9	9	0.0000	20.8333	20.8333	0	1
10	10	0.0000	20.8333	20.8333	0	1
11	11	0.0000	20.8333	20.8333	0	1
12	12	0.0000	20.8333	20.8333	0	1
13	13	0.0000	20.8333	20.8333	0	1
14	14	0.0000	20.8333	20.8333	0	1
15	15	0.0000	20.8333	20.8333	0	1
16	16	0.0000	20.8333	20.8333	0	1
17	17	0.0000	20.8333	20.8333	0	1
18	18	0.0000	20.8333	20.8333	0	1
19	19	0.0000	20.8333	20.8333	0	1
20	20	0.0000	20.8333	20.8333	0	1
21	21	0.0000	20.8333	20.8333	0	1
22	22	0.0000	20.8333	20.8333	0	1
23	23	0.0000	20.8333	20.8333	0	1
24	24	0.0000	20.8333	20.8333	0	1
25	25	0.0000	20.8333	20.8333	0	1
26	26	0.0000	20.8333	20.8333	0	1
27	27	0.0000	20.8333	20.8333	0	1
28	28	0.0000	20.8333	20.8333	0	1
29	29	0.0000	20.8333	20.8333	0	1
30	30	0.0000	20.8333	20.8333	0	1
31	31	0.0000	20.8333	20.8333	0	1
10004	4	0.0000	11.5741	11.5741	1	1
10024	24	0.0000	11.5741	11.5741	1	1
10029	29	0.0000	11.5741	11.5741	1	1
];

end
