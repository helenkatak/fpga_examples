import numpy as np
import math
from matplotlib import pyplot as plt

font = {'family' : 'normal',
        'weight' : 'normal',
        'size'   : 16}
plt.rc('font', **font)

from mpl_toolkits.axes_grid.inset_locator import (inset_axes, InsetPosition,mark_inset)
from matplotlib.ticker import FixedLocator, FixedFormatter

from FixedPoint import FXfamily, FXnum

## SRM model 
def SRM_ei(u1, u2, u3, w, sp_vec, uth):  #
    u1 = u1 * math.exp(-dt/tm)      # membrane
    u2 = u2 * math.exp(-dt/tse)     # synapse 
    u3 = u3 * math.exp(-dt/tref)    # refractory
    
    u1 = u1 + w * sp_vec            # w = matrix, vec = activity vector multiplication
    u2 = u2 + w * sp_vec
    umem = (u1 - u2) * tm / (tm - tse) + u3
    sp = np.where(umem > uth, 1, 0)  

    u1[umem > uth] = 0
    u2[umem > uth] = 0
    u3[umem > uth] = uref   
    
    return (umem, u1, u2, u3, sp)

## Neuron simulation:
tm = 40e-3
tse = 10e-3  
tref = tm #40e-3
uref = -2e-3

w = 0.01
uth = 0.009
sp_vec = 0   # 0 or 1

u1 = np.array([0])
u2 = np.array([0])
u3 = np.array([0])   

u_1 = np.array([0])
u_2 = np.array([0])
u_3 = np.array([0])

u_mem = np.array([0])
sp_ = np.array([0])


for t in range(1500):   
    if (t==50 or t == 220):# or t==400 or t==450 or t==535):        # spike input at time t
        sp_vec = 1
    else:
        sp_vec = 0
    
    umem, u1, u2, u3, sp = SRM_ei(u1, u2, u3, w, sp_vec, uth)
    #print(t, u1, u2, u3, umem)
    u_1 = np.append(u_1, u1)
    u_2 = np.append(u_2, u2)
    u_3 = np.append(u_3, u3)
    u_mem = np.append(u_mem, umem[0])
    sp_ = np.append(sp_, sp[0])


x = np.arange(0,1000000*2**-12,1000*2**-12)
fig, ax1 = plt.subplots(figsize=[8,2.5])
ax1.plot(u_mem, '--', c='r', alpha=1, label='Reference')
fig, ax2 = plt.subplots(figsize=[8,2.5])
ax2.plot(u_1+u_2)
fig, ax3 = plt.subplots(figsize=[8,2.5])
ax3.plot(u_3)
#plt.show()