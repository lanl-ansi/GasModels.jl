# Matgas Format (.m)

Here we detail the parameters that can be inputted using the matgas format. They can be inputted in the order they appear here, or selectively, in the case where some data is not required, by using the following header format.

```matlab
%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon
```

See case files in `test/data/matgas` or `examples/data/matgas` for examples of file syntax.

## Junctions (mgc.junction)

These components model “point” locations in the system, i.e. locations of withdrawal or injection, or simply connection points between pipes. Each junction may have multiple pipes attached.

| Variable      | Type    | Name             | Standard Units (SI) | United States Customary Units | Required           | Description                                                                                                                                      |
| ------------- | ------- | ---------------- | ------------------- | ----------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| id            | Int     | Junction id      |                     |                               | Y | Unique id for junctions                                                                                                                          |
| p_min         | Float64 | Pressure Minimum | Pascal              | PSI                           | Y | Optimization constraint                                                                                                                          |
| p_max         | Float64 | Pressure Maximum | Pascal              | PSI                           | Y | Maximum operating pressure (MOP, psig) used in line pack calculations, which is lower than the maximum allowable operating pressure (MAOP, psig) |
| p_nominal     | Float64 | Pressure         | Pascal              | PSI                           | Y | Nominal pressure, can have a default that lies between the pressure min/max                                                                      |
| junction_type | Int     | Junction Type    |                     |                               | Y | Classification of the junction: 0 = standard node, 1 = slack node                                                                                |
| status        | Int     | Junction Status  |                     |                               | Y | Determines if the component is active in the model                                                                                               |
| pipeline_name | String  | Pipeline Name    |                     |                               |                    | Name of the pipeline to which this junction belongs                                                                                              |
| edi_id        | String  | EDI ID           |                     |                               |                    | EDI ID if applicable, to enabled easy input of near-real-time EDI data                                                                           |
| lat           | Float64 | Latitude         | Decimal degrees     | Decimal degrees               |                    | Latitude of the junction                                                                                                                         |
| lon           | Float64 | Longitude        | Decimal degrees     | Decimal degrees               |                    | Longitude of the junction                                                                                                                        |

## Pipes (mgc.pipe)

These components model pipelines which connect two junctions.

| Variable                          | Type    | Name              | Standard Units (SI) | United States Customary Units | Required           | Description                                                                                                                             |
| --------------------------------- | ------- | ----------------- | ------------------- | ----------------------------- | ------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| id                                | Int     | Pipe id           |                     |                               | Y | Unique id for pipes                                                                                                                     |
| fr_junction                       | Int     | From Junction id  |                     |                               | Y | Unique id of the junction on the from side                                                                                              |
| to_junction                       | Int     | To Junction id    |                     |                               | Y | Unique id of the junction on the to side                                                                                                |
| diameter                          | Float64 | Diameter          | Meters              | Inches                        | Y | Pipe diameter                                                                                                                           |
| length                            | Float64 | Length            | Meters              | Miles                         | Y | Pipe Length                                                                                                                             |
| friction_factor                   | Float64 | Friction Factor   |                     |                               | Y | parameter based on the relative roughness of the pipe and Reynolds Number                                                               |
| p_min                             | Float64 | Pressure Minimum  | Pascal              | PSI                           | Y | Float value link minimum pressure used as optimization constraint, typically set equal to 14.7 psia, which is equivalent to 1.01325 bar |
| p_max                             | Float64 | Pressure Maximum  | Pascal              | PSI                           | Y | Maximum allowable operating pressure (MAOP,psig) for a given pipeline segment                                                           |
| status                            | Int     | Pipe status       |                     |                               | Y | Determines if the component is active in the model                                                                                      |
| is_bidirectional                  | Int     | Bi-directionality |                     |                               |                    | Specifies whether the pipe supports bi-directional flow                                                                                 |
| pipeline_name                     | String  | Pipeline Name     |                     |                               |                    | Name of the pipeline to which this pipe belongs                                                                                         |
| num\_spatial\_discretization_points | Int     | Space points      |                     |                               |                    | Number of spatial discretization points in the pipe, used for Transient calculations                                                    |

## Compressors (mgc.compressor)

These components model infrastructure used to boost pressure between two nodes.

