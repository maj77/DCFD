`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  AGH
// Engineer: Marcin Maj
// 
// Create Date        : 17.08.2024 13:11:16
// Design Name        : passthrough 
// Project Name       : Constant Fraction Discriminator
// Target Devices     : temporary for zedboard but final target device is ultrascale
// Tool Versions      : vivado 2018.3
// Additional Comments: passthrough module used for debug purposes, could be used in lab testing
//////////////////////////////////////////////////////////////////////////////////


module passthrough #(
    DATA_WIDTH=12         
)(
    input  logic                  clk                 ,
    input  logic                  rst_p               ,
    input  logic [DATA_WIDTH-1:0] passth_data_in      ,
    input  logic                  passth_th_sample_in ,
    output logic [DATA_WIDTH-1:0] passth_data_out     ,
    output logic                  passth_th_sample_out
);

// scale_and_delay module passthrough
struct {
    logic [IN_WIDTH-1:0] input_reg;
    logic [IN_WIDTH-1:0] dly_reg;
    logic [IN_WIDTH-1:0] interp_input_reg;
    logic [IN_WIDTH-1:0] interp_out_reg;
} SD_data_passthrough; // input data samples passhthrough

struct {
    logic  input_reg=0;
    logic  dly_reg=0;
    logic  interp_input_reg=0;
    logic  interp_out_reg=0;
} SD_th_passthrough; // threshold sample passthrough

// zc_interp module passthrough
struct {
    logic [IN_WIDTH-1:0] input_reg;
    logic [IN_WIDTH-1:0] output_reg;
} zc_data_passthrough;

struct {
    logic input_reg=0;
    logic output_reg=0;
} zc_th_passthrough;


always_ff @(posedge clk) begin : scale_delay_passthrough_input_ff
  if(rst_p) begin
    SD_th_passthrough   <= '{default:0};
    SD_data_passthrough <= '{default:0};
  end else begin
    SD_data_passthrough.input_reg <= passth_data_in;
    SD_th_passthrough.input_reg   <= passth_th_sample_in;
  end
end

logic [1:0] passthrough_vld_unused;
pipe_dly #( .DATA_WIDTH (IN_WIDTH),
            .DELAY      (PIPE_DLY+1) 
)i_passthrough_samp_pipe_dly(
            .clk   (clk                       ),
            .rst_p (rst_p                     ),
            .vld_in(1'b1                      ),
            .data_i(SD_data_passthrough.input_reg),
            .data_o(SD_data_passthrough.dly_reg  ),
            .vld_o (passthrough_vld_unused[0] )
          );

pipe_dly #( .DATA_WIDTH (1       ),
            .DELAY      (PIPE_DLY+1)
)i_passthrough_th_pipe_dly(
            .clk   (clk                      ),
            .rst_p (rst_p                    ),
            .vld_in(1'b1                     ),
            .data_i(SD_th_passthrough.input_reg ),
            .data_o(SD_th_passthrough.dly_reg   ),
            .vld_o (passthrough_vld_unused[1])
          );

// scale_and_delay passthroughs
always_ff @(posedge clk) begin : scale_delay_output_ff
  if(rst_p) begin
    SD_data_passthrough.interp_input_reg <= '{default:0};
    SD_th_passthrough.interp_input_reg   <= '{default:0};
  end else begin
    SD_data_passthrough.interp_input_reg <= SD_data_passthrough.dly_reg;
    SD_th_passthrough.interp_input_reg   <= SD_th_passthrough.dly_reg;
  end
end

always_ff @(posedge clk) begin : zc_interp_input_ff
  if (rst_p) begin
    zc_data_passthrough.input_reg <= '{default:0};
    zc_th_passthrough.input_reg   <= '{default:0};
  end else begin
    zc_data_passthrough.input_reg <= SD_data_passthrough.interp_input_reg;
    zc_th_passthrough.input_reg   <= SD_th_passthrough.interp_input_reg;
  end
end

always_ff @(posedge clk) begin : zc_interp_output_ff
  if (rst_p) begin
    zc_data_passthrough.output_reg <=  '{default:0};
    zc_th_passthrough.output_reg   <=  '{default:0};
  end else begin
    zc_data_passthrough.output_reg <= zc_data_passthrough.input_reg;
    zc_th_passthrough.output_reg   <= zc_th_passthrough.input_reg;
  end
end

assign passth_data_out      = zc_data_passthrough.output_reg;
assign passth_th_sample_out = zc_th_passthrough.output_reg;

endmodule
