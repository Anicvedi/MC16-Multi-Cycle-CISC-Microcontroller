#!/usr/bin/env python3
"""
Assembler for 16-bit Multi-Cycle MC16 Processor
Course: E3: 245 Processor System Design, IISc DESE
Target: 64 x 16-bit Distributed RAM
"""

import sys
import os

OPCODES = {
    'NOP':   0b00000,
    'ADD':   0b00001,
    'SUB':   0b00010,
    'INCR':  0b00011,
    'DECR':  0b00100,
    'SHL':   0b00101,
    'RRC':   0b00110,
    'AND':   0b00111,
    'OR':    0b01000,
    'LOAD':  0b01001,
    'STORE': 0b01010,
    'JMP':   0b01011,
    'JZ':    0b01100,
    'JNZ':   0b01101,
    'JC':    0b01110,
    'JNC':   0b01111,
}

REGISTERS = {
    'R0': 0, 'R1': 1, 'R2': 2, 'R3': 3,
    'R4': 4, 'R5': 5, 'R6': 6, 'R7': 7,
}

def parse_reg(reg_str):
    reg_str = reg_str.strip().upper()
    if reg_str in REGISTERS:
        return REGISTERS[reg_str]
    raise ValueError(f"Invalid register: {reg_str}")

def parse_addr(addr_str):
    addr_str = addr_str.strip()
    if addr_str.startswith('[') and addr_str.endswith(']'):
        addr_str = addr_str[1:-1].strip()
    if addr_str.startswith('0x') or addr_str.startswith('0X'):
        return int(addr_str, 16)
    return int(addr_str, 10)

def assemble_line(line, labels, current_addr):
    line = line.split(';')[0].strip()
    if not line:
        return None
    
    # Check for label
    if ':' in line:
        parts = line.split(':', 1)
        line = parts[1].strip()
        if not line:
            return None

    tokens = [t.strip() for t in line.replace(',', ' ').split()]
    mnemonic = tokens[0].upper()

    if mnemonic == 'DATA':
        # Direct data constant
        val = parse_addr(tokens[1])
        return val & 0xFFFF

    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown mnemonic: {mnemonic}")

    op = OPCODES[mnemonic]

    if mnemonic in ['ADD', 'SUB', 'AND', 'OR']:
        # Format: OP rd, rs2, rs1 or OP rd, rs1, rs2
        # As per PDF: [Opcode: 5][rd: 3][rs2: 3][rs1: 3][x: 2]
        # rd = tokens[1], rs1 = tokens[2], rs2 = tokens[3]
        # In mathematical convention: rd = rs1 - rs2.
        # So rs1 is first source, rs2 is second source.
        rd = parse_reg(tokens[1])
        rs1 = parse_reg(tokens[2])
        rs2 = parse_reg(tokens[3])
        # Format: Op[15:11], rd[10:8], rs2[7:5], rs1[4:2], x[1:0]
        word = (op << 11) | (rd << 8) | (rs2 << 5) | (rs1 << 2) | 0
        return word

    elif mnemonic in ['INCR', 'DECR', 'SHL', 'RRC']:
        # Format: [Opcode: 5][rd: 3][x: 3][x: 3][x: 2]
        rd = parse_reg(tokens[1])
        word = (op << 11) | (rd << 8)
        return word

    elif mnemonic == 'LOAD':
        # Format: [Opcode: 5][rd: 3][x: 3][A[4:2]: 3][A[1:0]: 2] -> A is bits [4:0]
        rd = parse_reg(tokens[1])
        target = tokens[2]
        addr = labels[target] if target in labels else parse_addr(target)
        word = (op << 11) | (rd << 8) | (addr & 0x1F)
        return word

    elif mnemonic == 'STORE':
        # Format: [Opcode: 5][x: 3][rs2: 3][A[4:2]: 3][A[1:0]: 2] -> rs2 at [7:5], A at [4:0]
        # STORE [Addr], rs2  or STORE rs2, [Addr]
        if tokens[1].startswith('[') or tokens[1] in labels or tokens[1].isdigit():
            target = tokens[1]
            rs2 = parse_reg(tokens[2])
        else:
            rs2 = parse_reg(tokens[1])
            target = tokens[2]
        addr = labels[target] if target in labels else parse_addr(target)
        word = (op << 11) | (rs2 << 5) | (addr & 0x1F)
        return word

    elif mnemonic in ['JMP', 'JZ', 'JNZ', 'JC', 'JNC']:
        # Format: [Opcode: 5][x: 3][x: 3][A[4:2]: 3][A[1:0]: 2] -> A at [4:0]
        target = tokens[1]
        addr = labels[target] if target in labels else parse_addr(target)
        word = (op << 11) | (addr & 0x1F)
        return word

    elif mnemonic == 'NOP':
        return 0x0000

    else:
        raise ValueError(f"Unhandled instruction: {mnemonic}")

def assemble_file(asm_path, coe_path, mem_path):
    with open(asm_path, 'r') as f:
        lines = f.readlines()

    # Pass 1: find labels and addresses
    labels = {}
    instructions = []
    current_addr = 0

    for raw_line in lines:
        line = raw_line.split(';')[0].strip()
        if not line:
            continue
        # Check if line has an address directive, e.g. @26 or ORG 26
        if line.startswith('@') or line.upper().startswith('ORG'):
            val_str = line[1:].strip() if line.startswith('@') else line.split()[1].strip()
            current_addr = int(val_str, 16 if '0x' in val_str.lower() else 10)
            continue

        if ':' in line:
            label, rest = line.split(':', 1)
            labels[label.strip()] = current_addr
            line = rest.strip()

        if line:
            instructions.append((current_addr, line))
            current_addr += 1

    # Pass 2: assemble
    memory = [0] * 64
    for addr, line in instructions:
        if addr >= 64:
            raise ValueError(f"Address {addr} exceeds 64-word memory limit!")
        word = assemble_line(line, labels, addr)
        if word is not None:
            memory[addr] = word

    # Write .mem file (hex entries for $readmemh)
    with open(mem_path, 'w') as f:
        for i, word in enumerate(memory):
            f.write(f"{word:04X}\n")

    # Write .coe file for Vivado
    with open(coe_path, 'w') as f:
        f.write("; MC16 Processor Memory Initialization File\n")
        f.write("; Course: E3: 245 Processor System Design, IISc DESE\n")
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        hex_strs = [f"{w:04X}" for w in memory]
        f.write(",\n".join(hex_strs) + ";\n")

    print(f"Assembly successful! Generated:\n  {mem_path}\n  {coe_path}")
    print(f"Labels: {labels}")
    for i, w in enumerate(memory[:32]):
        if w != 0:
            print(f"  [{i:02d}] 0x{w:04X}")

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("Usage: assemble.py <input.asm> <output.coe> <output.mem>")
        sys.exit(1)
    assemble_file(sys.argv[1], sys.argv[2], sys.argv[3])
