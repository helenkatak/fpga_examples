import serial 
import time

ser = serial.Serial()   # Seial port initialization 
ser.baudrate = 115200	# Set the port baudrate @ "device manager"
ser.port = 'COM5'  	 	# Check the port # using "device manager"y
ser.timeout=0.1

while True:   
    start_option = input('Start the system (y or n): ')
    if start_option != 'y' and start_option != 'Y' :
        print ("Bye!")
        break     
    else: 
        while True: 
            ser.open()            
            ins = input('Enter an Intstruction code: ') 
            while (ins!="WREN" and ins!="WRDI" and ins!="CERS" 
                   and ins!="PD" and ins!="UDPD" and ins!="RES" 
                   and ins!="RDSR" and ins!="WRSR" and ins!="WRSR2" 
                   and ins!="RD" and ins!="RDB" and ins!="PCNT" 
                   and ins!="WR" and ins!="FRD"): 
                ins = input('Invalid intruction! Enter again:  ')
                if (ins!="WREN" and ins!="WRDI" and ins!="CERS" 
                    and ins!="PD" and ins!="UDPD" and ins!="RES" 
                    and ins!="RDSR" and ins!="WRSR" and ins!="WRSR2" 
                    and ins!="RD" and ins!="RDB" and ins!="PCNT" 
                    and ins!="WR" and ins!="FRD"):  break               
            if   (ins == "WREN"):   op_int = 6
            elif (ins == "WRDI"):   op_int = 4
            elif (ins == "CERS"):   op_int = 96
            elif (ins == "WRSR"):   op_int = 1
            elif (ins == "WRSR2"):  op_int = 49               
            elif (ins == "RDSR"):   op_int = 5
            elif (ins == "WR"):     op_int = 2
            elif (ins == "RD"):     op_int = 3
            elif (ins == "RDB"):    op_int = 33
            elif (ins == "PCNT"):   op_int = 34
            elif (ins == "FRD"):    op_int = 11       
            elif (ins == "PD"):     op_int = 185
            elif (ins == "RES"):    op_int = 171               
            elif (ins == "UDPD"):   op_int = 121

            if (op_int==5):         ## RDSR
                ser.write((op_int).to_bytes(1, byteorder="big")  )    
                sdo_byte = ser.read(1)          
                sdo = int.from_bytes(sdo_byte, byteorder="big")  
                print("WIP:", int(format(sdo,'08b')[7],2), "WEL:", int(format(sdo, '08b')[6],2), "BP0:", int(format(sdo, '08b')[5],2), "BP1:", int(format(sdo, '08b')[4],2))
                print("UDPD:", int(format(sdo, '08b')[3],2), "LPSE:", int(format(sdo, '08b')[2],2), "APDE:", int(format(sdo, '08b')[1],2), "SRWD:", int(format(sdo, '08b')[0],2))   
            elif (op_int==1 or op_int==49): ## WRSR
                ser.write((op_int).to_bytes(1, byteorder="big")) 
                status = input('Enter a Status code: ') 
                status_byte = (int(status)).to_bytes(1, byteorder="big")                   
                ser.write(status_byte) 
            elif (op_int==3): ## READ ## Operate correctly only at <1MHz
                ser.write((op_int).to_bytes(1, byteorder="big") )
                addr = input ('Enter an address: ')
                ser.write(int(addr).to_bytes(2,byteorder='big')[:1])  
                ser.write(int(addr).to_bytes(2,byteorder='big')[1:2])                          
                sdo_byte = ser.read(1)                           
                print(int.from_bytes(sdo_byte, byteorder="big")  )  
            elif (op_int==33): ## READ ## Operate correctly only at <1MHz 
                ser.write((op_int).to_bytes(1, byteorder="big"))
                addr = input ('Enter an address: ')
                ser.write(int(addr).to_bytes(2,byteorder='big')[:1])  
                ser.write(int(addr).to_bytes(2,byteorder='big')[1:2]) 
                for n in range(64):
                    sdo_byte = ser.read(1)                           
                    sdo = int.from_bytes(sdo_byte, byteorder="big")  
                    print(sdo, bin(sdo))   
            elif (op_int==34): ## READ series 16 bytes
                ser.write((op_int).to_bytes(1, byteorder="big") )
                addr = input ('Enter an address: ')
                ser.write(int(addr).to_bytes(2,byteorder='big')[:1])  
                ser.write(int(addr).to_bytes(2,byteorder='big')[1:2])                       
                for n in range(4):
                    sdo_byte = ser.read(1)                           
                    sdo = int.from_bytes(sdo_byte, byteorder="big")  
                    print(sdo, bin(sdo))  
            elif (op_int==2): ## WR ##
                ser.write((op_int).to_bytes(1, byteorder="big"))  
                addr = input ('Enter an address: ')
                ser.write(int(addr).to_bytes(2,byteorder='big')[:1])  
                ser.write(int(addr).to_bytes(2,byteorder='big')[1:2])   
                din = input('Enter data input: ') 
                ser.write(int(din).to_bytes(1, byteorder="big"))  
            elif (op_int==11): ## Fast READ ## 
                ser.write((op_int).to_bytes(1, byteorder="big"))  
                addr = input ('Enter an address: ')
                ser.write(int(addr).to_bytes(2,byteorder='big')[:1])  
                ser.write(int(addr).to_bytes(2,byteorder='big')[1:2])  
                dummy=0#input ('Enter an dummy byte: ')
                ser.write(int(dummy).to_bytes(1,byteorder='big'))
                for n in range(256):
                    sdo_byte = ser.read(2)                           
                    sdo = int.from_bytes(sdo_byte, byteorder="little")  
                    print(n+1, sdo) 
            else: ser.write((op_int).to_bytes(1, byteorder="big")) ## WREN, WRDI, CERS ## RDSR      
                
            ser.close()
            break
                    
        