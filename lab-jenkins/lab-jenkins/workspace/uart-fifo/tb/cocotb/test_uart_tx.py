"""Tests unitaires de l'émetteur UART 8N1 (rtl/uart_tx.v)."""
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge

CLK_HZ = 100_000_000
BAUD = int(os.environ.get("BAUD", "115200"))
DIV = CLK_HZ // BAUD                      # cycles d'horloge par bit


async def demarrer(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    dut.start.value = 0
    dut.data.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 0


@cocotb.test()
async def ligne_au_repos(dut):
    """La ligne TX reste à 1 tant que rien n'est émis."""
    await demarrer(dut)
    await ClockCycles(dut.clk, 20)
    assert dut.tx.value == 1
    assert dut.busy.value == 0


@cocotb.test()
async def trame_8n1(dut):
    """Start à 0, 8 bits de données LSB en premier, stop à 1."""
    await demarrer(dut)
    octet = 0xA5
    dut.data.value = octet
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    await FallingEdge(dut.tx)                 # front du bit de start
    await ClockCycles(dut.clk, DIV // 2)      # échantillonnage au milieu du bit
    bits = []
    for _ in range(10):
        bits.append(int(dut.tx.value))
        await ClockCycles(dut.clk, DIV)

    assert bits[0] == 0, "bit de start"
    assert bits[9] == 1, "bit de stop"
    recu = sum(b << i for i, b in enumerate(bits[1:9]))
    assert recu == octet, f"reçu {recu:#04x}, attendu {octet:#04x}"
