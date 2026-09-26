"""test_build.py:

Checks of the MainSensorBoardDeployment build outputs that run on the development computer, without a Pico W.
Build the deployment first (cd MainSensorBoardDeployment && fprime-util generate && fprime-util build), then run:

    pytest MainSensorBoardDeployment/test/host

Set PICO_ARTIFACTS to check a build other than the default rpipicow build.
"""

import json
import os
import struct
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[3]
DEPLOYMENT = "MainSensorBoardDeployment"

# All IDs in this deployment start with 0x1 so they never collide with the CDHDeployment on the Pi Zero 2
ID_RANGE = range(0x10000000, 0x20000000)
# ComFprimeConfig.BASE_ID: the ComFprime subtopology's IDs
COM_FPRIME_RANGE = range(0x10100000, 0x10200000)

# Raspberry Pi Pico W (RP2040) memory, and the budgets this deployment must stay within
PICO_W_RAM = 264 * 1024
PICO_W_FLASH = 2 * 1024 * 1024
RAM_BUDGET = 200 * 1024  # static RAM (.data, .bss) at last check: ~97 KiB
FLASH_BUDGET = 1536 * 1024  # flash image at last check: ~205 KiB

# Sections the linker sizes to fill the remaining RAM, which are not used by the deployment itself
RAM_RESERVATIONS = {".heap", ".stack_dummy", ".stack1_dummy"}
RP2040_RAM = range(0x20000000, 0x20000000 + PICO_W_RAM)


def artifact(*parts):
    """Return a build output path, failing with build instructions if it does not exist"""
    root = Path(os.environ.get("PICO_ARTIFACTS", PROJECT_ROOT / "build-artifacts" / "rpipicow" / DEPLOYMENT))
    path = root.joinpath(*parts)
    if not path.exists():
        pytest.fail(f"{path} not found. Build {DEPLOYMENT} first, or set PICO_ARTIFACTS.")
    return path


@pytest.fixture(scope="module")
def dictionary():
    return json.loads(artifact("dict", f"{DEPLOYMENT}TopologyDictionary.json").read_text())


@pytest.fixture(scope="module")
def sections():
    """ELF sections of the firmware as {name: (address, size, allocated, has_contents)}"""
    elf = artifact("bin", f"{DEPLOYMENT}.elf").read_bytes()
    assert elf[:4] == b"\x7fELF" and elf[4] == 1 and elf[5] == 1, "expected a 32-bit little-endian ELF"
    section_offset, = struct.unpack_from("<I", elf, 0x20)
    entry_size, count, names_index = struct.unpack_from("<HHH", elf, 0x2E)

    headers = [struct.unpack_from("<IIIIIIIIII", elf, section_offset + i * entry_size) for i in range(count)]
    names_offset = headers[names_index][4]

    def name(offset):
        start = names_offset + offset
        return elf[start : elf.index(b"\0", start)].decode()

    SHF_ALLOC, SHT_NOBITS = 0x2, 8
    return {
        name(h[0]): (h[3], h[5], bool(h[2] & SHF_ALLOC), h[1] != SHT_NOBITS)
        for h in headers
        if h[0]
    }


def all_ids(dictionary):
    """(name, id) for every command, event, channel, and parameter"""
    for kind, field in (("commands", "opcode"), ("events", "id"), ("telemetryChannels", "id"), ("parameters", "id")):
        for item in dictionary[kind]:
            yield item["name"], item[field]


def test_ids_in_deployment_range(dictionary):
    """Every ID starts with 0x1, keeping it distinct from the CDHDeployment's IDs"""
    outside = [f"{name}={hex(value)}" for name, value in all_ids(dictionary) if value not in ID_RANGE]
    assert not outside, f"IDs outside 0x1xxxxxxx: {outside}"


def test_com_fprime_ids_in_subtopology_range(dictionary):
    """ComFprime subtopology IDs come from ComFprimeConfig.BASE_ID, and no other component uses that range"""
    for name, value in all_ids(dictionary):
        in_subtopology = name.startswith("ComFprime.")
        assert (value in COM_FPRIME_RANGE) == in_subtopology, f"{name}={hex(value)}"


def test_expected_interface(dictionary):
    """Commands and telemetry that the ground and hardware tests rely on are present"""
    commands = {command["name"] for command in dictionary["commands"]}
    channels = {channel["name"] for channel in dictionary["telemetryChannels"]}
    assert f"{DEPLOYMENT}.cmdDisp.CMD_NO_OP" in commands
    for channel in ("CycleCount", "CycleTime", "MaxCycleTime"):
        assert f"{DEPLOYMENT}.rateGroup10Hz.{channel}" in channels
    assert f"{DEPLOYMENT}.systemResources.CPU" in channels


def test_static_ram_within_budget(sections):
    """Statically allocated RAM leaves room for the heap on the Pico W"""
    static_ram = sum(
        size
        for name, (address, size, allocated, _) in sections.items()
        if allocated and address in RP2040_RAM and name not in RAM_RESERVATIONS
    )
    assert static_ram < RAM_BUDGET, f"static RAM {static_ram} bytes exceeds budget {RAM_BUDGET}"


def test_flash_within_budget(sections):
    """The flash image (code, constants, and initial values of .data) fits the budget"""
    flash = sum(size for address, size, allocated, has_contents in sections.values() if allocated and has_contents)
    assert flash < FLASH_BUDGET, f"flash image {flash} bytes exceeds budget {FLASH_BUDGET}"
    assert FLASH_BUDGET < PICO_W_FLASH