| Variable                       | Type    | Name                             | Standard Units (SI) | United States Customary Units | Required           | Description                                                                                                                                                                                                                                             |
| ------------------------------ | ------- | -------------------------------- | ------------------- | ----------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                             | Int     | Compressor id                    |                     |                               | Y | Unique id for compressor                                                                                                                                                                                                                                |
| fr_junction                    | Int     | From Junction id                 |                     |                               | Y | Unique id of the junction on the from side                                                                                                                                                                                                              |
| to_junction                    | Int     | To Junction id                   |                     |                               | Y | Unique id of the junction on the to side                                                                                                                                                                                                                |
| c\_ratio\_min                    | Float64 | Minimum compression ratio        |                     |                               | Y | Minimum compression ratio                                                                                                                                                                                                                               |
| c\_ratio\_max                    | Float64 | Maximum compression ratio        |                     |                               | Y | Maximum compression ratio                                                                                                                                                                                                                               |
| power_max                      | Float64 | Maximum power                    | W                   | HP                            | Y | Float value compressor max power, used as optimization constraint                                                                                                                                                                                       |
| flow_min                       | Float64 | Minimum mass flow                | kg/s                |                               | Y | Minimum mass flow                                                                                                                                                                                                                                       |
| flow_max                       | Float64 | Maximum mass flow                | kg/s                |                               | Y | Maximum mass flow                                                                                                                                                                                                                                       |
| inlet\_p\_min                    | Float64 | Minimum inlet pressure           | Pascal              | PSI                           | Y | Minimum pressure at compressor inlet                                                                                                                                                                                                                    |
| inlet\_p\_max                    | Float64 | Maximum inlet pressure           | Pascal              | PSI                           | Y | Maximum pressure at compressor inlet                                                                                                                                                                                                                    |
| outlet\_p\_min                   | Float64 | Minimum outlet pressure          | Pascal              | PSI                           | Y | Minimum pressure at compressor outlet                                                                                                                                                                                                                   |
| outlet\_p\_max                   | Float64 | Maximum outlet pressure          | Pascal              | PSI                           | Y | Maximum pressure at compressor outlet                                                                                                                                                                                                                   |
| status                         | Int     | Compressor status                |                     |                               | Y | Determines if the component is active in the model                                                                                                                                                                                                      |
| operating_cost                 | Float64 | Operating cost                   | $/W                 | $/kW                          |                    | Cost to operate compressor                                                                                                                                                                                                                              |
| directionality                 | Int     | Directionality                   |                     |                               |                    | An integer value that denotes the directionality of compression and flow: 0 = bi-directional compressor, 1 = unidirectional compressor with no reversal for flow allowed, 2 = unidirectional compressor which allows for uncompressed reversal of flows |
| compressor_station_name        | String  | Compressor Station Name          |                     |                               |                    | Name of compressor stations                                                                                                                                                                                                                             |
| pipeline_name                  | String  | Pipeline name                    |                     |                               |                    | Name of Pipeline                                                                                                                                                                                                                                        |
| total\_installed\_power          | Float64 | Total installed power            | W                   | W                             |                    | Total installed horsepower – same as maximum power                                                                                                                                                                                                      |
| num\_compressor\_units           | Int     | Number of compressor units       |                     |                               |                    | Number of compressor units – needed to account for number of gas-fired compressors versus those driven by electric power                                                                                                                                |
| compressor_type                | String  | Compressor Type                  |                     |                               |                    | Compressor type (reciprocal versus turbine) – used to determine compressor efficiency                                                                                                                                                                   |
| design\_suction\_pressure        | Float64 | Design Suction Pressure          | Pascal              | PSI                           |                    | Used to estimate compressor max pressure delta                                                                                                                                                                                                          |
| design\_discharge\_pressure      | Float64 | Design discharge pressure        | Pascal              | PSI                           |                    | Used to determine maximum extent of line pack for downstream pipeline segments                                                                                                                                                                          |
| max\_compressed\_volume          | Float64 | Maximum compressed volume        |                     |                               |                    | Maximum volume compressed at design conditions                                                                                                                                                                                                          |
| design\_fuel\_required           | Float64 | Design fuel required             |                     | MMSCFD                        |                    | Fuel required at design conditions                                                                                                                                                                                                                      |
| design\_electric\_power\_required | Float64 | Design electric power required   |                     | kWh/day                       |                    | Electric power required at design conditions – determines which compressor stations could be affected by an electric outage                                                                                                                             |
| num\_units\_for\_peak\_service     | Int     | Number of units for peak service |                     |                               |                    | Number of units in service during peak conditions                                                                                                                                                                                                       |
| peak_year                      | Int     | Peak year                        |                     |                               |                    | Year of peak conditions                                                                                                                                                                                                                                 |

