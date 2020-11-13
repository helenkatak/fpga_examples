import serial 
import time

ser = serial.Serial()   # Seial port initialization 
ser.baudrate = 115200	# Set the port baudrate @ "device manager"
ser.port = 'COM8'  	 	# Check the port # using "device manager"y
ser.timeout = 0.1
 


while True:   
    start_option = input('Start the RXM system (y or n): ')
    if start_option != 'y' and start_option != 'Y' :
        print ("Bye!")
        break     
    else: 
        while True: 
            ser.open()
            time.sleep(1)
            #data_col_ps = (input('Parallel or single cell addressing (p or s): ')) 
            data_col_ps = 's'
            if (data_col_ps == 'p'):
                data_col = int(input('Enter a column number between 1 and 30: '))   # 0<data_col<=30
                while (data_col>30): 
                    data_col = int(input('Out of range! Enter between 1 and 30:  '))
                    if (data_col<31):
                         break               
                data_col_byte = (data_col).to_bytes(1, byteorder="little")  
                ser.write(data_col_byte)  
                
                time.sleep(0.1)
                read_col_byte = ser.read(1)
                read_col = int.from_bytes(read_col_byte, byteorder="little")
                
                print ("Column", read_col, "is selected for parallel addressing")
                break 
            elif (data_col_ps == 's'):               
                data_col = int(input('Enter a column number between 1 and 30: '))  
                while (data_col>30): 
                    data_col = int(input('Out of range! Enter between 1 and 30:  '))
                    if (data_col<31):
                         break               
                data_col_byte = (data_col).to_bytes(1, byteorder="big")  
                ser.write(data_col_byte) 
                
                time.sleep(0.1)
                read_col_byte = ser.read(1)
                read_col = int.from_bytes(read_col_byte, byteorder="little")
                
                data_row = int(input('Enter a row number between 1 and 30: '))   
                while (data_row>30):
                    data_row = int(input('Out of range! Enter between 1 and 30: '))
                    if (data_row<31):                      
                        break
                data_row_byte = (data_row).to_bytes(1, byteorder="little")  
                ser.write(data_row_byte)   
                
                time.sleep(1)  
                read_row_byte = ser.read(1)
                read_row = int.from_bytes(read_row_byte, byteorder="little")
                                 
                print ("Column", read_col, "and row", read_row, "are selected for cell addressing")
                 
            ser.close()
            break
                    