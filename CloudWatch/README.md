# CloudWatch tools

## Read-FlowLog

Reads a flow-log log stream and deconstructs the log messages into a list of objects with fields you can work with.
Each object has the following fields

| Property      | Description                                                                                                         |
|---------------|---------------------------------------------------------------------------------------------------------------------|
| Version       | The VPC Flow Logs version.                                                                                          |
| AccountId     | The AWS account ID for the flow log.                                                                                |
| InterfaceId   | The ID of the network interface for which the traffic is recorded.                                                  |
| SourceAddress | The source IPv4 or IPv6 address. The IPv4 address of the network interface is always its private IPv4 address.      |
| DestAddress   | The destination IPv4 or IPv6 address. The IPv4 address of the network interface is always its private IPv4 address. |
| SourcePort    | The source port of the traffic.                                                                                     |
| DestPort      | The destination port of the traffic.                                                                                |
| Protocol      | The IANA protocol number of the traffic. For more information, see  [Assigned Internet Protocol Numbers](http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml). |
| Packets       | The number of packets transferred during the capture window.                                                        |
| Bytes         | The number of bytes transferred during the capture window.                                                          |
| StartTime     | The time, as a local DateTime, of the start of the capture window.                                                  |
| EndTime       | The time, as a local DateTime, of the end of the capture window.                                                    |
| Action        | The action associated with the traffic: ACCEPT or REJECT                                                            |
| Status        | The logging status of the flow log: OK, NODATA or SKIPDATA                                                          |

See also [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