## Short Pipes (mgc.short_pipe)

These components model, e.g., handling complicated contract situations at single entry points; they are modeled to have zero resistance.

| Variable         | Type   | Name              | Standard Units (SI) | United States Customary Units | Required           | Description                                             |
| ---------------- | ------ | ----------------- | ------------------- | ----------------------------- | ------------------ | ------------------------------------------------------- |
| id               | Int    | Short pipe id     |                     |                               | Y | Unique id for short pipe                                |
| fr_junction      | Int    | From Junction id  |                     |                               | Y | Unique id of the junction on the from side              |
| to_junction      | Int    | To Junction id    |                     |                               | Y | Unique id of the junction on the to side                |
| status           | Int    | Short Pipe status |                     |                               | Y | Determines if the component is active in the model      |
| is_bidirectional | Int    | Bi-directionality |                     |                               |                    | Specifies whether the pipe supports bi-directional flow |
| pipeline_name    | String | Pipeline Name     |                     |                               |                    | Name of the pipeline to which this pipe belongs         |

## Resistors (mgc.resistor)

These components model pressure drops for which no other data or models are available.

| Variable         | Type    | Name              | Standard Units (SI) | United States Customary Units | Required           | Description                                              |
| ---------------- | ------- | ----------------- | ------------------- | ----------------------------- | ------------------ | -------------------------------------------------------- |
| id               | Int     | Resistor id       |                     |                               | Y | Unique id for resistor                                   |
| fr_junction      | Int     | From Junction id  |                     |                               | Y | Unique id of the junction on the from side               |
| to_junction      | Int     | To Junction id    |                     |                               | Y | Unique id of the junction on the to side                 |
| drag             | Float64 | Drag factor       |                     |                               | Y | the drag factor of the resistors - non dimensional value |
| status           | Int     | Resistor status   |                     |                               | Y | Determines if the component is active in the model       |
| is_bidirectional | Int     | Bi-directionality |                     |                               |                    | Specifies whether the pipe supports bi-directional flow  |
| pipeline_name    | String  | Pipeline Name     |                     |                               |                    | Name of the pipeline to which this pipe belongs          |

## Loss Resistors (mgc.loss_resistor)

These components model constant pressure drops along edges.

| Variable         | Type    | Name              | Standard Units (SI) | United States Customary Units | Required           | Description                                              |
| ---------------- | ------- | ----------------- | ------------------- | ----------------------------- | ------------------ | -------------------------------------------------------- |
| id               | Int     | Loss resistor id       |                     |                               | Y | Unique id for resistor                                   |
| fr_junction      | Int     | From Junction id  |                     |                               | Y | Unique id of the junction on the from side               |
| to_junction      | Int     | To Junction id    |                     |                               | Y | Unique id of the junction on the to side                 |
| p_loss           | Float64 | Pressure loss     | Pascal              | PSI                           | Y | Constant pressure loss across the loss resistor |
| status           | Int     | Loss resistor status   |                     |                               | Y | Determines if the component is active in the model       |

## Regulators (mgc.regulator)

These components model pressure reducing valves.

