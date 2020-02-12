import numpy as np
import serial
import time
import pyqtgraph as pg
from pyqtgraph.Qt import QtCore, QtGui
import pyqtgraph.multiprocess as mp
import threading
from PIL import Image

class EventPlotter(object):
    def __init__(self, ser):
        self.app = pg.mkQApp()
        self.proc = mp.QtProcess()
        self.rpg = self.proc._import('pyqtgraph')				
        self.plotwin = self.rpg.GraphicsWindow(title="Monitor")
        self.plotwin.resize(800,500)
        self.plotwin.setWindowTitle('Activity Monitor')
        self.p1 = self.plotwin.addPlot(title="Neuron spikes vs. time")
        self.p1.setLabel('left', 'Neuron Number')
        self.p1.setLabel('bottom', 'Time [s]')
        self.p1.showGrid(x=True, y=True, alpha=0.5)
        self.spikes_curve = self.p1.plot(pen=None, symbol="o", symbolPen=None, symbolBrush='w', symbolSize=3)   
		# self.app.exit(self.app.exec_()) # not sure if this is necessary	
        self.on_screen = 300 # Number of events on the screen
        self.all_time_stamps = np.zeros(self.on_screen)
        self.all_addresses = np.zeros(self.on_screen, dtype=int)		
        self.ser = ser
        self.old_stamp = 0

    def decode_events(self, byte_data):
        time_stamps = []
        addresses = []
        event_nr = int(len(byte_data)/3)

        if event_nr > 0:
            for e in range(event_nr):
                event = byte_data[e*3:e*3+3] 
                addresses.append(event[2])
                new_stamp = int.from_bytes(event[0:2], byteorder='big')                   
                time_stamps.append(new_stamp)
        
        return time_stamps, addresses
    
    def ReadEvents(self):
        try:
            event_data = self.ser.read(300)
            time_stamps, addresses = self.decode_events(event_data)
            dn = len(time_stamps)
            if dn > 0:
                self.all_time_stamps = np.roll(self.all_time_stamps, -dn)
                self.all_addresses = np.roll(self.all_addresses, -dn)
                self.all_time_stamps[-dn:] = np.array(time_stamps)
                self.all_addresses[-dn:] = np.array(addresses)				
                self.spikes_curve.setData(x=self.all_time_stamps, y=self.all_addresses, _callSync='off')            
        except:
            None
                       
# Seial port initialization 
ser = serial.Serial()
ser.baudrate = 115200
ser.port = 'COM5'
ser.timeout = 1                                  # read timeout value in float
ser.open()
# Flags
script_on = True 
spikes_on = False
EventPlotter = EventPlotter(ser=ser)

def cmd_in():  
    global script_on, spikes_on, EventPlotter     
    while True:
        cmd_raw = input("Enter a command => ")#.split()
             
        if (cmd_raw == "r"):
            ser.write(bytes.fromhex('01'))                          # enable ext read
            time.sleep(0.001)
           # EventPlotter.ReadEvents()
            try:
                EventPlotter.on_screen = 100           
                EventPlotter.all_time_stamps = np.zeros(EventPlotter.on_screen)
                EventPlotter.all_addresses = np.zeros(EventPlotter.on_screen, dtype=int)
            except:
                print("Invalid number after show command.\n")
                
        elif (cmd_raw == "clear"):
            EventPlotter.all_time_stamps = np.zeros(EventPlotter.on_screen)
            EventPlotter.all_addresses = np.zeros(EventPlotter.on_screen, dtype = int)
 
        elif (cmd_raw == "quit"):
            script_on = False
            ser.close()
            break   

       # elif (cmd_raw == "write"):           
            #ser.write(bytes.fromhex('02'))                              # enable ext write
            #ser.write(cmd_addr.to_bytes(1, byteorder="little"))      # send address
            #ser.write(cmd_activity.to_bytes(2, byteorder="little")[1])  # send 1st 1byte of activity
            #ser.write(cmd_activity.to_bytes(2, byteorder="little")[0])  # send 2nd 1byte of activity
            #ser.write(cmd_value.to_bytes(1, byteorder="little")) 
                            
        elif (cmd_raw == "stop"): # Stop FIFO reading
            ser.write(bytes.fromhex('04'))
            spikes_on = False

def run_plot():
	global script_on, EventPlotter, spikes_on
	while script_on == True:
		time.sleep(0.001)
		EventPlotter.ReadEvents()
	EventPlotter.proc.close()

thread_plot = threading.Thread(target=run_plot)
thread_plot.daemon = False
thread_plot.start()

cmd_in()
            
