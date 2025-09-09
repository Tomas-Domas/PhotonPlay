import matplotlib.pyplot as plt
from PIL import Image
import os
import sys

# ./anaconda3/envs/aml/python.exe '.\Documents\design\PhotonPlay\demo materials\tb\tracer.py' '.\Documents\Dumb stuff\project_2\project_2.sim\sim_1\behav\xsim\output.txt'

# Check command-line arguments
if len(sys.argv) != 3:
    print(f"Usage: python {sys.argv[0]} <input_file> <output_file>")
    sys.exit(1)

INPUT_FILE = sys.argv[1]
OUTPUT_GIF = sys.argv[2]

# Read data points from file
x_data = []
y_data = []

with open(INPUT_FILE, "r") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        x, y = line.split(",")
        x_data.append(float(x))
        y_data.append(float(y))

# Generate frames
bbox_buffering = 200
frames = []
for i in range(1, len(x_data) + 1):
    plt.figure(figsize=(6, 4))
    plt.plot(x_data[:i], y_data[:i], color='blue', marker='o')
    plt.xlim(min(x_data) - bbox_buffering, max(x_data) + bbox_buffering)
    plt.ylim(min(y_data) - bbox_buffering, max(y_data) + bbox_buffering)
    plt.grid(True)
    plt.xlabel("X")
    plt.ylabel("Y")
    plt.title("Line Traveling Over Data Points")

    temp_file = f"frame_{i}.png"
    plt.savefig(temp_file)
    plt.close()
    frames.append(Image.open(temp_file))

# Save GIF
frames[0].save(OUTPUT_GIF, format='GIF', append_images=frames[1:], save_all=True, duration=400, loop=0)

# Clean up temporary files
for i in range(1, len(x_data) + 1):
    os.remove(f"frame_{i}.png")

print(f"GIF saved as {OUTPUT_GIF}")