| Variable               | Type    | Name                     | Standard Units (SI) | United States Customary Units | Required           | Description                                        |
| ---------------------- | ------- | ------------------------ | ------------------- | ----------------------------- | ------------------ | -------------------------------------------------- |
| id                     | Int     | Regulator id             |                     |                               | Y | Unique id for regulator                            |
| fr_junction            | Int     | From Junction id         |                     |                               | Y | Unique id of the junction on the from side         |
| to_junction            | Int     | To Junction id           |                     |                               | Y | Unique id of the junction on the to side           |
| \_factor\_min   | Float64 | Minimum reduction factor |                     |                               | Y | This value is necessarily < 1                      |
| reduction\_factor\_max   | Float64 | Maximum reduction factor |                     |                               | Y | Default value = 1, but can be < 1                  |
| flow_min               | Float64 | Minimum flow             | kg/s                | MMSCFD                        | Y | Minimum flow through the regulator                 |
| flow_max               | Float64 | Maximum flow             | kg/s                | MMSCFD                        | Y | Maximum flow through the regulator                 |
| status                 | Int     | Regulator status         |                     |                               | Y | Determines if the component is active in the model |
| discharge_coefficient  | Float64 | Discharge coefficient    |                     |                               | Y | More commonly known as the "flow coefficient Kv"   |
| design\_flow\_rate       | Float64 | kg/s                     | MMSCFD              |                               |                    | Maximum design flow                                |
| design\_inlet\_pressure  | Float64 | Pascal                   | PSI                 |                               |                    | Pressure upstream of the regulator                 |
| design\_outlet\_pressure | Float64 | Pascal                   | PSI                 |                               |                    | Pressure downstream of the regulator               |
| pipeline_name          | String  | Pipeline Name            |                     |                               |                    | Name of the pipeline to which this pipe belongs    |

## Valves (mgc.valve)

These model components which close off flow between two points in a natural gas network.

| Variable         | Type    | Name             | Standard Units (SI) | United States Customary Units | Required           | Description                                                                                                             |
| ---------------- | ------- | ---------------- | ------------------- | ----------------------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| id               | Int     | Valve id         |                     |                               | Y | Unique id for valve                                                                                                     |
| fr_junction      | Int     | From Junction id |                     |                               | Y | Unique id of the junction on the from side                                                                              |
| to_junction      | Int     | To Junction id   |                     |                               | Y | Unique id of the junction on the to side                                                                                |
| status           | Int     | Valve status     |                     |                               | Y | Determines if the component is active in the model                                                                      |
| flow_coefficient | Float64 | Flow Coefficient |                     |                               | Y | Coefficient of flow (Cv) – used to determine a valve’s flow under various conditions (e.g., potentially partially open) |
| pipeline_name    | String  | Pipeline Name    |                     |                               |                    | Name of the pipeline to which this pipe belongs                                                                         |

## Transfers (mgc.transfer)

These components model interconnects, i.e. points in the network that can act both as a receipt point or delivery point at different times of the day (redundant for steady-state). In practice, a transfer could be modeled as a receipt point and a delivery point, however, modeling it as a transfer allows for explicitly stating that a boundary condition can act as either an injection or consumption--but not both.

| Variable             | Type    | Name                 | Standard Units (SI) | United States Customary Units | Required           | Description                                                                                                                                                                                                         |
| -------------------- | ------- | -------------------- | ------------------- | ----------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                   | Int     | Transfer id          |                     |                               | Y | Unique id for transfer                                                                                                                                                                                              |
| junction_id          | Int     | Junction id          |                     |                               | Y | Unique id of Junction to which component is connected                                                                                                                                                               |
| withdrawal_min       | Float64 | Minimum Withdrawal   | kg/s                | MMSCFD                        | Y | This number can be negative, in which case it means that the transfer point is injecting gas into the system                                                                                                        |
| withdrawal_max       | Float64 | Maximum Withdrawal   | kg/s                | MMSCFD                        | Y | this variable can depend on flow direction                                                                                                                                                                          |
| withdrawal_nominal   | Float64 | Nominal Withdrawal   | kg/s                | MMSCFD                        | Y | Can have a default of 0.0                                                                                                                                                                                           |
| is_dispatchable      | Int     | Dispatchable         |                     |                               | Y | If the component is marked as dispatchable, it means that it can vary its withdrawal between its minimum and maximum. If not, then the component is injecting or withdrawing exactly at the nominal withdrawal rate |
| status               | Int     | Transfer status      |                     |                               | Y | Determines if the component is active in the model                                                                                                                                                                  |
| bid_price            | Float64 | Bid Price            | $/kg                | $/vol                         |                    | Bid price                                                                                                                                                                                                           |
| offer_price          | Float64 | Offer Price          | $/kg                | $/vol                         |                    | Offer price                                                                                                                                                                                                         |
| exchange\_point\_name  | String  | Exchange Point Name  |                     |                               |                    | Name of Exchange point                                                                                                                                                                                              |
| pipeline_name        | String  | Pipeline Name        |                     |                               |                    | Name of pipeline to which the transfer belongs                                                                                                                                                                      |
| other\_pipeline\_name  | String  | Other Pipeline Name  |                     |                               |                    | Name of pipeline to which the transfer connects                                                                                                                                                                     |
| design_pressure      | Float64 | Design pressure      |                     | PSI                           |                    | Maximum designed pressure                                                                                                                                                                                           |
| meter_capacity       | Float64 | Meter Capacity       |                     | MMSCFD                        |                    | Provided by real-time data collection (EDI), model constraint                                                                                                                                                       |
| daily\_scheduled\_flow | Float64 | Daily scheduled flow |                     | MMSCFD                        |                    | Provided by near-real-time data collection (EDI)                                                                                                                                                                    |

