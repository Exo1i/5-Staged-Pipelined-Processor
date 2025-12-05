"""
ISA Constants for 5-Stage Pipelined RISC Processor
Target: 32-bit Word Addressable Memory (1 MB Total Size)
Address Space: 18 bits (2^18 Words = 1 MB)
"""


class ISA:
    """Instruction Set Architecture constants and definitions"""

    # ========== OPCODES (5-bit) ==========
    OPCODES = {
        # One Operand Instructions (1 Word)
        'NOP':  0b00000,
        'HLT':  0b00001,
        'SETC': 0b00010,
        'NOT':  0b00011,
        'INC':  0b00100,
        'OUT':  0b00101,
        'IN':   0b00110,

        # Two Operand Instructions (1 Word)
        'MOV':  0b00111,
        'SWAP': 0b01000,
        'ADD':  0b01001,
        'SUB':  0b01010,
        'AND':  0b01011,

        # Immediate Instructions (2 Words)
        'IADD': 0b01100,

        # Memory Operations (Mixed)
        'PUSH': 0b01101,  # 1 Word
        'POP':  0b01110,  # 1 Word
        'LDM':  0b01111,  # 2 Words
        'LDD':  0b10000,  # 2 Words
        'STD':  0b10001,  # 2 Words

        # Branch and Control (2 Words for jumps with address/imm)
        'JZ':   0b10010,
        'JN':   0b10011,
        'JC':   0b10100,
        'JMP':  0b10101,
        'CALL': 0b10110,
        'RET':  0b10111,  # 1 Word
        'INT':  0b11000,  # 1 Word
        'RTI':  0b11001,  # 1 Word
    }

    # ========== INSTRUCTION SIZES (in 32-bit Words) ==========
    # 1 = Opcode Word only
    # 2 = Opcode Word + Immediate/Offset Word
    INSTRUCTION_SIZES = {
        # 1 Word
        'NOP': 1, 'HLT': 1, 'SETC': 1, 'NOT': 1, 'INC': 1, 'OUT': 1, 'IN': 1,
        'MOV': 1, 'SWAP': 1, 'ADD': 1, 'SUB': 1, 'AND': 1,
        'PUSH': 1, 'POP': 1,
        'RET': 1, 'RTI': 1, 'INT': 1,

        # 2 Words (Instruction + Immediate/Offset)
        'IADD': 2, 'LDM': 2,
        'LDD': 2, 'STD': 2,
        'JZ': 2, 'JN': 2, 'JC': 2, 'JMP': 2, 'CALL': 2,
    }

    # ========== INSTRUCTION CLASSIFICATIONS ==========
    NO_OPERAND_INSTRUCTIONS = {'NOP', 'HLT', 'SETC', 'RET', 'RTI'}
    SINGLE_REGISTER_INSTRUCTIONS = {'NOT', 'INC', 'OUT', 'IN', 'PUSH', 'POP'}
    ONE_OPERAND_INSTRUCTIONS = NO_OPERAND_INSTRUCTIONS | SINGLE_REGISTER_INSTRUCTIONS

    TWO_OPERAND_INSTRUCTIONS = {'MOV', 'SWAP'}
    THREE_OPERAND_INSTRUCTIONS = {'ADD', 'SUB', 'AND'}

    # These require the extra word
    IMMEDIATE_INSTRUCTIONS = {'IADD', 'LDM'}
    MEMORY_OFFSET_INSTRUCTIONS = {'LDD', 'STD'}
    BRANCH_INSTRUCTIONS = {'JZ', 'JN', 'JC', 'JMP', 'CALL'}

    # ========== MEMORY CONSTANTS ==========
    # 1 MB Total Size / 4 Bytes per Word = 262,144 Words
    # Log2(262144) = 18 bits
    ADDRESS_WIDTH = 18
    MEMORY_WORDS = 2 ** ADDRESS_WIDTH  # 262,144

    # Stack Pointer starts at the top of memory
    INITIAL_SP = MEMORY_WORDS - 1  # 0x3FFFF

    # ========== BIT SHIFTS FOR ENCODING ==========
    # Layout Word 1: [Opcode 31:27] [R1 26:24] [R2 23:21] [R3 20:18] [Zeros 17:0]
    SHIFT_OPCODE = 27
    SHIFT_R1 = 24
    SHIFT_R2 = 21
    SHIFT_R3 = 18

    @classmethod
    def get_opcode(cls, mnemonic: str) -> int:
        return cls.OPCODES.get(mnemonic.upper())

    @classmethod
    def get_size(cls, mnemonic: str) -> int:
        return cls.INSTRUCTION_SIZES.get(mnemonic.upper(), 1)
