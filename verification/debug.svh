`define _ADVANCED_DEBUG_ 0
`define _DEBUG_FULL_ 0
`define _DEBUG_DRIV_ 0
`define _DEBUG_MON_ 0
`define _DEBUG_SCB_ 0
`define _SHOW_ALL_ERR_ 1
`define _RCV_RDY_ERR_ 0
`define _DATA_RDY_ERR_ 0
`define _ADDR_OUT_ERR_ 0
`define _DATA_OUT_ERR_ 0
`define _BIT_SIZE_DATA_ 16
`define _BIT_SIZE_ADDR_ 16
`define _PORT_SIZE_ 4
`define _PORT_NUMBER_ 4
`define _FOR_LOOP_ 4 // this is to change if only data and addres size in addition to the port number is increased by the same portion 
                     // Ex: if port is 8 then data size is 64 if data is 256 then the port number is 16 in so on 


                     // make sure to make your reset to be same bit size as it is assigned to a6 bit and 4 
                     // if you don't know nothing just cry 