## Receipts (mgc.receipt)

These components model consumers of natural gas.

| Variable             | Type    | Name                  | Standard Units (SI) | United States Customary Units | Required           | Description                                                                                                                                                                                        |
| -------------------- | ------- | --------------------- | ------------------- | ----------------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                   | Int     | Receipt id            |                     |                               | Y | Unique id for receipt                                                                                                                                                                              |
| junction_id          | Int     | Junction id           |                     |                               | Y | Unique id of Junction to which component is connected                                                                                                                                              |
| injection_min        | Float64 | Minimum Injection     | kg/s                | MMSCFD                        | Y | Minimum amount of gas that can be injected                                                                                                                                                         |
| injection_max        | Float64 | Maximum Injection     | kg/s                | MMSCFD                        | Y | Maximum amount of gas that can be injected                                                                                                                                                         |
| injection_nominal    | Float64 | Nominal Injection     | kg/s                | MMSCFD                        | Y | Nominal gas injection                                                                                                                                                                              |
| is_dispatchable      | Int     | Dispatchable          |                     |                               | Y | If the component is marked as dispatchable, it means that it can vary its injection between its minimum and maximum. If not, then the component is injecting exactly at the nominal injection rate |
| status               | Int     | Receipt status        |                     |                               | Y | Determines if the component is active in the model                                                                                                                                                 |
| offer_price          | Float64 | Offer Price           | $/W                 | $/vol                         |                    | Offer price                                                                                                                                                                                        |
| name                 | String  | Receipt Name          |                     |                               |                    | Name of receipt point                                                                                                                                                                              |
| company_name         | String  | Company Name          |                     |                               |                    | Name of company that owns receipt point                                                                                                                                                            |
| daily\_scheduled\_flow | Float64 | Daily Scheduled Flow  |                     | MMSCFD                        |                    | Provided by real-time data collection (EDI), model constraint                                                                                                                                      |
| design_capacity      | Float64 | Design Capacity       |                     | MMSCFD                        |                    | Provided by real-time data collection (EDI), model constraint                                                                                                                                      |
| operating_capacity   | Float64 | Operating Capacity    |                     | MMSCFD                        |                    | Provided by real-time data collection (EDI), model constraint                                                                                                                                      |
| is_firm              | Int     | Interruptable vs Firm |                     |                               |                    | Identifies the order by which the receipt flow could be curtailed (interruptible first, then firm)                                                                                                 |
| edi_id               | Int     | EDI ID                |                     |                               |                    | Unique ID to allow easy input of near-real-time EDI data                                                                                                                                           |

## Deliveries (mgc.delivery)

These components model producers (providers) of natural gas.

