module MainSensorBoardDeployment {

  # ----------------------------------------------------------------------
  # Base ID Convention
  # ----------------------------------------------------------------------
  #
  # All Base IDs follow the 8-digit hex format: 0xDSSCCxxx
  #
  # Where:
  #   D   = Deployment digit (1 for this deployment). Keeps IDs distinct from the CDHDeployment on the Pi Zero 2.
  #   SS  = Subtopology digits (00 for main topology, 01 for ComFprime; see config/ComFprimeConfig)
  #   CC  = Component digits (00, 01, 02, etc.)
  #   xxx = Reserved for internal component items (events, commands, telemetry)
  #

  # ----------------------------------------------------------------------
  # Defaults
  # ----------------------------------------------------------------------

  module Default {
    constant QUEUE_SIZE = 3
    constant STACK_SIZE = 64 * 1024
  }

  # ----------------------------------------------------------------------
  # Active component instances
  # ----------------------------------------------------------------------

  instance cmdDisp: Svc.CommandDispatcher base id 0x10001000 \
    queue size Default.QUEUE_SIZE\
    stack size Default.STACK_SIZE \
    priority 101

  instance eventLogger: Svc.EventManager base id 0x10002000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 98

  instance tlmSend: Svc.TlmChan base id 0x10003000 \
    queue size Default.QUEUE_SIZE \
    stack size Default.STACK_SIZE \
    priority 97



  # ----------------------------------------------------------------------
  # Queued component instances
  # ----------------------------------------------------------------------

  # ----------------------------------------------------------------------
  # Passive component instances
  # ----------------------------------------------------------------------

  instance rateGroup1: Svc.PassiveRateGroup base id 0x10004000

  @ Communications driver. May be swapped with other com drivers like Arduino.StreamDriver, Arduino.TcpServer, or Arduino.TcpClient.
  instance comDriver: Arduino.StreamDriver base id 0x10005000

  instance fatalHandler: Baremetal.FatalHandler base id 0x10006000

  instance timeHandler: Arduino.ArduinoTime base id 0x10007000

  instance rateGroupDriver: Svc.RateGroupDriver base id 0x10008000

  instance textLogger: Svc.PassiveTextLogger base id 0x10009000

  instance systemResources: Svc.SystemResources base id 0x1000A000

  instance rateDriver: Arduino.HardwareRateDriver base id 0x1000B000

}
