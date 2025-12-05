import sys
# Relative imports because we are now in the 'assembler' package
from .isa import ISA
from .assembler import Assembler


class RISC_Simulator:
    def __init__(self):
        self.memory = {}
        self.regs = [0] * 8
        self.pc = 0
        self.sp = ISA.INITIAL_SP
        self.ccr = 0  # X-C-N-Z
        self.halted = False
        self.cycles = 0
        self.max_cycles = 5000

    def load_machine_code(self, instructions):
        for instr in instructions:
            addr = instr.address
            for word in instr.machine_code:
                self.memory[addr] = word
                addr += 1

    def get_mem(self, addr):
        return self.memory.get(addr & (ISA.MEMORY_WORDS - 1), 0)

    def set_mem(self, addr, value):
        self.memory[addr & (ISA.MEMORY_WORDS - 1)] = value & 0xFFFFFFFF

    def update_flags(self, result, carry_out=False):
        res32 = result & 0xFFFFFFFF
        z = 1 if res32 == 0 else 0
        n = 1 if (res32 & 0x80000000) else 0
        c = 1 if carry_out else 0
        self.ccr = (self.ccr & ~0b111) | (c << 2) | (n << 1) | z

    def get_flag_z(self): return self.ccr & 1
    def get_flag_n(self): return (self.ccr >> 1) & 1
    def get_flag_c(self): return (self.ccr >> 2) & 1
    def set_flag_c(self): self.ccr |= 4

    def step(self):
        if self.halted:
            return
        ir_addr = self.pc
        op_word = self.get_mem(self.pc)
        self.pc += 1

        opcode = (op_word >> 27) & 0x1F
        r1, r2, r3 = (op_word >> 24) & 7, (op_word >>
                                           21) & 7, (op_word >> 18) & 7

        mnemonic = next(
            (k for k, v in ISA.OPCODES.items() if v == opcode), None)
        if not mnemonic:
            print(f"Runtime Error: Bad Opcode {opcode:X} at {ir_addr:X}")
            self.halted = True
            return

        imm_val = 0
        if ISA.get_size(mnemonic) == 2:
            imm_val = self.get_mem(self.pc)
            # Python Logic: Convert 32-bit hex to signed int
            if imm_val & 0x80000000:
                imm_val -= 0x100000000
            self.pc += 1

        if mnemonic == 'NOP':
            pass
        elif mnemonic == 'HLT':
            self.halted = True
        elif mnemonic == 'SETC':
            self.set_flag_c()
        elif mnemonic == 'NOT':
            res = ~self.regs[r1]
            self.regs[r1] = res & 0xFFFFFFFF
            self.update_flags(res)
        elif mnemonic == 'INC':
            res = self.regs[r1] + 1
            self.regs[r1] = res & 0xFFFFFFFF
            self.update_flags(res, carry_out=(res > 0xFFFFFFFF))
        elif mnemonic == 'OUT':
            print(f"[SIM OUT] Port Write: {self.regs[r1]:X}")
        elif mnemonic == 'IN':
            self.regs[r1] = 0
        elif mnemonic == 'MOV':
            self.regs[r1] = self.regs[r2]
        elif mnemonic == 'SWAP':
            self.regs[r1], self.regs[r2] = self.regs[r2], self.regs[r1]
        elif mnemonic == 'ADD':
            res = self.regs[r2] + self.regs[r3]
            self.regs[r1] = res & 0xFFFFFFFF
            self.update_flags(res, carry_out=(res > 0xFFFFFFFF))
        elif mnemonic == 'SUB':
            op1, op2 = self.regs[r2], self.regs[r3]
            res = op1 - op2
            self.regs[r1] = res & 0xFFFFFFFF
            self.update_flags(res, carry_out=(op1 >= op2))
        elif mnemonic == 'AND':
            res = self.regs[r2] & self.regs[r3]
            self.regs[r1] = res & 0xFFFFFFFF
            self.update_flags(res, carry_out=False)
        elif mnemonic == 'IADD':
            op1 = self.regs[r2]
            res = op1 + imm_val
            self.regs[r1] = res & 0xFFFFFFFF
            self.update_flags(res, carry_out=(res > 0xFFFFFFFF)
                              or (res < 0))  # Approximate check
        elif mnemonic == 'LDM':
            self.regs[r1] = imm_val & 0xFFFFFFFF
        elif mnemonic == 'PUSH':
            self.set_mem(self.sp, self.regs[r1])
            self.sp = (self.sp - 1) & 0x3FFFF
        elif mnemonic == 'POP':
            self.sp = (self.sp + 1) & 0x3FFFF
            self.regs[r1] = self.get_mem(self.sp)
        elif mnemonic == 'STD':
            addr = self.regs[r2] + imm_val
            self.set_mem(addr, self.regs[r1])
        elif mnemonic == 'LDD':
            addr = self.regs[r2] + imm_val
            self.regs[r1] = self.get_mem(addr)
        elif mnemonic == 'JMP':
            self.pc = imm_val & (ISA.MEMORY_WORDS - 1)
        elif mnemonic == 'JZ':
            if self.get_flag_z():
                self.pc = imm_val & (ISA.MEMORY_WORDS - 1)
        elif mnemonic == 'JN':
            if self.get_flag_n():
                self.pc = imm_val & (ISA.MEMORY_WORDS - 1)
        elif mnemonic == 'JC':
            if self.get_flag_c():
                self.pc = imm_val & (ISA.MEMORY_WORDS - 1)
        elif mnemonic == 'CALL':
            self.set_mem(self.sp, self.pc)
            self.sp = (self.sp - 1) & 0x3FFFF
            self.pc = imm_val & (ISA.MEMORY_WORDS - 1)
        elif mnemonic == 'RET':
            self.sp = (self.sp + 1) & 0x3FFFF
            self.pc = self.get_mem(self.sp)
        elif mnemonic == 'INT':
            self.set_mem(self.sp, self.pc)
            self.sp = (self.sp - 1) & 0x3FFFF
            self.pc = self.get_mem(r1 + 2)
        elif mnemonic == 'RTI':
            self.sp = (self.sp + 1) & 0x3FFFF
            self.pc = self.get_mem(self.sp)

        self.cycles += 1
        if self.cycles >= self.max_cycles:
            self.halted = True

    def run(self):
        while not self.halted:
            self.step()

    def dump_memory(self, filepath):
        with open(filepath, 'w') as f:
            for a in sorted(self.memory.keys()):
                f.write(f"{a:05X}: {self.memory[a]:08X}\n")

# Logic to solve a specific file and return success


def solve_asm(asm_file, output_mem):
    assembler = Assembler(verbose=False)
    if not assembler.assemble(asm_file):
        return False
    sim = RISC_Simulator()
    sim.load_machine_code(assembler.instructions)
    sim.run()
    sim.dump_memory(output_mem)
    return True


if __name__ == "__main__":
    # Allow running simulator directly
    import argparse
    parser = argparse.ArgumentParser(description="RISC Simulator")
    parser.add_argument('input', help='Input .asm file')
    parser.add_argument('output', help='Output .mem file')
    args = parser.parse_args()
    if solve_asm(args.input, args.output):
        print("Simulation Done")
    else:
        sys.exit(1)