| Variable             | Type    | Name                  | Standard Units (SI) | United States Customary Units | Required           | Description                                                                                                                                                                                        |
| -------------------- | ------- | --------------------- | ------------------- | ----------------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| id                   | Int     | Delivery id           |                     |                               | Y | Unique id for delivery                                                                                                                                                                             |
| junction_id          | Int     | Junction id           |                     |                               | Y | Unique id of Junction to which component is connected                                                                                                                                              |
| withdrawal_min       | Float64 | Minimum withdrawal    | kg/s                | MMSCFD                        | Y | Minimum amount of gas that can be withdrawn                                                                                                                                                        |
| withdrawal_max       | Float64 | Maximum withdrawal    | kg/s                | MMSCFD                        | Y | Maximum amount of gas that can be withdrawn                                                                                                                                                        |
| withdrawal_nominal   | Float64 | Nominal withdrawal    | kg/s                | MMSCFD                        | Y | Nominal gas withdrawal                                                                                                                                                                             |
| is_dispatchable      | Int     | Dispatchable          |                     |                               | Y | If the component is marked as dispatchable, it means that it can vary its injection between its minimum and maximum. If not, then the component is injecting exactly at the nominal injection rate |
| status               | Int     | Delivery status       |                     |                               | Y | Determines if the component is active in the model                                                                                                                                                 |
| bid_price            | Float64 | Bid Price             | $/W                 | $/vol                         |                    | Bid price                                                                                                                                                                                          |
| name                 | String  | Delivery Name         |                     |                               |                    | Name of delivery point                                                                                                                                                                             |
| company_name         | String  | Company Name          |                     |                               |                    | Name of company that owns delivery point                                                                                                                                                           |
| daily\_scheduled\_flow | Float64 | Daily Scheduled Flow  |                     | MMSCFD                        |                    | Provided by real-time data collection (EDI), model constraint                                                                                                                                      |
| design_capacity      | Float64 | Design Capacity       |                     | MMSCFD                        |                    | Provided by real-time data collection (EDI), model constraint                                                                                                                                      |
| operating_capacity   | Float64 | Operating Capacity    |                     | MMSCFD                        |                    | Provided by real-time data collection (EDI), model constraint                                                                                                                                      |
| is_firm              | Int     | Interruptable vs Firm |                     |                               |                    | Identifies the order by which the d flow could be curtailed (interruptible first, then firm)                                                                                                       |
| edi_id               | Int     | EDI ID                |                     |                               |                    | Unique ID to allow easy input of near-real-time EDI data                                                                                                                                           |

## Storage (mgc.storage)

These components are used to model locations which can store and release natural gas.

| Variable                 | Type    | Name                     | Standard Units (SI) | United States Customary Units | Required           | Description                                                     |
| ------------------------ | ------- | ------------------------ | ------------------- | ----------------------------- | ------------------ | --------------------------------------------------------------- |
| id                       | Int     | Storage id               |                     |                               | Y | Unique id for storage                                           |
| junction_id              | Int     | Junction id              |                     |                               | Y | Unique id of Junction to which component is connected           |
| pressure_nominal         | Float64 | Nominal pressure         | Pascal              | PSI                           | Y | pressure at the storage                                         |
| flow\_injection\_rate\_min  | Float64 | Minimum injection rate   | kg/s                | MMSCFD                        | Y | Minimum flow injection rate                                     |
| flow\_injection\_rate\_max  | Float64 | Maximum injection rate   | kg/s                | MMSCFD                        | Y | Maximum flow injection rate                                     |
| flow\_withdrawal\_rate\_min | Float64 | Minimum withdrawal rate  | kg/s                | MMSCFD                        | Y | Minimum flow withdrawal rate                                    |
| flow\_withdrawal\_rate\_max | Float64 | Maximum withdrawal rate  | kg/s                | MMSCFD                        | Y | Maximum flow withdrawal rate                                    |
| capacity                 | Float64 | Capacity                 | kg                  | MMSCF                         | Y | Capacity of the storage                                         |
| status                   | Int     | Storage status           |                     |                               | Y | Determines if the component is active in the model              |
| name                     | String  | Storage Name             |                     |                               |                    | Name of the Storage point                                       |
| owner_name               | String  | Owner Name               |                     |                               |                    | Name of the Storage point owner                                 |
| storage_type             | String  | Storage type             |                     |                               |                    | Type of storage (aquifer, salt cavern, or depleted oil and gas) |
| daily\_withdrawal\_max     | Float64 | Daily withdrawal rate    | kg/s                | MMSCFD                        |                    | Maximum daily withdrawal                                        |
| seasonal\_withdrawal\_max  | Float64 | Seasonal withdrawal rate | kg/s                | MMSCFD                        |                    | Maximum Seasonal withdrawal                                     |
| base\_gas\_capacity        | Float64 | Base gas capacity        | kg                  | MMSCF                         |                    | Base gas capacity                                               |
| working\_gas\_capacity     | Float64 | Working gas capacity     | kg                  | MMSCF                         |                    | Working gas capacity                                            |
| total\_field\_capacity     | Float64 | Total field capacity     | kg                  | MMSCF                         |                    | Total field gas capacity                                        |
| edi_id                   | Int     | EDI ID                   |                     |                               |                    | Unique ID to allow easy input of near-real-time EDI data        |

