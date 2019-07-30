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
		data_to_send = input('Enter a number x between 0 and 255 => ')
		data_to_send = int(data_to_send)
		if (0 <= data_to_send < 256) :  # editted for echo
			data_byte = (data_to_send).to_bytes(1, byteorder="little")
			ser.write(data_byte)
			time.sleep(0.1)

			####### added for echo  #######
			data_read = ser.read(1)
			data_read = int.from_bytes(data_read, byteorder="little")
			print (data_read)
			###############################
		else :
			raise ValueError('x should not be less than 256!')
			
	except KeyboardInterrupt:
		break