#!/usr/bin/env python3
"""
Two-Pass Assembler for 5-Stage Pipelined RISC Processor
Target: 32-bit Word Addressable Memory
Logic: Variable Instruction Size (1 or 2 Words)
Constraint: Immediates are 16-bit sign-extended to 32-bit in the second word
Constraint: Memory Address space is 18-bit (1MB Total)
"""

import sys
import re
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from isa_constants import ISA


@dataclass
class Instruction:
    """Represents a parsed instruction"""
    label: Optional[str]
    mnemonic: str
    operands: List[str]
    line_num: int
    address: int = 0
    machine_code: List[int] = None  # List of 32-bit words


class Assembler:
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.symbol_table: Dict[str, int] = {}
        self.instructions: List[Instruction] = []
        self.current_address = 0
        self.errors = []

    def log(self, message: str):
        if self.verbose:
            print(f"[ASSEMBLER] {message}")

    def error(self, message: str, line_num: int = None):
        if line_num:
            self.errors.append(f"Line {line_num}: {message}")
        else:
            self.errors.append(message)

    def parse_register(self, reg_str: str) -> Optional[int]:
        reg_str = reg_str.strip().upper()
        if reg_str.startswith('R') and len(reg_str) == 2:
            try:
                reg_num = int(reg_str[1])
                if 0 <= reg_num <= 7:
                    return reg_num
            except ValueError:
                pass
        return None

    def parse_number(self, num_str: str) -> Optional[int]:
        """
        Parses a number string into a raw integer. 
        Supports Hex (0x, h), Binary (0b, b), and Decimal.
        Does NOT apply masking or width validation here.
        """
        num_str = num_str.strip()
        try:
            if num_str.startswith('0x') or num_str.startswith('0X'):
                return int(num_str, 16)
            elif num_str.lower().endswith('h'):
                return int(num_str[:-1], 16)
            elif num_str.startswith('0b') or num_str.startswith('0B'):
                return int(num_str, 2)
            elif num_str.lower().endswith('b'):
                return int(num_str[:-1], 2)
            else:
                return int(num_str)
        except ValueError:
            return None

    def sign_extend_16bit(self, value: int) -> int:
        """
        Interprets the lower 16 bits of 'value' as a signed integer
        and extends the sign to 32 bits.
        Value must be passed as a raw 16-bit pattern (0 to 65535).
        """
        # Ensure we are looking at just the 16 bits
        val_16 = value & 0xFFFF

        # Check sign bit (Bit 15)
        if val_16 & 0x8000:
            return val_16 | 0xFFFF0000
        return val_16

    def parse_offset_operand(self, operand: str) -> Optional[Tuple[int, int]]:
        """Parse offset(register) format -> (offset, register)"""
        match = re.match(r'([^(]+)\s*\(\s*R(\d)\s*\)',
                         operand.strip(), re.IGNORECASE)
        if match:
            offset = self.parse_number(match.group(1))
            reg = int(match.group(2))
            if offset is not None and 0 <= reg <= 7:
                return (offset, reg)
        return None

    def tokenize_line(self, line: str) -> Tuple[Optional[str], str, List[str]]:
        if ';' in line:
            line = line[:line.index(';')]
        line = line.strip()
        if not line:
            return None, '', []

        label = None
        if ':' in line:
            parts = line.split(':', 1)
            label = parts[0].strip()
            line = parts[1].strip() if len(parts) > 1 else ''

        if not line:
            return label, '', []

        parts = line.split(None, 1)
        mnemonic = parts[0].upper()
        operands = []
        if len(parts) > 1:
            operands = [op.strip() for op in parts[1].split(',')]

        return label, mnemonic, operands

    def handle_directive(self, directive: str, operands: List[str], line_num: int) -> bool:
        if directive == '.ORG':
            if len(operands) < 1:
                self.error(".ORG requires an address operand", line_num)
                return True
            new_address = self.parse_number(operands[0])
            if new_address is None:
                self.error(
                    f"Invalid address for .ORG: '{operands[0]}'", line_num)
                return True

            # Validation: Non-negative
            if new_address < 0:
                self.error(
                    f".ORG address cannot be negative: {new_address}", line_num)
                return True

            # Validation: 18-bit Limit
            if new_address >= ISA.MEMORY_WORDS:
                self.error(
                    f".ORG address {new_address:05X} exceeds memory size (18-bit limit: {ISA.MEMORY_WORDS:05X})", line_num)
                return True

            if new_address < self.current_address:
                self.error(
                    f".ORG address {new_address} is before current {self.current_address}", line_num)
                return True

            self.current_address = new_address
            self.log(f".ORG directive: set address to {new_address:05X}")
            return True
        return False

    def first_pass(self, lines: List[str]):
        """First pass: Symbol table and Address calculation"""
        self.log(
            f"Starting first pass (Memory Limit: {ISA.MEMORY_WORDS} Words)...")
        self.current_address = 0

        for line_num, line in enumerate(lines, 1):
            label, mnemonic, operands = self.tokenize_line(line)

            # Check address overflow
            if self.current_address >= ISA.MEMORY_WORDS:
                self.error(
                    f"Program exceeds memory limit of {ISA.MEMORY_WORDS} words", line_num)
                return

            if label:
                if label in self.symbol_table:
                    self.error(f"Duplicate label '{label}'", line_num)
                else:
                    self.symbol_table[label] = self.current_address
                    self.log(
                        f"Label '{label}' -> Address {self.current_address:05X}")

            if mnemonic and mnemonic.startswith('.'):
                if self.handle_directive(mnemonic, operands, line_num):
                    continue

            if mnemonic:
                if mnemonic not in ISA.OPCODES:
                    self.error(f"Unknown instruction '{mnemonic}'", line_num)
                    continue

                instr = Instruction(
                    label=label,
                    mnemonic=mnemonic,
                    operands=operands,
                    line_num=line_num,
                    address=self.current_address
                )
                self.instructions.append(instr)

                ops_str = ", ".join(operands)
                self.log(f"Parsed {instr.address:05X}: {mnemonic} {ops_str}")

                size = ISA.get_size(mnemonic)
                self.current_address += size

    # ================= ENCODING HELPERS =================

    def pack_header(self, opcode: int, r1: int = 0, r2: int = 0, r3: int = 0) -> int:
        """
        Packs the first word of the instruction.
        Format: [Opcode 31:27] [R1 26:24] [R2 23:21] [R3 20:18] [Zeros 17:0]
        """
        word = (opcode << ISA.SHIFT_OPCODE)
        word |= (r1 << ISA.SHIFT_R1)
        word |= (r2 << ISA.SHIFT_R2)
        word |= (r3 << ISA.SHIFT_R3)
        return word

    def encode_one_operand(self, instr: Instruction) -> List[int]:
        opcode = ISA.OPCODES[instr.mnemonic]

        if instr.mnemonic in ISA.NO_OPERAND_INSTRUCTIONS:
            return [self.pack_header(opcode)]

        if len(instr.operands) < 1:
            self.error(f"{instr.mnemonic} requires 1 operand", instr.line_num)
            return [0]

        rdst = self.parse_register(instr.operands[0])
        if rdst is None:
            self.error(
                f"Invalid register '{instr.operands[0]}'", instr.line_num)
            return [0]
        
        if instr.mnemonic == 'OUT':
            return [self.pack_header(opcode, r2=rdst)]

        return [self.pack_header(opcode, r1=rdst)]

    def encode_two_operand(self, instr: Instruction) -> List[int]:
        if len(instr.operands) < 2:
            self.error(f"{instr.mnemonic} requires 2 operands", instr.line_num)
            return [0]

        rsrc = self.parse_register(instr.operands[0])
        rdst = self.parse_register(instr.operands[1])

        if rsrc is None or rdst is None:
            self.error(f"Invalid registers", instr.line_num)
            return [0]

        opcode = ISA.OPCODES[instr.mnemonic]
        return [self.pack_header(opcode, r1=rdst, r2=rsrc)]

    def encode_three_operand(self, instr: Instruction) -> List[int]:
        if len(instr.operands) < 3:
            self.error(f"{instr.mnemonic} requires 3 operands", instr.line_num)
            return [0]

        rdst = self.parse_register(instr.operands[0])
        rsrc1 = self.parse_register(instr.operands[1])
        rsrc2 = self.parse_register(instr.operands[2])

        if rdst is None or rsrc1 is None or rsrc2 is None:
            self.error(f"Invalid registers", instr.line_num)
            return [0]

        opcode = ISA.OPCODES[instr.mnemonic]
        return [self.pack_header(opcode, r1=rdst, r2=rsrc1, r3=rsrc2)]

    def _validate_and_mask_16bit(self, val: int, line_num: int) -> int:
        """
        Validates that val fits in 16 bits (signed or unsigned)
        and returns the 16-bit mask for processing.
        Range: -32768 to 65535
        """
        if not (-32768 <= val <= 65535):
            self.error(f"Immediate value {val} out of 16-bit range", line_num)
            return 0

        # Mask to 16 bits to handle negative numbers correctly for sign extension
        # e.g., -5 (Python) -> ...11111011 & 0xFFFF -> 0xFFFB
        return val & 0xFFFF

    def encode_immediate_instruction(self, instr: Instruction) -> List[int]:
        opcode = ISA.OPCODES[instr.mnemonic]

        if instr.mnemonic == 'IADD':
            if len(instr.operands) < 3:
                self.error(f"IADD requires 3 operands", instr.line_num)
                return [0, 0]
            rdst = self.parse_register(instr.operands[0])
            rsrc = self.parse_register(instr.operands[1])
            imm = self.parse_number(instr.operands[2])

            if rdst is None or rsrc is None or imm is None:
                self.error("Invalid operands for IADD", instr.line_num)
                return [0, 0]

            imm_masked = self._validate_and_mask_16bit(imm, instr.line_num)

            w1 = self.pack_header(opcode, r1=rdst, r2=rsrc)
            w2 = self.sign_extend_16bit(imm_masked) & 0xFFFFFFFF
            return [w1, w2]

        elif instr.mnemonic == 'LDM':
            if len(instr.operands) < 2:
                self.error(f"LDM requires 2 operands", instr.line_num)
                return [0, 0]
            rdst = self.parse_register(instr.operands[0])
            imm = self.parse_number(instr.operands[1])

            if rdst is None or imm is None:
                self.error("Invalid operands for LDM", instr.line_num)
                return [0, 0]

            imm_masked = self._validate_and_mask_16bit(imm, instr.line_num)

            w1 = self.pack_header(opcode, r1=rdst)
            w2 = self.sign_extend_16bit(imm_masked) & 0xFFFFFFFF
            return [w1, w2]

        return [0, 0]

    def encode_memory_offset(self, instr: Instruction) -> List[int]:
        opcode = ISA.OPCODES[instr.mnemonic]

        if len(instr.operands) < 2:
            self.error(f"{instr.mnemonic} requires 2 operands", instr.line_num)
            return [0, 0]

        if instr.mnemonic == 'LDD':
            rdst = self.parse_register(instr.operands[0])
            offset_reg = self.parse_offset_operand(instr.operands[1])
            if rdst is None or offset_reg is None:
                self.error("Invalid operands for LDD", instr.line_num)
                return [0, 0]
            offset, rsrc = offset_reg

            offset_masked = self._validate_and_mask_16bit(
                offset, instr.line_num)

            w1 = self.pack_header(opcode, r1=rdst, r2=rsrc)
            w2 = self.sign_extend_16bit(offset_masked) & 0xFFFFFFFF
            return [w1, w2]

        elif instr.mnemonic == 'STD':
            rsrc1 = self.parse_register(instr.operands[0])
            offset_reg = self.parse_offset_operand(instr.operands[1])
            if rsrc1 is None or offset_reg is None:
                self.error("Invalid operands for STD", instr.line_num)
                return [0, 0]
            offset, rsrc2 = offset_reg

            offset_masked = self._validate_and_mask_16bit(
                offset, instr.line_num)

            w1 = self.pack_header(opcode, r1=rsrc1, r2=rsrc2)
            w2 = self.sign_extend_16bit(offset_masked) & 0xFFFFFFFF
            return [w1, w2]

        return [0, 0]

    def encode_branch(self, instr: Instruction) -> List[int]:
        if len(instr.operands) < 1:
            self.error(f"{instr.mnemonic} requires 1 operand", instr.line_num)
            return [0, 0]

        target = instr.operands[0]
        if target in self.symbol_table:
            imm = self.symbol_table[target]
        else:
            imm = self.parse_number(target)
            if imm is None:
                self.error(f"Invalid target '{target}'", instr.line_num)
                return [0, 0]

        # Check for address bit width validity (18-bit)
        if imm >= ISA.MEMORY_WORDS or imm < 0:
            self.error(
                f"Branch target {imm:X} exceeds 18-bit memory space", instr.line_num)

        opcode = ISA.OPCODES[instr.mnemonic]
        w1 = self.pack_header(opcode)
        w2 = imm & 0xFFFFFFFF
        return [w1, w2]

    def encode_interrupt(self, instr: Instruction) -> List[int]:
        if len(instr.operands) < 1:
            self.error(f"INT requires 1 operand", instr.line_num)
            return [0]

        index = self.parse_number(instr.operands[0])
        opcode = ISA.OPCODES['INT']
        return [self.pack_header(opcode, r1=index)]

    def encode_instruction(self, instr: Instruction) -> List[int]:
        mnemonic = instr.mnemonic

        if mnemonic in ISA.ONE_OPERAND_INSTRUCTIONS:
            return self.encode_one_operand(instr)
        elif mnemonic in ISA.TWO_OPERAND_INSTRUCTIONS:
            return self.encode_two_operand(instr)
        elif mnemonic in ISA.THREE_OPERAND_INSTRUCTIONS:
            return self.encode_three_operand(instr)
        elif mnemonic in ISA.IMMEDIATE_INSTRUCTIONS:
            return self.encode_immediate_instruction(instr)
        elif mnemonic in ISA.MEMORY_OFFSET_INSTRUCTIONS:
            return self.encode_memory_offset(instr)
        elif mnemonic in ISA.BRANCH_INSTRUCTIONS:
            return self.encode_branch(instr)
        elif mnemonic == 'INT':
            return self.encode_interrupt(instr)
        else:
            self.error(f"Unknown encoding for {mnemonic}", instr.line_num)
            return [0]

    def second_pass(self):
        self.log("Starting second pass...")
        for instr in self.instructions:
            machine_code = self.encode_instruction(instr)
            instr.machine_code = machine_code

            # Format output
            hex_codes = " ".join([f"{w:08X}" for w in machine_code])
            ops_str = ", ".join(instr.operands)
            self.log(
                f"Addr {instr.address:05X}: {instr.mnemonic:5s} {ops_str:15s} -> {hex_codes}")

    def assemble(self, input_file: str) -> bool:
        try:
            with open(input_file, 'r') as f:
                lines = f.readlines()
        except FileNotFoundError:
            self.error(f"Input file '{input_file}' not found")
            return False

        self.first_pass(lines)
        if self.errors:
            return False
        self.second_pass()
        return len(self.errors) == 0

    def generate_output(self, output_file: str, format_type: str = 'hex', start_address: int = 0):
        self.log(
            f"Generating output file: {output_file} (format: {format_type})")

        memory = {}
        for instr in self.instructions:
            addr = instr.address + start_address
            for word in instr.machine_code:
                memory[addr] = word
                addr += 1

        with open(output_file, 'w') as f:
            if format_type == 'hex':
                for addr in sorted(memory.keys()):
                    f.write(f"{addr:05X}: {memory[addr]:08X}\n")

            elif format_type == 'bin':
                for addr in sorted(memory.keys()):
                    f.write(f"{addr:032b}: {memory[addr]:032b}\n")

            elif format_type == 'mem':
                if memory:
                    max_addr = max(memory.keys())
                    for addr in range(max_addr + 1):
                        val = memory.get(addr, 0)
                        f.write(f"{val:08X}\n")

        self.log(f"Output written successfully")

    def print_symbol_table(self):
        if self.symbol_table:
            print("\n=== Symbol Table ===")
            for label, addr in sorted(self.symbol_table.items(), key=lambda x: x[1]):
                print(f"{label:20s} -> {addr:05X}")

    def print_errors(self):
        if self.errors:
            print("\n=== Errors ===")
            for error in self.errors:
                print(f"ERROR: {error}")


def main():
    import argparse
    parser = argparse.ArgumentParser(
        prog="assembler",
        description="Assembler for 5-stage pipelined RISC processor (1MB 18-bit Addr)"
    )
    parser.add_argument('input_file', type=str,
                        help='Input assembly file (.asm)')
    parser.add_argument('-o', '--output', type=str,
                        default='output.mem', help='Output file')
    parser.add_argument('-f', '--format', type=str,
                        choices=['hex', 'bin', 'mem'], default='mem', help='Output format')
    parser.add_argument('-v', '--verbose',
                        action='store_true', help='Verbose output')
    parser.add_argument('--start-address', type=lambda x: int(x,
                        0), default=0, help='Starting address')

    args = parser.parse_args()
    assembler = Assembler(verbose=args.verbose)

    if assembler.assemble(args.input_file):
        assembler.generate_output(args.output, args.format, args.start_address)
        if args.verbose:
            assembler.print_symbol_table()
        print(f"\n✓ Assembly successful!")
        print(f"  Input:  {args.input_file}")
        print(f"  Output: {args.output}")
        print(f"  Instructions: {len(assembler.instructions)}")
    else:
        assembler.print_errors()
        sys.exit(1)


if __name__ == "__main__":
    main()
