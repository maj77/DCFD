`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  AGH
// Engineer: Marcin Maj
// 
// Create Date        : 29.07.2023 09:30:28
// Design Name        : CFD 
// Project Name       : Constant Fraction Discriminator
// Target Devices     : temporary for zedboard but final target device is ultrascale
// Tool Versions      : vivado 2018.3
// Additional Comments: First version uses comparator at its output, 
//                      next step is to implement linear interpolation
//////////////////////////////////////////////////////////////////////////////////


module cfd #( IN_WIDTH      = 12,
              PIPE_DLY      = 10,
              ADC_PERIOD_NS = 100
           )( input  logic                clk      ,
              //input  logic                clk_ser  ,
              input  logic                sample_vld_in,
              input  logic                rst_p    ,
              input  logic [IN_WIDTH-1:0] sample_in,
              output logic                pulse_out
            );

localparam SCALE_FACTOR       = 12'b1100_1100_1101; // 0.8 in Q(0.12.12)
localparam SCALE_FACTOR_WIDTH = $bits(SCALE_FACTOR);
localparam SCALED_WIDTH       = SCALE_FACTOR_WIDTH + IN_WIDTH;

localparam ZC_IN_WIDTH        = SCALED_WIDTH + 1;
localparam ZC_IN_FRACT        = SCALE_FACTOR_WIDTH;

localparam ZC_OUT_WIDTH       = 4;
localparam ZC_OUT_FRACT       = 4;

logic [    IN_WIDTH-1:0] input_reg    ;
logic [    IN_WIDTH-1:0] sample_d     ;
logic [SCALED_WIDTH-1:0] sample_d_reg ;
logic [SCALED_WIDTH-1:0] sample_d_mux ;
logic [SCALED_WIDTH-1:0] scaled_sample;

logic signed [ZC_IN_WIDTH-1:0] sub_result       ;
logic signed [ZC_IN_WIDTH-1:0] zc_sample_in[1:0];

logic [ZC_OUT_WIDTH-1:0] zc_result    ;
logic                    zc_result_vld;
logic                    sample_vld_in_r;


logic                    delay_vld, delay_vld_r;



always_ff @(posedge clk) begin
  if(rst_p) begin
    input_reg       <= '{default:0};
    sample_vld_in_r <= 1'b0;
  end else begin
    input_reg       <= sample_in;
    sample_vld_in_r <= sample_vld_in;
  end
end

pipe_dly #( .DATA_WIDTH (IN_WIDTH  ),
            .DELAY      (PIPE_DLY  )
         )i_cfd_pipe_dly(
            .clk   (clk      ),
            .rst_p (rst_p    ),
            .vld_in(sample_vld_in_r),
            .data_i(input_reg),
            .data_o(sample_d ),
            .vld_o (delay_vld)
          );
          
scaler #( .SCALE_FACTOR(SCALE_FACTOR),
          .IN_WIDTH    (IN_WIDTH    )
          // remaining params are calculated automatically           
       ) i_scaler (
          .clk      (clk          ),
          .rst_p    (rst_p        ),
          .data_i   (input_reg    ),
          .data_o   (scaled_sample)
       );

always_ff @(posedge clk) begin
  if(rst_p)
    sample_d_reg <= '{default:0};
  else
    sample_d_reg <= sample_d << SCALE_FACTOR_WIDTH;
end

//assign sample_d_mux = (delay_vld) ? (sample_d_reg << SCALE_FACTOR_WIDTH) : {1'b0,{SCALED_WIDTH-1{1'b1}}};
//assign sub_result = sample_d_mux - scaled_sample;

assign sub_result = scaled_sample - sample_d_reg; // previously it was sample_d_reg - scaled_sample

always_ff @(posedge clk) begin
  if(rst_p) begin
    zc_sample_in <= '{default:0};
  end else begin
    zc_sample_in[0] <= sub_result;
    zc_sample_in[1] <= zc_sample_in[0];
  end
end

zc_interpolator #(.ADC_PERIOD_NS(ADC_PERIOD_NS),
                 .IN_WIDTH(ZC_IN_WIDTH),
                 .IN_FRACT(ZC_IN_FRACT),
                 .OUT_WIDTH(ZC_OUT_WIDTH),
                 .OUT_FRACT(ZC_OUT_FRACT)
) i_zc_interpolator (
                 .clk        (clk            ),
                 .rst_p      (rst_p          ),
//                 .sample_in_vld(sample_in_vld),
                 .sample_in_0(zc_sample_in[1]),
                 .sample_in_1(zc_sample_in[0]),
                 .result     (zc_result      ),
                 .result_vld (zc_result_vld  )
);

endmodule