## Network Parameters (mgc._parameter_)

| Variable                     | Type    | Name                   | Standard Units (SI) | United States Customary Units | Required | Description                                                        |
| ---------------------------- | ------- | ---------------------- | ------------------- | ----------------------------- | -------- | ------------------------------------------------------------------ |
| gas\_specific\_gravity         | Float64 | Specific Gravity       |                     |                               |          | Gas gravity                                                        |
| specific\_heat\_capacity\_ratio | Float64 | Specific heat capacity |                     |                               |          | specific heat capacity ratio                                       |
| temperature                  | Float64 | Temperature            | K                   |                               |          | temperature of the network                                         |
| sound_speed                  | Float64 | Speed of Sound         | m/s                 |                               |          | speed of sound in gas                                              |
| R                            | Float64 | Universal Gas Constant | J/mol/K             |                               |          | Universal gas constant                                            |
| gas\_molar\_mass               | Float64 | Molar Mass             | kg/mol              |                               |          | Molar Mass                                                         |
| compressibility_factor       | Float64 | Compressibility factor |                     |                               |          | Compressibility factor (unitless)                                  |
| base_pressure                | Float64 | Base Pressure          | Pascal              | PSI                           |          | Base pressure in Pa or psi                                         |
| base_length                  | Float64 | Base Length            | Meters              | Miles                         |          | Base length in m or miles                                          |
| base_time                    | Float64 | Base Time              | Hours               | Hours                         |          | Base time in hr                                                    |
| units                        | String  | Units                  |                     |                               |          | 'si' for standard units or 'usc' for United States customary units |
| is\_per\_unit                  | Int     | Per-unit               |                     |                               |          | If data is already in per-unit (non-dimensionalized                |
| name                         | String  | Case Name              |                     |                               |          | Name of Network Case                                               |
| year                         | Int     | Year                   |                     |                               |          | Year from which data originated                                    |

## Matgas extensions

The matgas format supports extensions which allow users to define arbitrary components and data which are used in customized problems and formulations.  For example, the syntax

```julia
  %column_names% data_field_name1, data_field_name2, ...
  mgc.component_data = [
  data1, data2
  data1, data2
  ...
  ]
```

is used to add data to standard gas components.  In this example, the data dictionary for `component` will be augmented with fields called `data_field_name1`, `data_field_name2`, etc. The names trailing the keyword `%column_name%` are used as the keys in the data dictionary for each `component`. The key word `mgc.component_data` is used to indicate the component the new data should be associated with.  For example, `mgc.pipe_data` adds the data to pipes. The data should be listed in the same order as used by the tables that specify the required data for the component.  The syntax

```julia
  %column_names% data_field_name1, data_field_name2, ...
  mgc.component = [
  data1, data2
  data1, data2
  ...
  ]
```

is then used to specify completely new components which are not specified in the default format.  This example would create an entry from components called `component` in the data dictionary.


# Transient Data Format (CSV)

The transient/time-series data will come in as one .csv file (comma separated format). The first column in the CSV format will be a time stamp in the date-time format YYYY-MM-DDTHH:MM:SS+HH:MM, where the +HH:MM indicates the timezone offset, the second column will be the component type, the third column will be the component id, the forth column will be the parameter name, and the fifth column will be the value of the parameter.  See below example for valid header names.

```csv
timestamp,component_type,component_id,parameter,value
1992-09-12T00:00:00.0+00:00,delivery,1,withdrawal_nominal,0.104678
1992-09-13T00:00:00.0+00:00,delivery,1,withdrawal_nominal,0.540400
1992-09-14T00:00:00.0+00:00,delivery,1,withdrawal_nominal,0.929477
1992-09-15T00:00:00.0+00:00,delivery,1,withdrawal_nominal,0.412720
```
