`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 22.03.2024 12:45:12
// Design Name: CFD
// Module Name: CFD BEHAVIORAL
// Description: behavioral module of constant fraction discriminator
//////////////////////////////////////////////////////////////////////////////////


module cfd_behav #(
              PIPE_DLY      = 10,
              SCALE_FACTOR  = 0.8,
              ADC_PERIOD_NS = 100
           )( input  logic  clk          ,
              input  logic  rst_p        ,
              input  real   sample_in    ,
              input  logic  sample_in_vld,
              output logic  pulse_out
            );

real input_reg;
real sample_d;
logic delay_vld;
real sample_d_reg;
real sample_d_mux;
real scaled_sample;

real sub_result;
real zc_sample_in [1:0];
logic [63:0] dummy_sample_1, dummy_sample_2;
real zc_result;
integer sub_result_int, scaled_sample_int, sample_in_int;
logic zc_result_vld;
logic sample_in_vld_r;

always_ff @(posedge clk) begin
  if(rst_p) begin
    input_reg       <= 0;
    sample_in_vld_r <= 1'b0;
  end else begin
    input_reg       <= sample_in;
    sample_in_vld_r <= sample_in_vld;
  end
end

assign sample_in_int = $rtoi(sample_in);

pipe_dly_behav#(
            .DELAY(PIPE_DLY)
)i_cfd_pipe_dly(
            .clk   (clk            ),
            .rst_p (rst_p          ),
            .vld_in(sample_in_vld_r),
            .data_i(input_reg      ),
            .data_o(sample_d       ),
            .vld_o (delay_vld      )
          );
          
scaler_behav #(
          .SCALE_FACTOR(SCALE_FACTOR)
) i_scaler (
          .clk      (clk          ),
          .rst_p    (rst_p        ),
          .data_i   (input_reg    ),
          .data_o   (scaled_sample)
       );
 
always_ff @(posedge clk) begin
  if(rst_p)
    sample_d_reg <= 0;
  else
    sample_d_reg <= sample_d;
end      

assign sample_d_mux = (delay_vld) ? sample_d_reg : scaled_sample; // watch out for BUG

assign sub_result = sample_d_mux - scaled_sample;

assign sub_result_int = $rtoi(sub_result);
assign scaled_sample_int = $rtoi(scaled_sample);

always_ff @(posedge clk) begin
  if(rst_p) begin
    zc_sample_in <= '{default:0};
  end else begin
    zc_sample_in[0] <= sub_result;
    zc_sample_in[1] <= zc_sample_in[0];
  end
end

assign dummy_sample_1 = $realtobits(zc_sample_in[0]);
assign dummy_sample_2 = $realtobits(zc_sample_in[1]);

zc_interpolator_behav #(
                 .ADC_PERIOD_NS(ADC_PERIOD_NS)
) i_zc_interpolator (
                 .clk        (clk            ),
                 .rst_p      (rst_p          ),
                 .sample_in_0(zc_sample_in[1]),
                 .sample_in_1(zc_sample_in[0]),
                 .result     (zc_result      ),
                 .result_vld (zc_result_vld  )
);

assign pulse_out = zc_result_vld & delay_vld;
endmodule