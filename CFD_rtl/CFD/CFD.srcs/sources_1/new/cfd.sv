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
// Additional Comments: 4dasquaw
//////////////////////////////////////////////////////////////////////////////////


module cfd #( IN_WIDTH           = 12 ,
              OUT_WIDTH          = 16 ,
              PIPE_DLY           = 10 ,
              ADC_PERIOD_NS      = 100, // [TODO]: LHC_PERIOD_NS SHOULD BE MUCH MUCH HIGHER THAN ADC_PERIOD_NS
              LHC_PERIOD_NS      = 25 ,
              SCALE_FACTOR_WIDTH = 12 , // [INFO] Probably it will remain hardcoded
              T_GATE_DELAY_NS    = 2.5
           )( input  logic                          clk              ,
              input  logic                          trigger          ,
              input  logic                          sample_vld_in    ,
              input  logic                          th_passthrough_in,
              input  logic                          rst_p            ,
              input  logic [          IN_WIDTH-1:0] sample_in        ,
              input  logic [SCALE_FACTOR_WIDTH-1:0] sf               ,
              output logic [         OUT_WIDTH-1:0] data_out         ,
              output logic                          pulse_out        ,
              output logic                          th_passthrough_out_vld 
            );

// localparam SCALE_FACTOR       = 12'b1100_1100_1101;   // 0.8 in Q(0.0.12)
// localparam SCALE_FACTOR_WIDTH = 12; //  $bits(SCALE_FACTOR);
localparam SCALED_WIDTH           = SCALE_FACTOR_WIDTH + IN_WIDTH;
localparam ZC_IN_WIDTH            = SCALED_WIDTH + 1;
localparam ZC_IN_FRACT            = SCALE_FACTOR_WIDTH;
localparam ZC_OUT_WIDTH           = 16;
localparam ZC_OUT_FRACT           = 8;
localparam CFD_TOP_PIPELINE_WIDTH = 4; 


logic signed [ ZC_IN_WIDTH-1:0] zc_sample_in[1:0];
logic        [ZC_OUT_WIDTH-1:0] zc_result    ;
logic                           zc_result_vld;
logic                           delay_vld, delay_vld_r;


logic [IN_WIDTH-1:0] passhthrough_data_out;
logic                passthrough_th_out;   

scale_delay #(.IN_WIDTH          (IN_WIDTH          ),
              .PIPE_DLY          (PIPE_DLY          ),
              .SCALE_FACTOR_WIDTH(SCALE_FACTOR_WIDTH)
)i_scale_and_delay(
              .clk         (clk            ),
              .rst_p       (rst_p          ),
              .sf          (sf             ),
              .sample_in   (sample_in      ),
              .sample_0_out(zc_sample_in[0]),
              .sample_1_out(zc_sample_in[1])
);

zc_interpolator #(.ADC_PERIOD_NS(ADC_PERIOD_NS),
                 .IN_WIDTH      (ZC_IN_WIDTH  ),
                 .IN_FRACT      (ZC_IN_FRACT  ),
                 .OUT_WIDTH     (ZC_OUT_WIDTH ),
                 .OUT_FRACT     (ZC_OUT_FRACT ),
                 .RAW_IN_WIDTH  (IN_WIDTH     )
) i_zc_interpolator (
                 .clk               (clk            ),
                 .rst_p             (rst_p          ),
                 .sample_in_0       (zc_sample_in[0]),
                 .sample_in_1       (zc_sample_in[1]),
                 .result            (zc_result      ),
                 .result_vld        (zc_result_vld  )
);

passthrough #(
  .DATA_WIDTH(IN_WIDTH)
)i_passthrough(
  .clk                  (clk                  ),
  .rst_p                (rst_p                ),
  .passth_data_in       (sample_in            ),
  .passth_th_sample_in  (th_passthrough_in    ),
  .passth_data_out      (passhthrough_data_out),
  .passth_th_sample_out (passhthrough_th_out  )
);

assign pulse_out = zc_result_vld;
assign data_out  = zc_result;
assign th_passthrough_out_vld = passhthrough_th_out;

endmodule