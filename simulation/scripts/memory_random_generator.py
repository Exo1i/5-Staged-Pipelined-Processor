import random

# --- Configuration ---
FILE_NAME = "memory_data.mem"
NUM_LINES = 100  # Number of 32-bit words (memory depth)
WORD_BITS = 32   # Word size in bits
WORD_HEX_DIGITS = WORD_BITS // 4 # 32 bits / 4 bits per hex digit = 8 hex digits
# ---------------------

print(f"Generating {NUM_LINES} random {WORD_BITS}-bit hex words to '{FILE_NAME}'...")

with open(FILE_NAME, 'w') as f:
    for _ in range(NUM_LINES):
        # Generate a random integer in the 32-bit range (0 to 2^32 - 1)
        random_int = random.randint(0, (2**WORD_BITS) - 1)
        
        # Convert the integer to a hexadecimal string:
        # 1. 'x' for hexadecimal format
        # 2. '0' for zero padding
        # 3. '8' for the total width (8 characters for 32 bits)
        # 4. Remove the leading '0x' using [2:]
        hex_string = f'{random_int:0{WORD_HEX_DIGITS}x}'
        
        # Write the hex string followed by a newline
        f.write(hex_string + '\n')

print("✅ Generation complete!")
print(f"File created: {FILE_NAME}")