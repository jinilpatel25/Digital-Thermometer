import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys, time, math

xsize=100
   
def data_gen():
    t = data_gen.t
    while True:
       t+=1
       val1=100.0*math.sin(t*2.0*np.pi/100.0)
       val2=100.0*math.cos(t*2.0*np.pi/100.0)
       yield t, val1, val2

def run(data):
    # update the data
    t,y1,y2 = data
    if t>-1:
        xdata.append(t)
        ydata1.append(y1)
        ydata2.append(y2)
        if t>xsize: # Scroll to the left.
            ax.set_xlim(t-xsize, t)
        line1.set_data(xdata, ydata1)
        line2.set_data(xdata, ydata2)

    return line1, line2

def on_close_figure(event):
    sys.exit(0)

data_gen.t = -1
fig = plt.figure()
fig.canvas.mpl_connect('close_event', on_close_figure)
ax = fig.add_subplot(111)
line1, = ax.plot([], [], lw=2, label='Sine')
line2, = ax.plot([], [], lw=2, label='Cosine')
ax.set_ylim(-100, 100)
ax.set_xlim(0, xsize)
ax.grid()
ax.legend()
xdata, ydata1, ydata2 = [], [], []

# Important: Although blit=True makes graphing faster, we need blit=False to prevent
# spurious lines to appear when resizing the stripchart.
ani = animation.FuncAnimation(fig, run, data_gen, blit=False, interval=100, repeat=False)
plt.show()
