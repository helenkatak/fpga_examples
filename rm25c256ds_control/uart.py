import serial 
import time

ser = serial.Serial()   # Seial port initialization 
ser.baudrate = 115200	# Set the port baudrate @ "device manager"
ser.port = 'COM8'  	 	# Check the port # using "device manager"y
#ser.stopbits=serial.STOPBITS_ONE
#ser.bytesize=serial.EIGHTBITS
ser.timeout=0.1

while True:   
    start_option = input('Start the system (y or n): ')
    if start_option != 'y' and start_option != 'Y' :
        print ("Bye!")
        break     
    else: 
        while True: 
            ser.open()
            time.sleep(0.1)
            
            op_code = input('Enter an Intstruction code: ') 
            #while (op_code>300): 
             #   op_code = int(input('Invalid intruction! Enter again:  '))
              #  if (op_code<301):
              #       break               
            if (op_code == "WREN"): # write_enable    
                op_int = 6
            elif (op_code =="WRDI"):
                op_int = 4
            elif (op_code == "CERS"):
                op_int = 96
            elif (op_code == "PD"):
                op_int = 185
            elif (op_code == "UDPD"):
                op_int = 121
            elif (op_code == "RES"):
                op_int = 171
            elif (op_code == "RDSR"):
                op_int = 5
            elif (op_code == "WRSR"):
                op_int = 1
            elif (op_code == "WRSR2"):
                op_int = 49
            elif (op_code == "READ"):
                op_int = 3
            elif (op_code == "WR"):
                op_int = 2
                    
            if (op_int==5):
                 op_int_byte = (op_int).to_bytes(1, byteorder="big")  
                 ser.write(op_int_byte)    
                 sdo_byte = ser.read(1)          
                 sdo = int.from_bytes(sdo_byte, byteorder="big")  
                 print("WIP:", int(format(sdo, '08b')[0],2), "WEL:", int(format(sdo, '08b')[1],2), "BP0:", int(format(sdo, '08b')[2],2), "BP1:", int(format(sdo, '08b')[3],2))
                 print("UDPD:", int(format(sdo, '08b')[4],2), "LPSE:", int(format(sdo, '08b')[5],2), "APDE:", int(format(sdo, '08b')[6],2), "SRWD:", int(format(sdo, '08b')[7],2))   
            elif (op_int==1 or op_int==49):
                 inst_byte = (op_int).to_bytes(1, byteorder="big")  
                 ser.write(inst_byte)  
                 status = input('Enter a Status code: ') 
                 status_byte = (int(status)).to_bytes(1, byteorder="big")  
                 ser.write(status_byte)  
            elif (op_int==3):
                 inst_byte = (op_int).to_bytes(1, byteorder="big")  
                 ser.write(inst_byte) 
                 addr = input ('Enter an address: ')
                 addr_byte=int(addr).to_bytes(2,byteorder='big')
                 ser.write(addr_byte[:1])  
                 ser.write(addr_byte[1:2]) 
                 
                 sdo_byte = ser.read(1)          
                 sdo = int.from_bytes(sdo_byte, byteorder="little")  
                 print(sdo_byte, sdo, bin(sdo) )  
            elif (op_int==2):
                 inst_byte = (op_int).to_bytes(1, byteorder="big")  
                 ser.write(inst_byte)  
                 addr = input ('Enter an address: ')
                 addr_byte=int(addr).to_bytes(2,byteorder='big')
                 ser.write(addr_byte[:1])  
                 ser.write(addr_byte[1:2])    
                 din1 = input('Enter data input: ') 
                 din1_byte = int(din1).to_bytes(1, byteorder="big")  
                 ser.write(din1_byte)  
            else:
                op_int_byte = (op_int).to_bytes(1, byteorder="big")  
                ser.write(op_int_byte)             
                            
            ser.close()
            break
                    
        