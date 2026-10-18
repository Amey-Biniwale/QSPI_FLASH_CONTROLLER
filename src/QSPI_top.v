`default_nettype none

module QSPI_top#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BYTES = DATA_WIDTH/8,
    parameter DATA_BYTES = DATA_WIDTH/8,
    parameter ADDR_BYTES = 3,
    parameter DIVIDER = 4,
    parameter LINE_SIZE = 4
)(
    input wire PCLK,
    input wire HCLK,
    
    input wire CPOL,
    input wire CPHA,
    
    input wire RESETn,
    
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [DATA_WIDTH-1:0] PWDATA,
    input wire [ADDR_WIDTH-1:0] PADDR,
    
    input wire [1:0] HTRANS,
    input wire HSEL,
    input wire HWRITE,
    input wire HREADY,
    input wire [ADDR_WIDTH-1:0] HADDR,
    
    output wire PSLVERR,
    output wire PREADY,
    output wire [DATA_WIDTH-1:0] PRDATA,
    
    output wire HREADYOUT,
    output wire HRESP,
    output wire [DATA_WIDTH-1:0] HRDATA,
    
    output wire CSn,
    
    output wire SCLK,
    
    inout wire io_0,
    inout wire io_1,
    inout wire io_2,
    inout wire io_3
    );
    
    wire [2:0] EMPTY, FULL;
    
    wire SCLK_INT;
    
    // APB <--> FIFO
    
    reg PRESETn;
    
    wire [76:0] POUT_CTRL;
    wire PSTART;
    wire [DATA_WIDTH-1:0] POUT_FIFO;
    
    wire SPBUSY;
    wire SPERROR;
    wire [DATA_WIDTH-1:0] SPRET_DATA;
    
    wire PFIFO_WR_EN;
    wire PFIFO_RD_EN;
    
    
    // AHB <--> XIP
    
    reg HRESETn;
    
    wire REQ_START;
    wire [ADDR_WIDTH-1:0] REQ_ADDR;
    
    wire [DATA_WIDTH-1:0] XHRET_DATA;
    wire XHRET_DATA_VALID;
    wire XHERROR;
    
    
    // XIP <--> FIFO
    wire SHBUSY;
    wire SHERROR;
    
    wire [DATA_WIDTH-1:0] SHRET_DATA;
    
    wire HSTART;
    wire [76:0] HOUT_CTRL;
    wire HFIFO_RD_EN;
    
    
    // FIFO <--> SCLK
    
    reg SRESETn;
    
    wire SPSTART;
    wire SHSTART;
    
    wire [DATA_WIDTH-1:0] SPOUT_FIFO;
    
    wire PBUSY;
    wire HBUSY;
    wire PERROR;
    wire HERROR;
    
    wire FLUSH_APB, FLUSH_AHB;
    wire SFLUSH_APB, SFLUSH_AHB;
    
    // ARB <--> QSPI
    
    wire AQSTART;
    wire AQOWNER;
    wire [76:0] AQOUT_CTRL;
    
    wire AQBUSY;
    wire AQERROR;
    
    // QSPI <--> HCLK/PCLK
    
    wire QPFIFO_RD_EN;
    wire QPFIFO_WR_EN;
    
    wire QHFIFO_WR_EN;
    
    wire [DATA_WIDTH-1:0] PRET_DATA;
    
    wire [DATA_WIDTH-1:0] HRET_DATA;
    
    reg PSYNC, HSYNC, SSYNC;
    
    wire CLK_EN;
    
    always @(posedge PCLK or negedge RESETn) begin
        if(!RESETn) begin
            PRESETn <= 0;
            PSYNC <= 0;
        end
        else begin
            PSYNC <= 1;
            PRESETn <= PSYNC;
        end
    end
    
    always @(posedge HCLK or negedge RESETn) begin
        if(!RESETn) begin
            HRESETn <= 0;
            HSYNC <= 0;
        end
        else begin
            HSYNC <= 1;
            HRESETn <= HSYNC;
        end
    end
    
    always @(posedge SCLK_INT or negedge RESETn) begin
        if(!RESETn) begin
            SRESETn <= 0;
            SSYNC <= 0;
        end
        else begin
            SSYNC <= 1;
            SRESETn <= SSYNC;
        end
    end
    
    // APB SLAVE
    
    APB_Slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) apb (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PWRITE(PWRITE),
        
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        
        .BUSY(SPBUSY),
        .ERROR(SPERROR),
        .FIFO_EMPTY(EMPTY[1]),
        .FIFO_FULL(FULL[0]),
        
        .FIFO_WR_EN(PFIFO_WR_EN),
        .FIFO_RD_EN(PFIFO_RD_EN),
        
        .RET_DATA(SPRET_DATA),
        
        .PSLVERR(PSLVERR),
        .PREADY(PREADY),
        .PRDATA(PRDATA),
        
        .START(PSTART),
        .OUT_CTRL(POUT_CTRL),
        .OUT_FIFO(POUT_FIFO),
        .FLUSH(SFLUSH_APB)
    );
    
    
    // AHB SLAVE
    
    AHB_Slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ahb (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        .HSEL(HSEL),
        .HTRANS(HTRANS),
        .HREADY(HREADY),
        .HWRITE(HWRITE),
        
        .HADDR(HADDR),
        
        .RET_DATA(XHRET_DATA),
        .RET_DATA_VALID(XHRET_DATA_VALID),
        .ERROR(XHERROR),
        
        .HREADYOUT(HREADYOUT),
        .HRESP(HRESP),
        .HRDATA(HRDATA),
        
        .REQ_START(REQ_START),
        .REQ_ADDR(REQ_ADDR)
    );
    
    
    // XIP + PREFETCH BUFFER
    
    XIP_Prefetch #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .LINE_SIZE(LINE_SIZE),
        .DATA_BYTES(DATA_BYTES),
        .ADDR_BYTES(ADDR_BYTES)
    ) prefetch (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        
        .REQ_START(REQ_START),
        .REQ_ADDR(REQ_ADDR),
        
        .BUSY(SHBUSY),
        .ERROR(SHERROR),
        .FIFO_EMPTY(EMPTY[2]),
        
        .RET_DATA(SHRET_DATA),
        
        .START(HSTART),
        .OUT_CTRL(HOUT_CTRL),
        .FIFO_RD_EN(HFIFO_RD_EN),
        .FLUSH(SFLUSH_AHB),
        
        .AHB_DATA(XHRET_DATA),
        .AHB_DATA_VALID(XHRET_DATA_VALID),
        .AHB_ERROR(XHERROR)
    );
    
    
    // CLOCK DIVIDER
    
    
    CLOCK_DIV #(
        .DIVIDER(DIVIDER)
    ) clock_div (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .EN(CLK_EN),
        
        .CPOL(CPOL),
        .CPHA(CPHA),
        
        .SCLK(SCLK),
        .SCLK_INT(SCLK_INT)
    );
    
    
    // ARBITER
    
    QSPI_Arbiter arbiter (
        .SCLK(SCLK_INT),
        .SRESETn(SRESETn),
        
        .PSTART(SPSTART),
        .PCTRL(POUT_CTRL),
        
        .HSTART(SHSTART),
        .HCTRL(HOUT_CTRL),
        
        .BUSY(AQBUSY),
        .ERROR(AQERROR),
        
        .START(AQSTART),
        .OWNER(AQOWNER),
        .OUT_CTRL(AQOUT_CTRL),
        
        .FLUSH_APB(FLUSH_APB),
        .FLUSH_AHB(FLUSH_AHB),
        
        .PBUSY(PBUSY),
        .PERROR(PERROR),
        
        .HBUSY(HBUSY),
        .HERROR(HERROR)
    );
    
    
    // QSPI
    
    QSPI #(
        .DATA_WIDTH(DATA_WIDTH),
        .BYTES(BYTES)
    ) qspi (
        .SCLK(SCLK_INT),
        .SRESETn(SRESETn),
        
        .START(AQSTART),
        .OWNER(AQOWNER),
        .OUT_CTRL(AQOUT_CTRL),
        
        .POUT_FIFO(SPOUT_FIFO),
        
        .BUSY(AQBUSY),
        .ERROR(AQERROR),
        
        .CLK_EN(CLK_EN),
        
        .PFIFO_RD_EN(QPFIFO_RD_EN),
        .PFIFO_WR_EN(QPFIFO_WR_EN),
        
        .HFIFO_WR_EN(QHFIFO_WR_EN),
        
        .PRET_DATA(PRET_DATA),
        .HRET_DATA(HRET_DATA),
        
        .CSn(CSn),
        
        .io_in({io_3, io_2, io_1, io_0}),
        .io_out({io_3, io_2, io_1, io_0})
    );
    
    sync_ff2 pstart(
        .CLK(SCLK_INT),
        .RSTn(SRESETn),
        .DATA_IN(PSTART),
        .DATA_OUT(SPSTART)
    );
    
    sync_ff2 hstart(
        .CLK(SCLK_INT),
        .RSTn(SRESETn),
        .DATA_IN(HSTART),
        .DATA_OUT(SHSTART)
    );
    
    sync_ff2 pbusy(
        .CLK(PCLK),
        .RSTn(PRESETn),
        .DATA_IN(PBUSY),
        .DATA_OUT(SPBUSY)
    );
    
    sync_ff2 perror(
        .CLK(PCLK),
        .RSTn(PRESETn),
        .DATA_IN(PERROR),
        .DATA_OUT(SPERROR)
    );
    
    sync_ff2 hbusy(
        .CLK(HCLK),
        .RSTn(HRESETn),
        .DATA_IN(HBUSY),
        .DATA_OUT(SHBUSY)
    );
    
    sync_ff2 herror(
        .CLK(HCLK),
        .RSTn(HRESETn),
        .DATA_IN(HERROR),
        .DATA_OUT(SHERROR)
    );
    
    async_fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(256)
    ) apb_qspi (
        .wr_clk(PCLK),
        .rd_clk(SCLK_INT),
        .wr_en(PFIFO_WR_EN),
        .rd_en(QPFIFO_RD_EN),
        .wr_rst(PRESETn),
        .rd_rst(SRESETn),
        .flush_wr(SFLUSH_APB),
        .flush_rd(FLUSH_APB),
        .din(POUT_FIFO),
        .dout(SPOUT_FIFO),
        .full(FULL[0]),
        .empty(EMPTY[0])
    );
    
    async_fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(16)
    ) qspi_apb (
        .wr_clk(SCLK_INT),
        .rd_clk(PCLK),
        .wr_en(QPFIFO_WR_EN),
        .rd_en(PFIFO_RD_EN),
        .wr_rst(SRESETn),
        .rd_rst(PRESETn),
        .flush_wr(FLUSH_APB),
        .flush_rd(SFLUSH_APB),
        .din(PRET_DATA),
        .dout(SPRET_DATA),
        .full(FULL[1]),
        .empty(EMPTY[1])
    );
    
    async_fifo #(
        .WIDTH(DATA_WIDTH),
        .DEPTH(2*LINE_SIZE)
    ) qspi_ahb (
        .wr_clk(SCLK_INT),
        .rd_clk(HCLK),
        .wr_en(QHFIFO_WR_EN),
        .rd_en(HFIFO_RD_EN),
        .wr_rst(SRESETn),
        .rd_rst(HRESETn),
        .flush_wr(FLUSH_AHB),
        .flush_rd(SFLUSH_AHB),
        .din(HRET_DATA),
        .dout(SHRET_DATA),
        .full(FULL[2]),
        .empty(EMPTY[2])
    );
endmodule

