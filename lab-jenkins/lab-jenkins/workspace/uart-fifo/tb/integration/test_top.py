"""Test d'intégration du top-level : le design émet "HELLO\\r\\n" sur sa sortie UART.

Le top est compilé avec CLK_HZ = 1 152 000 et BAUD = 115 200, soit 10 cycles par bit,
pour que la simulation reste courte (voir la cible « integration » du Makefile).
"""
import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, with_timeout

DIV = int(os.environ.get("DIV", "10"))       # cycles d'horloge par bit


async def lire_octet(dut):
    await FallingEdge(dut.uart_txd)           # bit de start
    await ClockCycles(dut.clk, DIV // 2)
    assert dut.uart_txd.value == 0, "bit de start instable"
    octet = 0
    for i in range(8):
        await ClockCycles(dut.clk, DIV)
        octet |= int(dut.uart_txd.value) << i
    await ClockCycles(dut.clk, DIV)
    assert dut.uart_txd.value == 1, "bit de stop absent"
    return octet


@cocotb.test()
async def message_hello(dut):
    """Après le reset, la ligne série transporte HELLO\\r\\n."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    recu = bytearray()
    for _ in range(7):
        recu.append(await with_timeout(lire_octet(dut), 20, "us"))
    dut._log.info("Recu : %r", bytes(recu))
    assert bytes(recu) == b"HELLO\r\n"
