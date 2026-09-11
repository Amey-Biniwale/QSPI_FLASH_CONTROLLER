`default_nettype none
/*
This module contains the RTL code for the physical shift registers for QSPI which connects the QSPI controller to the actual pins
*/

module QSPI_PHY #(
  parameter ADDR_WIDTH = 32,                        
  parameter DATA_WIDTH = 32                         
)(
  // CLOCK AND RESET
  input wire SCLK,                                       
  input wire SRESETn,
  
  // INPUTS FROM THE QSPI CONTROLLER                                 
  input wire START,                                    
  input wire [3:0] PHASE,                                
  input wire [1:0] MODE,  
  input wire [7:0] MODE_QIOR,                             
  input wire [7:0] OPCODE,
  input wire [ADDR_WIDTH-1:0] ADDRESS,
  input wire [DATA_WIDTH-1:0] TX_DATA,
  input wire [4:0] DUMMY_CYCLES,
  input wire BUSY,
  
  // INPUT PORTS FOR THE QSPI
  input wire io0_i,
  input wire io1_i,
  input wire io2_i,
  input wire io3_i,

  // OUTPUTS TO THE QSPI CONTROLLER
  output reg [DATA_WIDTH-1:0] RX_DATA,
  output reg ERROR,
  output reg PHASE_DONE,
  
  // CHIP SELECT
  output reg CSn,
  
  // OUTPUT PORTS FOR THE QSPI
  output reg io0_o,
  output reg io1_o,
  output reg io2_o,
  output reg io3_o,
  output reg io0_oe,
  output reg io1_oe,
  output reg io2_oe,
  output reg io3_oe
);


  // Intermediate Shift Registers to send the incoming data bit by bit


  reg [7:0] opcode_shift;
  reg [ADDR_WIDTH-1:0] addr_shift;
  reg [DATA_WIDTH-1:0] tx_shift;
  reg [DATA_WIDTH-1:0] rx_shift;
  reg [7:0] mode_qior_shift;


  // Counter Registers


  reg [4:0] dummy_count;
  reg [DATA_WIDTH-1:0] data_bit_count;
  reg [ADDR_WIDTH-1:0] addr_bit_count;


  // Bits per Clock


  reg [2:0] bits_per_clk;


  // Phase State Declaration


  localparam PH_IDLE = 4'b0000, PH_OPCODE = 4'b0001, PH_ADDRESS = 4'b0010, PH_MODE = 4'b0011, PH_DUMMY = 4'b0100, PH_DATA_TX = 4'b0101, PH_DATA_RX = 4'b0110;


  // MODE State Declarations

  localparam SINGLE = 2'b00, DUAL = 2'b01, QUAD = 2'b10;


  // Chip Select Logic : Active Low Chip Select

  always @(*) begin
      if(BUSY) begin
          CSn = 0;
      end
      else begin
          CSn = 1;
      end
  end


  // Setting the values to bits_per_clk based on the MODE


  always @(*) begin
      case(MODE)
        SINGLE : bits_per_clk = 1;
        DUAL : bits_per_clk = 2;
        QUAD : bits_per_clk = 4;
        default : bits_per_clk = 1;
      endcase
  end


  // Setting the output port enables based on the MODE


  always @(*) begin
      case(PHASE)
        PH_OPCODE, PH_ADDRESS, PH_MODE, PH_DATA_TX : begin
            case(MODE)
              SINGLE : begin
                  io0_oe = 1;
                  io1_oe = 0;
                  io2_oe = 0;
                  io3_oe = 0;
              end
              DUAL : begin
                  io0_oe = 1;
                  io1_oe = 1;
                  io2_oe = 0;
                  io3_oe = 0;
              end
              QUAD : begin
                  io0_oe = 1;
                  io1_oe = 1;
                  io2_oe = 1;
                  io3_oe = 1;
              end
              default : begin
                  io0_oe = 1;
                  io1_oe = 0;
                  io2_oe = 0;
                  io3_oe = 0;
              end
            endcase
        end
        default : begin
            io0_oe = 0;
            io1_oe = 0;
            io2_oe = 0;
            io3_oe = 0;
        end
      endcase
  end
  
  // TX SHIFT REGISTER

  // Registering the inputs into intermediate registers synchronous to the SCLK
  // OPCODE to cmd_shift
  // ADDRESS to addr_shift
  // Transmitter Data to tx_shift
  // Reciever Data to rx_shift
  // All the registers are also differentiated based on MODE


  always @(posedge SCLK or negedge SRESETn) begin
      if(!SRESETn) begin
          opcode_shift <= 0;
          addr_shift <= 0;
          tx_shift <= 0;
          rx_shift <= 0;
          mode_qior_shift <= 0;

          data_bit_count <= 0;
          addr_bit_count <= 0;
          dummy_count <= 0;

          PHASE_DONE <= 0;


          RX_DATA <= 0;
          ERROR <= 0;
      end
      else begin
          PHASE_DONE <= 0;

          if(START) begin

              opcode_shift <= OPCODE;
              addr_shift <= ADDRESS;
              tx_shift <= TX_DATA;
              mode_qior_shift <= MODE_QIOR;
              RX_DATA <= 0;

              data_bit_count <= 0;
              addr_bit_count <= 0;

              ERROR <= 0;
          end

          else if(BUSY) begin
              case(PHASE)
                PH_IDLE : begin
                    PHASE_DONE <= 1;
                end
                PH_OPCODE: begin
                    case(MODE)
                      SINGLE : opcode_shift <= {opcode_shift[6:0],1'b0};
                      DUAL : opcode_shift <= {opcode_shift[5:0],2'b0};
                      QUAD : opcode_shift <= {opcode_shift[3:0],4'b0};
                      default : ERROR <= 1;
                    endcase
                    data_bit_count <= (data_bit_count + bits_per_clk);
                    if(data_bit_count + bits_per_clk >= 8) begin
                        data_bit_count <= 0;
                        PHASE_DONE <= 1;
                    end
                end
                PH_ADDRESS: begin
                    case(MODE)
                      SINGLE : addr_shift <= {addr_shift[ADDR_WIDTH-2:0],1'b0};
                      DUAL : addr_shift <= {addr_shift[ADDR_WIDTH-3:0],2'b0};
                      QUAD : addr_shift <= {addr_shift[ADDR_WIDTH-5:0],4'b0};
                      default : ERROR <= 1;
                    endcase
                    addr_bit_count <= (addr_bit_count + bits_per_clk);
                    if(addr_bit_count + bits_per_clk >= ADDR_WIDTH) begin
                        addr_bit_count <= 0;
                        PHASE_DONE <= 1;
                    end
                end
                PH_MODE : begin
                    case(MODE)
                      SINGLE : mode_qior_shift <= {mode_qior_shift[6:0],1'b0};
                      DUAL : mode_qior_shift <= {mode_qior_shift[5:0],2'b0};
                      QUAD : mode_qior_shift <= {mode_qior_shift[3:0],4'b0};
                      default : ERROR <= 1;
                    endcase
                    data_bit_count <= (data_bit_count + bits_per_clk);
                    if(data_bit_count + bits_per_clk >= 8) begin
                        data_bit_count <= 0;
                        PHASE_DONE <= 1;
                    end
                end
                PH_DUMMY: begin
                  dummy_count <= dummy_count + 1;
                  if(dummy_count + 1 >= DUMMY_CYCLES) begin
                      dummy_count <= 0;
                      PHASE_DONE <= 1;
                  end
                end
                PH_DATA_TX: begin
                    case(MODE)
                      SINGLE : tx_shift <= {tx_shift[DATA_WIDTH-2:0],1'b0};
                      DUAL : tx_shift <= {tx_shift[DATA_WIDTH-3:0],2'b0};
                      QUAD : tx_shift <= {tx_shift[DATA_WIDTH-5:0],4'b0};
                      default : ERROR <= 1;
                    endcase
                    data_bit_count <= (data_bit_count + bits_per_clk);
                    if(data_bit_count + bits_per_clk >= DATA_WIDTH) begin
                        data_bit_count <= 0;
                        PHASE_DONE <= 1;
                    end
                end
                PH_DATA_RX: begin
                      case(MODE)
                        SINGLE : rx_shift <= {rx_shift[DATA_WIDTH-2:0], io0_i};
                        DUAL : rx_shift <= {rx_shift[DATA_WIDTH-3:0], io1_i, io0_i};
                        QUAD : rx_shift <= {rx_shift[DATA_WIDTH-5:0], io3_i, io2_i, io1_i, io0_i};
                        default : ERROR <= 1;
                      endcase
                      data_bit_count <= (data_bit_count + bits_per_clk);
                      if(data_bit_count + bits_per_clk >= DATA_WIDTH) begin
                          data_bit_count <= 0;
                          case(MODE)
                            SINGLE : RX_DATA <= {rx_shift[DATA_WIDTH-2:0], io0_i};
                            DUAL : RX_DATA <= {rx_shift[DATA_WIDTH-3:0], io1_i, io0_i};
                            QUAD : RX_DATA <= {rx_shift[DATA_WIDTH-5:0], io3_i, io2_i, io1_i, io0_i};
                          endcase
                          PHASE_DONE <= 1;
                      end
                end
                default: begin
                    opcode_shift <= 0;
                    addr_shift <= 0;
                    tx_shift <= 0;
                    rx_shift <= 0;
                    ERROR <= 1;
                    PHASE_DONE <= 0;
                end
              endcase


          end
      end
  end


  // Shifting the registers to the output ports based on MODE
  
  // RX SHIFT REGISTER


  always @(*) begin
      io0_o = 1'bz;
      io1_o = 1'bz;
      io2_o = 1'bz;
      io3_o = 1'bz;

      case(PHASE)
        PH_OPCODE: begin
            case(MODE)
              SINGLE: begin
                  io0_o = opcode_shift[7];
              end
              DUAL: begin
                  io1_o = opcode_shift[7];
                  io0_o = opcode_shift[6];
              end
              QUAD: begin
                  io3_o = opcode_shift[7];
                  io2_o = opcode_shift[6];
                  io1_o = opcode_shift[5];
                  io0_o = opcode_shift[4];
              end
              default : begin
                  io0_o = 1'bz;
                  io1_o = 1'bz;
                  io2_o = 1'bz;
                  io3_o = 1'bz;
              end
            endcase
        end
        PH_ADDRESS: begin
            case(MODE)
              SINGLE: begin
                  io0_o = addr_shift[ADDR_WIDTH-1];
              end
              DUAL: begin
                  io1_o = addr_shift[ADDR_WIDTH-1];
                  io0_o = addr_shift[ADDR_WIDTH-2];
              end
              QUAD: begin
                  io3_o = addr_shift[ADDR_WIDTH-1];
                  io2_o = addr_shift[ADDR_WIDTH-2];
                  io1_o = addr_shift[ADDR_WIDTH-3];
                  io0_o = addr_shift[ADDR_WIDTH-4];
              end
              default : begin
                  io0_o = 1'bz;
                  io1_o = 1'bz;
                  io2_o = 1'bz;
                  io3_o = 1'bz;
              end
            endcase
        end
        PH_MODE: begin
            case(MODE)
              SINGLE: begin
                  io0_o = mode_qior_shift[7];
              end
              DUAL: begin
                  io1_o = mode_qior_shift[7];
                  io0_o = mode_qior_shift[6];
              end
              QUAD: begin
                  io3_o = mode_qior_shift[7];
                  io2_o = mode_qior_shift[6];
                  io1_o = mode_qior_shift[5];
                  io0_o = mode_qior_shift[4];
              end
              default : begin
                  io0_o = 1'bz;
                  io1_o = 1'bz;
                  io2_o = 1'bz;
                  io3_o = 1'bz;
              end
            endcase
        end
        PH_DATA_TX: begin
            case(MODE)
              SINGLE: begin
                  io0_o = tx_shift[DATA_WIDTH-1];
              end
              DUAL: begin
                  io1_o = tx_shift[DATA_WIDTH-1];
                  io0_o = tx_shift[DATA_WIDTH-2];
              end
              QUAD: begin
                  io3_o = tx_shift[DATA_WIDTH-1];
                  io2_o = tx_shift[DATA_WIDTH-2];
                  io1_o = tx_shift[DATA_WIDTH-3];
                  io0_o = tx_shift[DATA_WIDTH-4];
              end
              default : begin
                  io0_o = 1'bz;
                  io1_o = 1'bz;
                  io2_o = 1'bz;
                  io3_o = 1'bz;
              end
            endcase
        end
        default: begin
            io3_o = 1'bz;
            io2_o = 1'bz;
            io1_o = 1'bz;
            io0_o = 1'bz;
        end
      endcase
  end

endmodule
