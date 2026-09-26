module MainSensorBoardDeployment {

  # ----------------------------------------------------------------------
  # Symbolic constants for port numbers
  # ----------------------------------------------------------------------

    enum Ports_RateGroups {
      rateGroup10Hz
    }

  topology MainSensorBoardDeployment {

    # ----------------------------------------------------------------------
    # Subtopology imports
    # ----------------------------------------------------------------------


    import ComFprime.Subtopology

    # ----------------------------------------------------------------------
    # Instances used in the topology
    # ----------------------------------------------------------------------

    instance cmdDisp
    instance comDriver
    instance eventLogger
    instance fatalHandler
    instance rateDriver
    instance rateGroup10Hz
    instance rateGroupDriver
    instance systemResources
    instance textLogger
    instance timeHandler
    instance tlmSend

    # ----------------------------------------------------------------------
    # Pattern graph specifiers
    # ----------------------------------------------------------------------

    command connections instance cmdDisp

    event connections instance eventLogger

    telemetry connections instance tlmSend

    text event connections instance textLogger

    time connections instance timeHandler

    # ----------------------------------------------------------------------
    # Direct graph specifiers
    # ----------------------------------------------------------------------

    connections RateGroups {
      # Block driver
      rateDriver.CycleOut -> rateGroupDriver.CycleIn

      # 10Hz rate group
      rateGroupDriver.CycleOut[Ports_RateGroups.rateGroup10Hz] -> rateGroup10Hz.CycleIn
      rateGroup10Hz.RateGroupMemberOut[0] -> tlmSend.Run
      rateGroup10Hz.RateGroupMemberOut[1] -> systemResources.run
      rateGroup10Hz.RateGroupMemberOut[2] -> comDriver.schedIn
    }

    connections FaultProtection {
      eventLogger.FatalAnnounce -> fatalHandler.FatalReceive
    }


    connections Communications {
      # Inputs to ComQueue (events, telemetry, file)
      eventLogger.PktSend -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.EVENTS]
      tlmSend.PktSend     -> ComFprime.comQueue.comPacketQueueIn[ComFprime.Ports_ComPacketQueue.TELEMETRY]

      # ComDriver buffer allocations
      comDriver.allocate      -> ComFprime.commsBufferManager.bufferGetCallee
      comDriver.deallocate    -> ComFprime.commsBufferManager.bufferSendIn
      
      # ComDriver <-> ComStub (Uplink)
      comDriver.$recv                     -> ComFprime.comStub.drvReceiveIn
      ComFprime.comStub.drvReceiveReturnOut -> comDriver.recvReturnIn
      
      # ComStub <-> ComDriver (Downlink)
      ComFprime.comStub.drvSendOut      -> comDriver.$send
      comDriver.ready         -> ComFprime.comStub.drvConnected

      # Router <-> CmdDispatcher
      ComFprime.fprimeRouter.commandOut  -> cmdDisp.seqCmdBuff
      cmdDisp.seqCmdStatus     -> ComFprime.fprimeRouter.cmdResponseIn
    }

    connections MainSensorBoardDeployment {
      # Add here connections to user-defined components
    }

  }

}
