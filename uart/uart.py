import numpy as np
import serial
import time, datetime


# Seial port initialization 
ser = serial.Serial()
ser.baudrate = 115200
ser.port = 'COM5'
ser.timeout = 0.1


start_option = input('Would you like to start (y|n) => ')

if (start_option == "y" or "Y") : 
	ser.open()
	time.sleep(1)
	print ('Waiting for switch to be ON or OFF ...................')
	while True: 
		data_byte = ser.read(8)	
		if (data_byte !=b'' ):
			data_int = int.from_bytes(data_byte, byteorder="little")
			
			if (data_int == 0) :
			 	print ('All the switches are OFF.')
			else :
				data_bitstr = "{:08b}".format(int(data_byte.hex(),16))
				on_led = ''
				for i in reversed(range(len(data_bitstr))):
					if (data_bitstr[i] == '1'): 			
						on_led = on_led + str(8-i) + 'st '
				print ('At', datetime.datetime.now().strftime("%H:%M:%S"),'LED',on_led,'is(are) switched ON')	
	
	
		########## recieving a value from PC to the board ########
		# data_to_send = input('Enter a number x between 0 and 255 => ')
		# data_to_send = int(data_to_send)
		# if (0 <= data_to_send < 256) :  # editted for echo
		# 	data_byte = (data_to_send).to_bytes(1, byteorder="little")
		# 	ser.write(data_byte)
		# 	time.sleep(0.1)

		# 	####### added for echo  #######
		# 	data_read = ser.read(1)
		# 	data_read = int.from_bytes(data_read, byteorder="little")
		# 	print (data_read)
		# 	###############################
	
elif (start_option == "n" or "N"):
	print ('Loop ended.')

