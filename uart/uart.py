import numpy as np
import serial
import time

# Seial port initialization 
ser = serial.Serial()
ser.baudrate = 115200
ser.port = 'COM5'
ser.timeout = 0.1
ser.open()

while True:
	try: 
		data_to_send = input('Enter a number from 0 to 7 => ')
		data_to_send = int(data_to_send)
		if 0 <= data_to_send < 8 :  
			data_byte = (data_to_send).to_bytes(1, byteorder="little")
			ser.write(data_to_send)
			time.sleep(0.01)
		else :
			print('The number is not in the right range.')
			break
			
	except KeyboardInterrupt:
		break