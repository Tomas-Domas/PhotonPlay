import math

# SIZE CONSTANTS
LUT_ADDRESS_SIZE = 6   # Create LUT with 2^x entries 
LUT_BIT_DEPTH    = 12  # Each entry is x bits

# FUNCTION CONSTANTS
FUNCTION  = math.atan
DOMAIN = [-0.466307658155, 0.466307658155]  # bounds of input values

def main():
    lower_bound = FUNCTION(DOMAIN[0])
    upper_bound = FUNCTION(DOMAIN[1])
    num_steps = 2**LUT_ADDRESS_SIZE
    step_size = (DOMAIN[1] - DOMAIN[0])/(num_steps-1)

    lut = [
        round((FUNCTION(DOMAIN[0] + i*step_size) - lower_bound) / (upper_bound-lower_bound) * (2**LUT_BIT_DEPTH - 1))
        for i in range(num_steps)
    ]

    print_lut(lut, LUT_ADDRESS_SIZE, LUT_BIT_DEPTH)


# ========== HELPER FUNCTIONS ==========
def print_lut(lut, address_size, bit_depth):
    for i in range(2**address_size):
        print(
            str(i).zfill(2) + ": ",
            str(lut[i])[0:8],
            bin(round(lut[i]))[2:].zfill(bit_depth)
        )

def to_rad(degrees):
    return degrees/180 * math.pi

if __name__ == "__main__":
    main()
