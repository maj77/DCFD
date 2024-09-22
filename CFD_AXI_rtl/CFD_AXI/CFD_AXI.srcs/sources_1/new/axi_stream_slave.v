`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  AGH
// Engineer: Marcin Maj
// 
// Create Date        : 07.09.2024 21:21:02
// Design Name        : cfd_axi_stream_slave_if
// Project Name       : Constant Fraction Discriminator
// Tool Versions      : vivado >2018.3
// Additional Comments: Interface based on auto generated axi-stream-slave interface,
//                      it implements fifo, which is useless in current system design
//                      however in case of CDC it's nice to have it. (In that case clock on read port must be added)
//////////////////////////////////////////////////////////////////////////////////

module cfd_axi_stream_slave_if #(
    parameter integer CFD_DATA_WIDTH       = 12,
    parameter integer C_S_AXIS_TDATA_WIDTH = 32 // AXI4Stream sink: Data Width
)(
    //==========================================================
    // SLAVE READ INTERFACE
    //==========================================================
    input  wire                                  S_AXIS_ACLK,     // AXI4Stream sink: Clock
    input  wire                                  S_AXIS_ARESETN,  // AXI4Stream sink: Clock
    output wire                                  S_AXIS_TREADY,   // Ready to accept data in
    input  wire [    C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,    // Data in
    input  wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,    // Byte qualifier - UNUSED
    input  wire                                  S_AXIS_TLAST,    // Indicates boundary of last packet
    input  wire                                  S_AXIS_TVALID,   // Data is in valid
    //==========================================================
    // CFD CONNECTION
    //==========================================================
    input  wire                                  FIFO_DATA_RDY, // cfd is ready for data (will be always 1)
    output wire                                  FIFO_DATA_VLD, // valid from interface to CFD input
    output wire [          CFD_DATA_WIDTH-1 : 0] FIFO_DATA_OUT, // data from interface to CFD
    output wire                                  CFD_TRIGGER    // trigger from testbench
);
// function called clogb2 that returns an integer which has the 
// value of the ceiling of the log base 2.
function integer clogb2 (input integer bit_depth);
  begin
    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
      bit_depth = bit_depth >> 1;
  end
endfunction

    
localparam NUMBER_OF_INPUT_WORDS  = 8; // Total number of input data.
localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1); // bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.

// thermo code?
parameter [1:0] IDLE       = 2'b00, // This is the initial/idle state 
                WRITE_FIFO = 2'b01, // In this state FIFO is written with the input stream data S_AXIS_TDATA
                FIFO_FULL  = 2'b11; // In this state FIFO waits until resources are freed


wire               axis_tready;
reg  [        1:0] fsm_state;        // State variable
wire               fifo_wren;        // FIFO write enable
reg  [bit_num-1:0] write_pointer;    // FIFO write pointer
reg                writes_done;      // sink has accepted all the streaming data and stored in FIFO
reg  [bit_num-1:0] fifo_count;       // FIFO data count
reg  [bit_num-1:0] read_pointer;     // FIFO read_pointer

wire              fifo_rden;         // FIFO read enable
wire              fifo_not_full;

wire                             fifo_data_vld;
reg                              fifo_data_vld_r;
reg [C_S_AXIS_TDATA_WIDTH-1 : 0] fifo_data_out; // used to catch data from generate block
reg [C_S_AXIS_TDATA_WIDTH-1 : 0] stream_data_fifo [0:NUMBER_OF_INPUT_WORDS-1];

// I/O Connections assignments
assign S_AXIS_TREADY = axis_tready;
assign CFD_TRIGGER   = fifo_data_out[12];
assign FIFO_DATA_OUT = fifo_data_out[11:0];
assign FIFO_DATA_VLD = fifo_data_vld_r;


// FSM for reception interface
always @(posedge S_AXIS_ACLK) begin : fifo_rdy_gen
    if (!S_AXIS_ARESETN) begin
        fsm_state <= IDLE;
    end else begin
        case (fsm_state)
            IDLE: 
                if (S_AXIS_TVALID) begin // what if writes_done==1 and S_AXIS_TVALID==1??? xilinx has bugs in design??
                    fsm_state <= WRITE_FIFO;
                end else begin
                    fsm_state <= IDLE;
                end
            WRITE_FIFO: 
                if (writes_done) begin
                    fsm_state <= FIFO_FULL;
                end else begin
                    fsm_state <= WRITE_FIFO;
                end
            FIFO_FULL:
                if (fifo_not_full) begin
                    if (S_AXIS_TVALID) begin
                        fsm_state <= WRITE_FIFO;
                    end else begin
                        fsm_state <= IDLE;
                    end
                end else begin
                    fsm_state <= FIFO_FULL;
                end
        endcase
    end
end

assign fifo_wren     = S_AXIS_TVALID && axis_tready;    // FIFO write enable generation
assign fifo_rden     = fifo_data_vld && FIFO_DATA_RDY;  // probably fifo_data_rdy will be tiehigh in cfd,  probably "assign fifo_rden = fifo_data_rdy" will be also ok

assign fifo_not_full = (fifo_count <= (NUMBER_OF_INPUT_WORDS-1)) ? 1'b1 : 1'b0; // check operator precedence to minimize number of parenthesis
assign axis_tready   = (fsm_state == WRITE_FIFO) && fifo_not_full;
assign fifo_data_vld = (fifo_count > 0) ? 1'b1 : 1'b0;

always @(posedge S_AXIS_ACLK) begin : fifo_data_vld_reg
    if(!S_AXIS_ARESETN) begin
        fifo_data_vld_r <= 1'b0;
    end else begin
        fifo_data_vld_r <= fifo_data_vld;
    end
end

always @(posedge S_AXIS_ACLK) begin : write_pointer_proc
    if(!S_AXIS_ARESETN) begin
        write_pointer <= 0;
        writes_done   <= 1'b0;
    end else if (fifo_not_full) begin
        if (fifo_wren) begin
            write_pointer <= write_pointer + 1; // no nee to decrement, it will overflow to 0
            writes_done   <= 1'b0;
        end
        if (fifo_count == NUMBER_OF_INPUT_WORDS-1) begin
            writes_done <= 1'b1;
        end
    end
end

always @(posedge S_AXIS_ACLK) begin : read_pointer_proc
    if(!S_AXIS_ARESETN) begin
        read_pointer <= 0;
    end else if (fifo_count > 0) begin
        if (fifo_rden) begin
            read_pointer <= read_pointer + 1; // no nee to decrement, it will overflow to 0
        end
    end  
end

always @(posedge S_AXIS_ACLK) begin : fifo_count_proc
    if(!S_AXIS_ARESETN) begin
        fifo_count <= 0;
    end else begin
        if (fifo_rden==1'b1 && fifo_wren==1'b1) begin
            fifo_count <= fifo_count;
        end else if (fifo_rden==1'b1 && fifo_wren==1'b0) begin
            fifo_count <= fifo_count - 1;    
        end else if (fifo_wren==1'b1 && fifo_rden==1'b0) begin
            fifo_count <= fifo_count + 1;
        end
    end
end

always @(posedge S_AXIS_ACLK) begin : write_to_fifo_proc
    if(!S_AXIS_ARESETN) begin
        for (integer n=0; n<NUMBER_OF_INPUT_WORDS; n=n+1) begin // consider rewriting file to sv, since it have more straightforward reset syntax
            stream_data_fifo[n] <= 32'd0;
        end
    end else if (fifo_wren) begin
        stream_data_fifo[write_pointer] <= S_AXIS_TDATA;
    end
end

always @(posedge S_AXIS_ACLK) begin : read_from_fifo_proc
    if(!S_AXIS_ARESETN) begin
        fifo_data_out <= 0;
    end else if (fifo_rden) begin
        fifo_data_out <= stream_data_fifo[read_pointer]; // fifo_data_out is 32b bus
    end
end

endmodule
