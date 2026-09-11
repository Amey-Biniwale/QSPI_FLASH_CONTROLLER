`default_nettype none

module QSPI_Core #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // CLOCK AND RESET
    input wire SCLK,
    input wire SRESETn,
    
    // INPUTS FROM INDIRECT COMMAND ENGINE
    input wire IND_START,
    input wire [7:0] IND_OPCODE,
    input wire [ADDR_WIDTH-1:0] IND_ADDRESS,
    input wire [DATA_WIDTH-1:0] IND_TX_DATA,
    input wire [4:0] IND_DUMMY,
    input wire [1:0] IND_MODE,
    input wire IND_DATA_DIR,
    input wire [5:0] IND_ENABLE,
    
    // INPUTS FROM XIP
    input wire XIP_START,
    input wire [7:0] XIP_OPCODE,
    input wire [ADDR_WIDTH-1:0] XIP_ADDRESS,
    input wire [4:0] XIP_DUMMY,
    input wire [1:0] XIP_MODE,
    input wire [5:0] XIP_ENABLE,
    input wire [7:0] XIP_MODE_QIOR,
    
    // OUTPUTS TO INDIRECT COMMAND ENGINE
    output wire IND_BUSY,
    output wire IND_DONE,
    output wire [DATA_WIDTH-1:0] IND_RX_DATA,
    output wire IND_RX_DATA_VALID,
    output wire IND_ERROR,
    output wire IND_FIFO_EN,
    output wire IND_GET_EN,
    
    // OUTPUTS TO XIP
    output wire XIP_BUSY,
    output wire XIP_DONE,
    output wire [DATA_WIDTH-1:0] XIP_RX_DATA,
    output wire XIP_RX_DATA_VALID,
    output wire XIP_ERROR,
    output wire XIP_FIFO_EN,
    output wire XIP_GET_EN,
    
      // INPUT PORTS FOR THE QSPI
      input wire io0_i,
      input wire io1_i,
      input wire io2_i,
      input wire io3_i,
    
     // CHIP SELECT
     input wire FLASH_WIP,
      output wire CSn,
      
      // OUTPUT PORTS FOR THE QSPI
      output wire io0_o,
      output wire io1_o,
      output wire io2_o,
      output wire io3_o,
      output wire io0_oe,
      output wire io1_oe,
      output wire io2_oe,
      output wire io3_oe
    );
    
    wire CONT_ARB_BUSY;
    wire CONT_ARB_DONE;
    wire [DATA_WIDTH-1:0] CONT_ARB_RX_DATA;
    wire CONT_ARB_RX_DATA_VALID;
    wire CONT_ARB_ERROR;
    
    wire ARB_CONT_START;
    wire [7:0] ARB_CONT_OPCODE;
    wire [ADDR_WIDTH-1:0] ARB_CONT_ADDRESS;
    wire [4:0] ARB_CONT_DUMMY;
    wire [7:0] ARB_CONT_MODE_QIOR;
    wire [1:0] ARB_CONT_MODE;
    wire [5:0] ARB_CONT_ENABLE;
    wire ARB_CONT_DATA_DIR;
    wire [DATA_WIDTH-1:0] ARB_CONT_TX_DATA;
    
    QSPI_ARBITER #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) arb(
        .SCLK(SCLK),
        .SRESETn(SRESETn),
        
        .IND_START(IND_START),
        .IND_OPCODE(IND_OPCODE),
        .IND_ADDRESS(IND_ADDRESS),        
        .IND_TX_DATA(IND_TX_DATA),
        .IND_DUMMY(IND_DUMMY),
        .IND_MODE(IND_MODE),
        .IND_DATA_DIR(IND_DATA_DIR),
        .IND_ENABLE(IND_ENABLE),
        
        .XIP_START(XIP_START),
        .XIP_OPCODE(XIP_OPCODE),
        .XIP_ADDRESS(XIP_ADDRESS),
        .XIP_DUMMY(XIP_DUMMY),
        .XIP_MODE(XIP_MODE),
        .XIP_ENABLE(XIP_ENABLE),
        .XIP_MODE_QIOR(XIP_MODE_QIOR),
        
        .QSPI_BUSY(CONT_ARB_BUSY),
        .QSPI_DONE(CONT_ARB_DONE),
        .QSPI_RX_DATA(CONT_ARB_RX_DATA),
        .QSPI_RX_DATA_VALID(CONT_ARB_RX_DATA_VALID),
        .QSPI_ERROR(CONT_ARB_ERROR),
        
        .QSPI_START(ARB_CONT_START),
        .QSPI_OPCODE(ARB_CONT_OPCODE),
        .QSPI_ADDRESS(ARB_CONT_ADDRESS),
        .QSPI_TX_DATA(ARB_CONT_TX_DATA),
        .QSPI_DUMMY(ARB_CONT_DUMMY),
        .QSPI_MODE(ARB_CONT_MODE),
        .QSPI_ENABLE(ARB_CONT_ENABLE),
        .QSPI_MODE_QIOR(ARB_CONT_MODE_QIOR),
        .QSPI_DATA_DIR(ARB_CONT_DATA_DIR),
        
        .IND_BUSY(IND_BUSY),
        .IND_DONE(IND_DONE),
        .IND_RX_DATA(IND_RX_DATA),
        .IND_RX_DATA_VALID(IND_RX_DATA_VALID),
        .IND_ERROR(IND_ERROR),
        .IND_FIFO_EN(IND_FIFO_EN),
        
        .XIP_BUSY(XIP_BUSY),
        .XIP_DONE(XIP_DONE),
        .XIP_RX_DATA(XIP_RX_DATA),
        .XIP_RX_DATA_VALID(XIP_RX_DATA_VALID),
        .XIP_ERROR(XIP_ERROR),
        .XIP_FIFO_EN(XIP_FIFO_EN),
        
        .IND_GET_EN(IND_GET_EN),
        .XIP_GET_EN(XIP_GET_EN)
    );
    
    wire PHY_CONT_PHASE_DONE;
    wire PHY_CONT_ERROR;
    wire [DATA_WIDTH-1:0] PHY_CONT_RX_DATA;
    
    wire CONT_PHY_START;
    wire [7:0] CONT_PHY_OPCODE;
    wire [3:0] CONT_PHY_PHASE;
    wire [1:0] CONT_PHY_MODE;
    wire [7:0] CONT_PHY_MODE_QIOR;
    wire [ADDR_WIDTH-1:0] CONT_PHY_ADDRESS;
    wire [4:0] CONT_PHY_DUMMY;
    wire [DATA_WIDTH-1:0] CONT_PHY_TX_DATA;
    
    
    
    
    // CONTROLLER
    
    
    
    QSPI_CONTROLLER #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) cont(
        .SCLK(SCLK),
        .SRESETn(SRESETn),
        
        .OPCODE(ARB_CONT_OPCODE),
        .ADDRESS(ARB_CONT_ADDRESS),
        .MODE(ARB_CONT_MODE),
        .TX_DATA(ARB_CONT_TX_DATA),
        .DUMMY(ARB_CONT_DUMMY),
        .START(ARB_CONT_START),
        .ENABLE(ARB_CONT_ENABLE),
        .MODE_QIOR(ARB_CONT_MODE_QIOR),
        .DATA_DIR(ARB_CONT_DATA_DIR),
        
        .PHY_PHASE_DONE(PHY_CONT_PHASE_DONE),
        .PHY_ERROR(PHY_CONT_ERROR),
        .PHY_RX_DATA(PHY_CONT_RX_DATA),
        
        .FLASH_WIP(FLASH_WIP),
        
        .PHY_START(CONT_PHY_START),
        .PHY_OPCODE(CONT_PHY_OPCODE),
        .PHY_PHASE(CONT_PHY_PHASE),
        .PHY_MODE(CONT_PHY_MODE),
        .PHY_MODE_QIOR(CONT_PHY_MODE_QIOR),
        .PHY_ADDRESS(CONT_PHY_ADDRESS),
        .PHY_DUMMY(CONT_PHY_DUMMY),
        .PHY_TX_DATA(CONT_PHY_TX_DATA),
        
        .DONE(CONT_ARB_DONE),
        .BUSY(CONT_ARB_BUSY),
        .RX_DATA(CONT_ARB_RX_DATA),
        .RX_VALID(CONT_ARB_RX_DATA_VALID),
        .ERROR(CONT_ARB_ERROR)
    );
    
    
    
    
    // PHYSICAL SHIFT REGISTER
    
    
    
    QSPI_PHY #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) phy(
        .SCLK(SCLK),
        .SRESETn(SRESETn),
        
        .START(CONT_PHY_START),
        .OPCODE(CONT_PHY_OPCODE),
        .ADDRESS(CONT_PHY_ADDRESS),
        .MODE(CONT_PHY_MODE),
        .DUMMY_CYCLES(CONT_PHY_DUMMY),
        .MODE_QIOR(CONT_PHY_MODE_QIOR),
        .TX_DATA(CONT_PHY_TX_DATA),
        .PHASE(CONT_PHY_PHASE),
        .BUSY(CONT_ARB_BUSY),
        
        .io0_i(io0_i),
        .io1_i(io1_i),
        .io2_i(io2_i),
        .io3_i(io3_i),
        
        .io0_o(io0_o),
        .io1_o(io1_o),
        .io2_o(io2_o),
        .io3_o(io3_o),
        
        .io0_oe(io0_oe),
        .io1_oe(io1_oe),
        .io2_oe(io2_oe),
        .io3_oe(io3_oe),
        
        .CSn(CSn),
        
        .RX_DATA(PHY_CONT_RX_DATA),
        .ERROR(PHY_CONT_ERROR),
        .PHASE_DONE(PHY_CONT_PHASE_DONE)
    );
endmodule

