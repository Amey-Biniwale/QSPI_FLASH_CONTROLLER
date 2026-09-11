`default_nettype none

module APB_Slave #(
    parameter DATA_WIDTH = 32,
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
    
    // INPUTS FROM THE INDIRECT COMMAND ENGINE
    input wire [DATA_WIDTH-1:0] IND_RDATA,
    
    // OUTPUTS TO THE CPU
    output reg PSLVERR,
    output wire PREADY,
    output reg [DATA_WIDTH-1:0] PRDATA,
    
    // OUTPUT TO THE INDIRECT COMMAND ENGINE
    output reg [DATA_WIDTH-1:0] IND_DATA,
    output reg [31:0] IND_ADDR,
    output wire IND_WRITE
    
    );
        
    // ADDRESSES DEFINED FOR THE DATA
    localparam [31:0] OPCODE_ADDR = 32'h0000;
    localparam [31:0] ADDRESS_ADDR = 32'h0008;
    localparam [31:0] MODE_ADDR = 32'h0028;
    localparam [31:0] DUMMY_ADDR = 32'h0030;
    localparam [31:0] DATA_ADDR = 32'h0038;
    localparam [31:0] START_ADDR = 32'h0058;
    localparam [31:0] DATA_DIR_ADDR = 32'h0059;
    
    // ADDRESSES DEFINED FOR ENABLE SIGNALS
    
    localparam EN_ADDR = 32'h005A; 
    
    wire APB_READ;  
    
    assign IND_WRITE = PSEL && PENABLE && PWRITE;
    assign APB_READ = PSEL && PENABLE && !PWRITE;
    
    //IN THIS BLOCK, THE MODULE IS CHECKING THE STROBE INPUTS MATCH THE WIDTH OF THE DATA TO BE SENT THROUGH THE HELP OF INCOMING ADDRESS
    
    /*
    For example, if I have to sent the OPCODE, my OPCODE will be of 8 bits.
    If the address sent by the CPU corresponds to that of OPCODE, we will check whether only 1 bit of Strobe is asserted. 
    If only 1 is asserted, the data is taken to be valid and sent to the Indirect Command Engine.
    If not, PSLVERR is asserted
    */
    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            IND_DATA <= 0;
            IND_ADDR <= 0;
        end
        else begin       
            if(IND_WRITE) begin
                case(PADDR)
                    // SENDING THE OPCODE 
                    OPCODE_ADDR : begin
                        if(PSTRB == {{(DATA_BYTES-1){1'b0}},1'b1}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    // SENDING THE ADDRESS
                    ADDRESS_ADDR : begin
                        if(PSTRB == {DATA_BYTES{1'b1}}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    MODE_ADDR : begin
                        if(PSTRB == {{(DATA_BYTES-1){1'b0}},1'b1}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    // SENDING THE SUMMY CYCLES
                    DUMMY_ADDR : begin
                        if(PSTRB == {{(DATA_BYTES-1){1'b0}},1'b1}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    // SENDING THE DATA
                    DATA_ADDR : begin
                        if(PSTRB == {DATA_BYTES{1'b1}}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    // SENDING THE START BIT
                    START_ADDR : begin
                        if(PSTRB == {{(DATA_BYTES-1){1'b0}},1'b1}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    DATA_DIR_ADDR : begin
                        if(PSTRB == {{(DATA_BYTES-1){1'b0}},1'b1}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    EN_ADDR : begin
                        if(PSTRB == {{(DATA_BYTES-1){1'b0}},1'b1}) begin
                            IND_ADDR <= PADDR;
                            IND_DATA <= PWDATA;
                        end
                    end
                    default : begin
                        IND_ADDR <= 0;
                        IND_DATA <= 0;
                    end
                endcase
            end
        end
    end
    
    always @(*) begin
        PRDATA  = 0;
        PSLVERR = 0;
    
        if(APB_READ) begin
            if(PADDR == DATA_ADDR)
                PRDATA = IND_RDATA;
            else
                PSLVERR = 1;
        end
    
        if(IND_WRITE) begin
            case(PADDR)
                OPCODE_ADDR,
                MODE_ADDR,
                DUMMY_ADDR,
                START_ADDR,
                DATA_DIR_ADDR,
                EN_ADDR:
                    if(PSTRB != {{(DATA_BYTES-1){1'b0}},1'b1})
                        PSLVERR = 1;
    
                ADDRESS_ADDR,
                DATA_ADDR:
                    if(PSTRB != {DATA_BYTES{1'b1}})
                        PSLVERR = 1;
    
                default:
                    PSLVERR = 1;
            endcase
        end
    end   
    
    assign PREADY = (PENABLE && PSEL);

endmodule

