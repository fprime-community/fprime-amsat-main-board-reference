#!/usr/bin/env bash
# Runs the MainSensorBoardDeployment hardware tests against a Pico W connected over USB.
#
# Usage, from the project virtual environment after building and flashing the deployment:
#     MainSensorBoardDeployment/test/int/run-hardware-tests.sh [serial device] [extra pytest arguments]
#
# The serial device defaults to /dev/ttyACM0. GDS logs are kept for debugging when a test fails.
set -euo pipefail

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$TEST_DIR/../../.." && pwd)
ARTIFACTS="$PROJECT_ROOT/build-artifacts/rpipicow/MainSensorBoardDeployment"
DICTIONARY="$ARTIFACTS/dict/MainSensorBoardDeploymentTopologyDictionary.json"
DEVICE="${1:-/dev/ttyACM0}"
shift || true

if [[ ! -f "$DICTIONARY" ]]; then
    echo "Dictionary not found at $DICTIONARY." >&2
    echo "Build the deployment first: cd MainSensorBoardDeployment && fprime-util generate && fprime-util build" >&2
    exit 1
fi
if [[ ! -e "$DEVICE" ]]; then
    echo "Serial device $DEVICE not found. Connect the Pico W, or pass its device, e.g. $0 /dev/ttyACM1" >&2
    exit 1
fi

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pico-hw-XXXXXX")
GDS_PID=""

# Job control starts the GDS in its own process group without ignoring SIGINT, as background jobs otherwise do in
# scripts, so it can be stopped cleanly
set -m

stop_gds() {
    if [[ -n "$GDS_PID" ]] && kill -0 "$GDS_PID" 2>/dev/null; then
        # SIGINT lets the GDS shut down cleanly
        kill -INT "$GDS_PID"
        for _ in $(seq 20); do
            kill -0 "$GDS_PID" 2>/dev/null || break
            sleep 0.5
        done
        # If it is still running, stop its whole process group
        kill -TERM -- "-$GDS_PID" 2>/dev/null || true
        wait "$GDS_PID" 2>/dev/null || true
    fi
}
trap stop_gds EXIT

fprime-gds --gui none --no-app --dictionary "$DICTIONARY" \
    --framing-selection fprime --communication-selection uart --uart-device "$DEVICE" --uart-baud 115200 \
    --logs "$WORK_DIR/logs" --file-storage-directory "$WORK_DIR/files" \
    > "$WORK_DIR/gds.out" 2>&1 &
GDS_PID=$!

status=0
python -m pytest "$TEST_DIR" \
    --dictionary "$DICTIONARY" --file-storage-directory "$WORK_DIR/files" --logs "$WORK_DIR/pytest-logs" \
    "$@" || status=$?

stop_gds
trap - EXIT
if [[ $status -eq 0 ]]; then
    rm -rf "$WORK_DIR"
else
    echo "Hardware tests failed. GDS logs are in $WORK_DIR" >&2
fi
exit $status
