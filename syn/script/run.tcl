#read_verilog ../src/adder.v
analyze -format verilog ../src/{QSPI_top.v AHB_Slave.v APB_Slave.v syncro.v INDIRECT_COMMAND_ENGINE.v XIP_PREFETCH_BUFFER.v APB_Path.v AHB_Path.v QSPI_ARBITER.v QSPI_CONTROLLER.v QSPI_PHY.v QSPI_Core.v}
analyze -format verilog ../src/async_fifo/{write_handler.v fifo_top.v fifo.v read_handler.v ff2_sync.v bi_to_gr.v}
elaborate QSPI_top
#current_design adder
link
check_design
write -format ddc -hier -output unmapped/QSPI_top.ddc
source -echo constraints.sdc
write -format ddc -hier -output unmapped/QSPI_top.ddc
check_timing
compile
report_area > reports/QSPI_top_area.rpt
report_timing > reports/QSPI_top_timing.rpt
write -format verilog -hierarchy -output netlist/QSPI_top_netlist.v
write -format ddc -hierarchy -output mapped/QSPI_top.ddc
start_gui
