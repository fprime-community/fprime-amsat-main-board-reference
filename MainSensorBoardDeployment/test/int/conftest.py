"""conftest.py: shared setup for the MainSensorBoardDeployment hardware tests"""

import pytest


@pytest.fixture(scope="session", autouse=True)
def pico_running(fprime_test_api_session):
    """Wait for the Pico W to start sending telemetry before any test runs"""
    if not fprime_test_api_session.await_telemetry_count(1, timeout=20):
        pytest.exit("The Pico W did not send telemetry within 20 s. Is it flashed, connected, and on the right port?")
