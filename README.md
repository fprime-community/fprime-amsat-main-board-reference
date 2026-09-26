# Welcome to F Prime's Reference Repo for the AMSAT® CubeSat Simulator Main Board

<img width="300" alt="CubeSatSim v2" src="https://CubeSatSim.org/v2/cubesatsim%20v2%20complete.png">

This Git Repo contains the F' reference repository for the Raspberry Pi Pico W on the Main (STEM Payload) Board of the AMSAT® CubeSat Simulator.

## F' Framework Overview
F´ (F Prime) is an open-source, component-driven software framework developed by NASA’s Jet Propulsion Laboratory (JPL) for rapid development and deployment of embedded systems and spaceflight applications. It is designed to simplify the creation of flight-quality software, particularly for small-scale missions like CubeSats, SmallSats, instruments, and deployables, but it can be used for any embedded system.

## AMSAT® CubeSat Simulator Overview
The CubeSatSim(TM) is a low cost satellite emulator that runs on solar panels and batteries, transmits UHF radio telemetry, has a 3D printed frame, and can be extended by additional sensors and modules.  This project is sponsored by the not-for-profit [Radio Amateur Satellite Corporation, AMSAT®](https://amsat.org).

The [CubeSatSim kit](https://github.com/alanbjohnston/CubeSatSim/wiki/Kit) contains two processors:
- A **Raspberry Pi Zero 2** running Linux, with the Pi Camera attached.
- A **Raspberry Pi Pico W** (RP2040) mounted on the Main (STEM Payload) Board.

## AMSAT® CubeSat Simulator Hardware Block Diagram
![CubeSatSim Block Diagram](https://github.com/user-attachments/assets/a09086b9-2a05-4b4e-91a7-f8360718b6ce)

## AMSAT® CubeSat Simulator Deployments
There are two F' deployments for the AMSAT® CubeSat, each in its own Git Repo:

| Deployment | Processor | Repo |
|---|---|---|
| CDHDeployment | Raspberry Pi Zero 2 (Linux). Manages command and telemetry of the CubeSat and the Pi Camera. | [fprime-amsat-reference](https://github.com/fprime-community/fprime-amsat-reference) |
| MainSensorBoardDeployment | Raspberry Pi Pico W (baremetal) on the Main Board. | This repo |

This Git Repo contains the source code, CMake build files, and configuration files for the Raspberry Pi Pico W MainSensorBoardDeployment only.

## Install F'
Below are the steps to install the F' Framework and clone this repo:
1. Install the F' [system requirements](https://fprime.jpl.nasa.gov/latest/docs/getting-started/installing-fprime/#system-requirements).
2. Install fprime-bootstrap: `pip install fprime-bootstrap`
3. Clone the project: `fprime-bootstrap clone https://github.com/fprime-community/fprime-amsat-main-board-reference.git`
4. `cd fprime-amsat-main-board-reference`
5. Activate the virtual environment: `. fprime-venv/bin/activate`

If you cloned with plain `git clone` instead of `fprime-bootstrap`, run `git submodule update --init --recursive` to fetch `lib/fprime`, `lib/fprime-arduino`, `lib/fprime-baremetal`, and `lib/fprime-sensors`.

## Install the Arduino CLI
The Pico W is built with the Arduino toolchain through [fprime-arduino](https://github.com/fprime-community/fprime-arduino). With the project virtual environment active, install `arduino-cli` and the CMake wrapper into the virtual environment:

```shell
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR=$VIRTUAL_ENV/bin sh
pip install arduino-cli-cmake-wrapper
```

Then install the Raspberry Pi Pico board package and the required Arduino `Time` library:

```shell
arduino-cli config init
arduino-cli config add board_manager.additional_urls https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json
arduino-cli core update-index
arduino-cli core install rp2040:rp2040
arduino-cli lib install Time
```

See the fprime-arduino [Arduino CLI Installation Guide](lib/fprime-arduino/docs/arduino-cli-install.md) for more detail, including Linux udev rules.

## Building for the Pico W
From the project virtual environment:
1. `cd MainSensorBoardDeployment`
2. `fprime-util generate -f` (`-f` deletes any previous build directory)
3. `fprime-util build`

`rpipicow` is the default toolchain in `settings.ini`. Build output is written to `build-artifacts/rpipicow/MainSensorBoardDeployment/` at the project root.

## Loading and Running on the Pico W
See [MainSensorBoardDeployment/README.md](MainSensorBoardDeployment/README.md#uploading-to-the-pico-w) for uploading the firmware and connecting the F' GDS.
