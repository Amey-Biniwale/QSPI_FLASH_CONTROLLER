verification_cycle
QSPI_top.SCLK
wf_signal_group -name "Destination Clock" -signals {QSPI_top.SCLK}
QSPI_top.IND_FIFO_START
wf_signal_group -name "Destination Input" -signals {QSPI_top.IND_FIFO_START}
QSPI_top.PCLK
wf_signal_group -name "Source Clock" -signals {QSPI_top.PCLK}
QSPI_top.ff1.syncro1
wf_signal_group -name "Destination Output" -signals {QSPI_top.ff1.syncro1}
