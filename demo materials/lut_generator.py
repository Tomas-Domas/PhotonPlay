import math
import csv
PI = math.pi


# SIZE CONSTANTS
LUT_SIZE      = 8   # Create table with LUT_SIZE number of entries 
LUT_BIT_DEPTH = 12  # Each entry is LUT_BIT_DEPTH number of bits


def f_x(x):
    return x

def f_y(y):
    return y

def main():
    x_lut = create_lut(
        function = math.cos,
        domain = [0, 2*PI],
        periodic = False
    )
    y_lut = create_lut(
        function = math.sin,
        domain = [0, 2*PI],
        periodic = False
    )

    FILE_NAME = "octagon"
    write_verilog_LUT(FILE_NAME+"_x_lut.txt", x_lut)
    write_verilog_LUT(FILE_NAME+"_y_lut.txt", y_lut)

    # write_csv("waveform.csv", x_lut, y_lut)

    # atan_lut = create_lut(
    #     function = math.atan,
    #     domain = [-0.466307658155, 0.466307658155]
    # )


def create_lut(*, function, domain, periodic=False, binary=False):
    if periodic:
        step_size = (domain[1] - domain[0])/(LUT_SIZE)
    else:
        step_size = (domain[1] - domain[0])/(LUT_SIZE-1)

    lut = []
    minimum = function(domain[0])
    maximum = function(domain[0])

    # Calculate values and bounds
    for i in range(LUT_SIZE):
        val = function(domain[0] + i*step_size)
        lut.append(val)

        if minimum > val:
            minimum = val
        if maximum < val:
            maximum = val

    for i in range(LUT_SIZE):
        # Scale
        lut[i] = round((lut[i] - minimum) / (maximum - minimum) * (2**LUT_BIT_DEPTH - 1))
        
        # Convert to string of 1s and 0s
        if binary:
            lut[i] = bin(round(lut[i]))[2:].zfill(LUT_BIT_DEPTH)

        print(str(i).zfill(2) + ": ", lut[i])
    
    print()
    
    return lut


def write_csv(filename, x_lut, y_lut):
    # NOTE: all data signals are doubled in length since clock edges are in between.
    DAC_A_COMMAND = "0001"
    DAC_B_COMMAND = "1010"

    # Columns
    data = []
    clk  = []
    cs   = []

    for entry_i in range(len(x_lut)):
        # Write x command
        for bit in (DAC_A_COMMAND + x_lut[entry_i] + "00"):  # Command, data, 2 "don't care" bits
            add_bit(data, clk, cs, int(bit))
        add_end_condition(data, clk, cs)

        # Write y command
        for bit in (DAC_B_COMMAND + y_lut[entry_i] + "00"):  # Command, data, 2 "don't care" bits
            add_bit(data, clk, cs, int(bit))
        add_end_condition(data, clk, cs)

    # Write to CSV
    rows = zip(data, clk, cs)
    with open(filename, mode="w", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(["Pin0", "Pin1", "Pin2"])
        writer.writerows(rows)


def write_verilog_LUT(filename, lut):
    with open(filename, mode="w", encoding="utf-8") as file:
        for index in range(0, len(lut)):
            value = lut[index]
            line = f"rom[{index}] = 12'd{value};\n"
            file.write(line)



# ========== HELPER FUNCTIONS ==========
def add_end_condition(data, clk, cs):
    data += [0]
    clk  += [0]
    cs   += [1]

def add_bit(data, clk, cs, bit):
    data += [bit, bit]
    clk  += [0, 1]
    cs   += [0, 0]

def to_rad(degrees):
    return degrees/180 * math.pi



if __name__ == "__main__":
    main()
