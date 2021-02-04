
file = open(r"C:/Users/KJS/PROJECT_WS/fpga_projects/rm25c256ds_control/input.mem","w")

for n in range(256):
    if (n==0): data = 0
    elif (n==255): data = 2**1024-1
    else:      data = (data+5)<<4
    file.write('{:01024b}'.format(data)+"\r")

file.close() 