`default_nettype none

module APB_Path #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter DATA_BYTES = DATA_WIDTH/8
)(
    // CLOCK AND RESET
    input wire PCLK,
    input wire PRESETn,
    
    //INPUTS FROM CPU
    input wire PWRITE,
    input wire PENABLE,
    input wire PSEL,
    input wire [DATA_BYTES-1:0] PSTRB,
    input wire [31:0] PADDR,
    input wire [DATA_WIDTH-1:0] PWDATA,
    
    // OUTPUTS TO THE CPU
    output wire PSLVERR,
    output wire PREADY,
    output wire [DATA_WIDTH-1:0] PRDATA,
    
    
    // QSPI CONTROLLER INTERFACE
    input wire QSPI_BUSY,
    input wire QSPI_DONE,
    input wire [DATA_WIDTH-1:0] QSPI_RX_DATA,
    input wire QSPI_RX_VALID,
    input wire QSPI_ERROR,

    // COMMAND TO ARBITER
    output wire QSPI_START,
    output wire [7:0] QSPI_OPCODE,
    output wire [ADDR_WIDTH-1:0] QSPI_ADDRESS,
    output wire [4:0] QSPI_DUMMY,
    output wire [1:0] QSPI_MODE,
    output wire [DATA_WIDTH-1:0] QSPI_TX_DATA,
    output wire DATA_DIR,
    output wire [5:0] QSPI_ENABLE,

    // IND -> ARB COMMAND FIFO WRITE ENABLE
    output wire FIFO_EN,
    output wire APB_ERROR
    );
    
    wire [DATA_WIDTH-1:0] APB_IND_DATA;
    wire [ADDR_WIDTH-1:0] APB_IND_ADDR;
    
    wire [DATA_WIDTH-1:0] IND_APB_RDATA;
    wire APB_IND_WRITE;
    

    // APB SLAVE
    
    APB_Slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_BYTES(DATA_BYTES)
    ) apb(
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        
        .PSEL(PSEL),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSTRB(PSTRB),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        
        .IND_RDATA(IND_APB_RDATA),
        
        .PSLVERR(PSLVERR),
        .PREADY(PREADY),
        .PRDATA(PRDATA),
        
        .IND_DATA(APB_IND_DATA),
        .IND_ADDR(APB_IND_ADDR) ,
        .IND_WRITE(APB_IND_WRITE)
    );



    // INDIRECT COMMAND ENGINE
    
    
    INDIRECT_COMMAND_ENGINE #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ice(
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        
        .APB_DATA(APB_IND_DATA),
        .APB_ADDR(APB_IND_ADDR),
        .APB_WRITE(APB_IND_WRITE),
        
        .QSPI_BUSY(QSPI_BUSY),
        .QSPI_DONE(QSPI_DONE),
        .QSPI_RX_DATA(QSPI_RX_DATA),
        .QSPI_RX_VALID(QSPI_RX_VALID),
        .QSPI_ERROR(QSPI_ERROR),
        
        .QSPI_START(QSPI_START),
        .QSPI_OPCODE(QSPI_OPCODE),
        .QSPI_ADDRESS(QSPI_ADDRESS),
        .QSPI_DUMMY(QSPI_DUMMY),
        .QSPI_MODE(QSPI_MODE),
        .QSPI_TX_DATA(QSPI_TX_DATA),
        .DATA_DIR(DATA_DIR),
        .QSPI_ENABLE(QSPI_ENABLE),
        
        .FIFO_EN(FIFO_EN),
                
        .APB_RDATA(IND_APB_RDATA),
        .APB_ERROR(APB_ERROR)
    );
    
    
endmodule

