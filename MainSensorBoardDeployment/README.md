# MainSensorBoardDeployment Application

`MainSensorBoardDeployment` is the baremetal F' deployment for the Raspberry Pi Pico W on the AMSAT® CubeSat Simulator Main Board. It is built with the Arduino toolchain through [fprime-arduino](https://github.com/fprime-community/fprime-arduino) and only builds for Arduino targets (`rpipicow` by default).

## Topology

- **Scheduling**: `Arduino.HardwareRateDriver` ticks every 1 ms. `Svc.RateGroupDriver` divides it down to a 10 Hz passive rate group (`rateGroup10Hz`) that runs telemetry, system resources, and the serial driver. Active components run cooperatively under the `fprime-baremetal` TaskRunner from the Arduino `loop()`.
- **Command and data handling**: `Svc.CommandDispatcher`, `Svc.EventManager`, `Svc.TlmChan`, `Svc.PassiveTextLogger`, `Baremetal.FatalHandler`, `Arduino.ArduinoTime`, `Svc.SystemResources`.
- **Communications**: the F' core **ComFprime** subtopology (F' framing, matching the CDHDeployment) over `Arduino.StreamDriver` on the Pico W USB serial port at 115200 baud.
- **No filesystem**: there is no file uplink/downlink, command sequencer, or parameter database. Parameters are not loaded at startup.

Deployment configuration (buffer sizes, queue depths, port counts) is in [config/](config/). Component base IDs start with `0x1` so they do not collide with the CDHDeployment; see [Top/instances.fpp](Top/instances.fpp).

## Building

From the project virtual environment:

```sh
cd MainSensorBoardDeployment
fprime-util generate
fprime-util build
```

`rpipicow` is the default toolchain in `settings.ini`, so it does not need to be passed on the command line.

## Uploading to the Pico W

Hold down the BOOTSEL button on the Pico W as you plug in the USB cable. A drive named `RPI-RP2` mounts on your computer. Copy `MainSensorBoardDeployment.elf.uf2` from `build-artifacts/rpipicow/MainSensorBoardDeployment/bin/` (at the project root) onto that drive. The Pico W unmounts and starts running the deployment.

See the fprime-arduino [RP2040 upload guide](https://github.com/fprime-community/fprime-arduino/blob/main/docs/uploading/rp2040_2350.md) for an alternative upload method over the serial port.

## Running the F' GDS

From the project root, with the Pico W connected over USB:

```sh
fprime-gds -n --dictionary build-artifacts/rpipicow/MainSensorBoardDeployment/dict/MainSensorBoardDeploymentTopologyDictionary.json --framing-selection fprime --communication-selection uart --uart-device /dev/ttyACM0 --uart-baud 115200
```

> [!NOTE]
> `--framing-selection fprime` is required. The Pico W uses F' framing, and the GDS defaults to CCSDS framing.
>
> `/dev/ttyACM0` may differ on your system. Run `ls /dev/tty*` with the Pico W unplugged and plugged in to find it. On macOS it is similar to `/dev/tty.usbmodem12345`.
>
> Log text (`Fw::Logger` and the text event logger) is written to the same USB serial port as the F' frames. The GDS skips the non-frame bytes.

## Testing

Run these from the project root in the project virtual environment, after building the deployment.

| Tests | What they cover | Command |
|---|---|---|
| Host | Dictionary ID ranges, expected commands and telemetry, and static RAM and flash budgets | `python -m pytest MainSensorBoardDeployment/test/host` |
| Hardware | The deployment running on a Pico W: telemetry, commands, and the 10 Hz rate group | `MainSensorBoardDeployment/test/int/run-hardware-tests.sh [/dev/ttyACM0]` |

[CI](../.github/workflows/ci.yml) builds the firmware and runs the host checks on every push and pull request, and saves the `.uf2` as a build artifact. The hardware tests need a flashed Pico W connected over USB and are run by hand. Close any other GDS or serial monitor using the port first.
