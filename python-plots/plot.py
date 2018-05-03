import matplotlib
import matplotlib.pyplot as plt
import scipy.integrate as integrate
from scipy.interpolate import interp1d
import csv
import math

# Config for the plot
font = {'family' : 'Roboto',
        'weight' : 'normal',
        'size'   : 20}
matplotlib.rc('font', **font)

# Constants
PEAK_START_TIME = 150 # !HARDCODED! Time when peak starts (manually derived, [s])
PEAK_END_TIME = 300 # !HARDCODED! Time when peak ends (manually derived, [s])

# Variables
baseline = math.inf

x_vals = []
y_vals = []

peak_x_vals = []
peak_y_vals = []

# Read data !HARDCODED! Path to CSV data
with open('raw-data-a.csv', newline='') as csvfile: # File must be formatted as: <time as float>,<signal as float>\n
    reader = csv.reader(csvfile, delimiter=',')
    # Iterate over each line and populate list
    for row in reader:
        # Read data and parse to float
        TIME = float(row[0]) * 60 # Time val is given as minute (float), hence convert to seconds
        SIGNAL = float(row[1])

        x_vals.append(TIME)
        y_vals.append(SIGNAL)

# Derive peak values
i = -1
for y_val in y_vals:
    i = i + 1

    if x_vals[i] < PEAK_START_TIME or x_vals[i] > PEAK_END_TIME: # Skip if time is not in between PEAK_START_TIME and PEAK_END_TIME
        continue

    peak_x_vals.append(x_vals[i])

    SIGNAL = y_vals[i]

    if baseline > SIGNAL:
        baseline = SIGNAL

    peak_y_vals.append(y_vals[i])

print('Baseline is', baseline)

# Apply baseline correction
peak_y_vals = [y_val - baseline for y_val in peak_y_vals]

# Calculate peak area
result = integrate.trapz(peak_y_vals, x=peak_x_vals)
print('Peak area: {}'.format(result))

# Plot chromatogram
fig = plt.figure()
ax = fig.add_subplot(111)
ax.set_xlabel('Retention time [s]', fontsize=24)
ax.set_ylabel('Intensity [–]', fontsize=24)
ax.plot(x_vals, y_vals, linestyle='-', linewidth=5)
plt.show()
