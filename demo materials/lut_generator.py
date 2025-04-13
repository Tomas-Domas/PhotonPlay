import math
import csv

# SIZE CONSTANTS
LUT_ADDRESS_SIZE = 7   # Create LUT with 2^x entries 
LUT_BIT_DEPTH    = 10  # Each entry is x bits

def main():
    x_lut = create_lut(
        function = math.sin,
        domain = [0, 2*math.pi],
        periodic = True
    )
    print()
    y_lut = create_lut(
        function = math.cos,
        domain = [0, 2*math.pi],
        periodic = True
    )

    write_csv(x_lut, y_lut)
    # atan_lut = create_lut(
    #     function = math.atan,
    #     domain = [-0.466307658155, 0.466307658155]
    # )


def create_lut(*, function, domain, periodic=False):
    num_steps = 2**LUT_ADDRESS_SIZE
    if periodic:
        step_size = (domain[1] - domain[0])/(num_steps)
    else:
        step_size = (domain[1] - domain[0])/(num_steps-1)

    lut = []
    minimum = function(domain[0])
    maximum = function(domain[0])

    # Calculate values and bounds
    for i in range(num_steps):
        val = function(domain[0] + i*step_size)
        lut.append(val)

        if minimum > val:
            minimum = val
        if maximum < val:
            maximum = val

    for i in range(num_steps):
        # Scale
        lut[i] = round((lut[i] - minimum) / (maximum - minimum) * (2**LUT_BIT_DEPTH - 1))
        
        # Convert to string of 1s and 0s
        lut[i] = bin(round(lut[i]))[2:].zfill(LUT_BIT_DEPTH)

        print(str(i).zfill(2) + ": ", lut[i])
    
    return lut


def write_csv(x_lut, y_lut):
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
    with open('waveform.csv', mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(['Pin0', 'Pin1', 'Pin2'])
        writer.writerows(rows)



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
