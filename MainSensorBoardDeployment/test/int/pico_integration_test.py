"""pico_integration_test.py:

Hardware tests for the MainSensorBoardDeployment, run against a Pico W connected over USB through the F' GDS. Run them
with run-hardware-tests.sh.
"""

import time

DEPLOYMENT = "MainSensorBoardDeployment"
COMMANDER = f"{DEPLOYMENT}.cmdDisp"


def test_is_streaming(fprime_test_api):
    """Telemetry arrives from the Pico W"""
    fprime_test_api.assert_telemetry_count(5, timeout=10)


def test_no_op(fprime_test_api):
    """A NO_OP command is dispatched and completes"""
    fprime_test_api.send_and_assert_command(f"{COMMANDER}.CMD_NO_OP", max_delay=1.0, commander=COMMANDER)


def test_system_resources(fprime_test_api):
    """systemResources reports CPU telemetry"""
    fprime_test_api.assert_telemetry(f"{DEPLOYMENT}.systemResources.CPU", timeout=5)


def test_10hz_rate_group(fprime_test_api):
    """rateGroup10Hz completes about 10 cycles per second"""
    channel = f"{DEPLOYMENT}.rateGroup10Hz.CycleCount"
    first = fprime_test_api.await_telemetry(channel, timeout=5)
    assert first is not None, f"{channel} not received"
    first_time = time.monotonic()

    time.sleep(5)
    last = fprime_test_api.await_telemetry(channel, timeout=5)
    assert last is not None, f"{channel} not received"
    elapsed = time.monotonic() - first_time

    rate = (last.get_val() - first.get_val()) / elapsed
    assert 8 <= rate <= 12, f"rateGroup10Hz ran at {rate:.1f} Hz"
