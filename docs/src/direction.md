# Direction Documentation

The data format allows the user to specify the design criteria associated with direction of flow through an edge.  For example, a pipe can be designed to allow bi directional flow, in which case the flow may travel in either direction through the pipe.  Or, a pipe may be designed for uni directional flow.  In which case, the flow may only travel from the from junction to the to junction.  In certain cases, it may be desirable to specify a direction flow that goes beyond the physical characteristics of an edge. For example, while a pipe may be designed for bi directional flow, a user may find it useful to specify in case that the flow should be in "reverse" direction. For such situations, the key word `flow_direction` has been reserved to allow the user to specify a direction of flow, where `flow_direction=-1` denotes reversal of flow, `flow_direction=0` denotes unspecified direction, and `flow_direction=1` denotes forward flow. The next few tables describes the behavior of `flow_direction` when combined with design criteria for flow.  

## Pipe

| `is_bidirectional` | `flow_direction` | description               |
| ------------------ | ---------------- | ------------------------- |
| 1                  | -1               | reverse flow only         |
| 1                  | 0                | flow in both directions   |
| 1                  | 1                | forward flow only         |
| 0                  | -1               | no flow                   |
| 0                  | 0                | forward flow only         |
| 0                  | 1                | forward flow only         |

## Compressor

| `directionality`   | `flow_direction` | description               |
| ------------------ | ---------------- | ------------------------- |
| 0                  | -1               | reverse flow with compression                                      |
| 0                  | 0                | flow and compression in either directions                          |
| 0                  | 1                | forward flow with compression                                      |
| 1                  | -1               | no flow                                                            |
| 1                  | 0                | forward flow with compression                                      |
| 1                  | 1                | forward flow with compression                                      |
| 2                  | -1               | reverse flow without compression                                   |
| 2                  | 0                | forward flow with compression or reverse flow without compression  |
| 2                  | 1                | forward flow with compression                                      |


## Regulator

| `is_bidirectional` | `flow_direction` | description               |
| ------------------ | ---------------- | ------------------------- |
| 1                  | -1               | reverse flow with no pressure reduction                                           |
| 1                  | 0                | reverse flow with no pressure reduction or forward flow with pressure reduction   |
| 1                  | 1                | forward flow with pressure reduction                                              |
| 0                  | -1               | no flow                                                                           |
| 0                  | 0                | forward flow with pressure reduction                                              |
| 0                  | 1                | forward flow with pressure reduction                                              |


## Valve

| `is_bidirectional` | `flow_direction` | description               |
| ------------------ | ---------------- | ------------------------- |
| 1                  | -1               | reverse flow only         |
| 1                  | 0                | flow in both directions   |
| 1                  | 1                | forward flow only         |
| 0                  | -1               | no flow                   |
| 0                  | 0                | forward flow only         |
| 0                  | 1                | forward flow only         |

## Resistor

| `is_bidirectional` | `flow_direction` | description               |
| ------------------ | ---------------- | ------------------------- |
| 1                  | -1               | reverse flow only         |
| 1                  | 0                | flow in both directions   |
| 1                  | 1                | forward flow only         |
| 0                  | -1               | no flow                   |
| 0                  | 0                | forward flow only         |
| 0                  | 1                | forward flow only         |

## Short Pipe

| `is_bidirectional` | `flow_direction` | description               |
| ------------------ | ---------------- | ------------------------- |
| 1                  | -1               | reverse flow only         |
| 1                  | 0                | flow in both directions   |
| 1                  | 1                | forward flow only         |
| 0                  | -1               | no flow                   |
| 0                  | 0                | forward flow only         |
| 0                  | 1                | forward flow only         |
