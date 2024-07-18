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
           )( input  logic                clk              ,
              input  logic                clk_ser          , // clock used for serializer 3x base clock speed
              input  logic                sample_vld_in    ,
              input  logic                th_passthrough_in,
              input  logic                rst_p            ,
              input  logic [IN_WIDTH-1:0] sample_in        ,
              output logic                pulse_out        ,
              output logic                th_passthrough_out_vld 
            );

localparam SCALE_FACTOR       = 12'b1100_1100_1101; // 0.8 in Q(0.12.12)
localparam SCALE_FACTOR_WIDTH = $bits(SCALE_FACTOR);
localparam SCALED_WIDTH       = SCALE_FACTOR_WIDTH + IN_WIDTH;

localparam ZC_IN_WIDTH        = SCALED_WIDTH + 1;
localparam ZC_IN_FRACT        = SCALE_FACTOR_WIDTH;

localparam ZC_OUT_WIDTH       = 4;
localparam ZC_OUT_FRACT       = 4;

localparam CFD_TOP_PIPELINE_WIDTH = 4; 

logic [    IN_WIDTH-1:0] input_reg    ;
logic [    IN_WIDTH-1:0] sample_d     ;
logic [SCALED_WIDTH-1:0] sample_d_reg ;
logic [SCALED_WIDTH-1:0] sample_d_mux ;
logic [SCALED_WIDTH-1:0] scaled_sample;

logic signed [ZC_IN_WIDTH-1:0] sub_result       ;
logic signed [ZC_IN_WIDTH-1:0] sub2_result      ;
logic signed [ZC_IN_WIDTH-1:0] sub_result_d     ;
logic signed [ZC_IN_WIDTH-1:0] sub_result_temp  ;
logic signed [ZC_IN_WIDTH-1:0] sub_result_avg   ;
logic signed [ZC_IN_WIDTH-1:0] zc_sample_in[1:0];

logic signed [ZC_IN_WIDTH+4-1:0] sub_result_mavg;
logic signed [ZC_IN_WIDTH+4-1:0] sub_result_mavg_r0;
logic signed [ZC_IN_WIDTH+4-1:0] sub_result_mavg_r1;

logic [ZC_OUT_WIDTH-1:0] zc_result    ;
logic                    zc_result_vld;
logic                    sample_vld_in_r;

logic                    delay_vld, delay_vld_r;

struct {
    logic [IN_WIDTH-1:0] input_reg;
    logic [IN_WIDTH-1:0] dly_reg;
    logic [IN_WIDTH-1:0] sub_result_reg;
    logic [IN_WIDTH-1:0] interp_input_reg;
    logic [IN_WIDTH-1:0] interp_out_reg;
} data_passthrough; // input data samples passhthrough

struct {
    logic  input_reg=0;
    logic  dly_reg=0;
    logic  sub_result_reg=0;
    logic  interp_input_reg=0;
    logic  interp_out_reg=0;
} th_passthrough; // threshold sample passthrough

always_ff @(posedge clk) begin
  if(rst_p) begin
    input_reg        <= '{default:0};
    sample_vld_in_r  <= 1'b0;
    th_passthrough   <= '{default:0};
    data_passthrough <= '{default:0};
  end else begin
    input_reg                  <= sample_in;
    data_passthrough.input_reg <= sample_in;
    th_passthrough.input_reg   <= th_passthrough_in;
    sample_vld_in_r            <= sample_vld_in;
  end
end

pipe_dly #( .DATA_WIDTH (IN_WIDTH  ),
            .DELAY      (PIPE_DLY-1)
)i_cfd_pipe_dly(
            .clk   (clk      ),
            .rst_p (rst_p    ),
            .vld_in(1'b1     ),
            .data_i(input_reg),
            .data_o(sample_d ),
            .vld_o (delay_vld)
          );

logic [1:0] passthrough_vld_unused;
pipe_dly #( .DATA_WIDTH (IN_WIDTH  ),
            .DELAY      (PIPE_DLY-1)
)i_passthrough_samp_pipe_dly(
            .clk   (clk                       ),
            .rst_p (rst_p                     ),
            .vld_in(1'b1                      ),
            .data_i(data_passthrough.input_reg),
            .data_o(data_passthrough.dly_reg  ),
            .vld_o (passthrough_vld_unused[0] )
          );

pipe_dly #( .DATA_WIDTH (1         ),
            .DELAY      (PIPE_DLY-1)
)i_passthrough_th_pipe_dly(
            .clk   (clk                      ),
            .rst_p (rst_p                    ),
            .vld_in(1'b1                     ),
            .data_i(th_passthrough.input_reg ),
            .data_o(th_passthrough.dly_reg   ),
            .vld_o (passthrough_vld_unused[1])
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

assign sub_result  = sample_d_reg - scaled_sample;
assign sub2_result = scaled_sample - sample_d_reg;

always_ff @(posedge clk) begin
    if(rst_p) begin
        sub_result_d <= '{default:0};
    end else begin
        sub_result_d <= sub_result;
    end
end

assign sub_result_avg = (sub2_result - sub_result_d) >>> 1;

moving_average #(
    .DATA_WIDTH (ZC_IN_WIDTH),
    .NO_AVG_SAMP(16          )
) i_sub_res_avg (
    .clk     (clk            ),
    .rst_p   (rst_p          ),
    .data_in (sub_result     ),
    .data_out(sub_result_mavg)
);  

// This part is for testing zero-cross from moving average of subtraction result 
logic m_avg_zero_cross;
integer m_avg_zc_cnt=0;
always @(posedge clk) begin
    sub_result_mavg_r0 <= sub_result_mavg;
    sub_result_mavg_r1 <= sub_result_mavg_r0;
end

always_comb begin
    if (sub_result_mavg_r1 <= 0 && sub_result_mavg_r0 > 0) begin
        m_avg_zero_cross = 1'b1;
        m_avg_zc_cnt = m_avg_zc_cnt + 1;
    end else begin
        m_avg_zero_cross = 1'b0;
    end
end

// delay samples for zc module (could be optimized by 1 flop)
// delay passthroughs
always_ff @(posedge clk) begin
  if(rst_p) begin
    zc_sample_in <= '{default:0};
  end else begin
    // passthrough data for verification
    data_passthrough.sub_result_reg   <= data_passthrough.dly_reg;
    data_passthrough.interp_input_reg <= data_passthrough.sub_result_reg;
    th_passthrough.sub_result_reg     <= th_passthrough.dly_reg;
    th_passthrough.interp_input_reg   <= th_passthrough.sub_result_reg;
    // acutal samples
    zc_sample_in[0]                   <= sub_result;
    zc_sample_in[1]                   <= zc_sample_in[0];
  end
end

// for testing purposes
logic raw_wave_zc;
always_comb begin
  if (zc_sample_in[1] <= 0 && zc_sample_in[0] > 0) begin
    raw_wave_zc = 1'b1;
  end else begin
    raw_wave_zc = 1'b0;
  end
end

zc_interpolator #(.ADC_PERIOD_NS(ADC_PERIOD_NS),
                 .IN_WIDTH      (ZC_IN_WIDTH  ),
                 .IN_FRACT      (ZC_IN_FRACT  ),
                 .OUT_WIDTH     (ZC_OUT_WIDTH ),
                 .OUT_FRACT     (ZC_OUT_FRACT ),
                 .RAW_IN_WIDTH  (IN_WIDTH     )
) i_zc_interpolator (
                 .clk               (clk                              ),
                 .rst_p             (rst_p                            ),
                 .sample_in_0       (zc_sample_in[1]                  ),
                 .sample_in_1       (zc_sample_in[0]                  ),
                 .result            (zc_result                        ),
                 .result_vld        (zc_result_vld                    ),
                 .passthrough_in    (data_passthrough.interp_input_reg),
                 .passthrough_out   (data_passthrough.interp_out_reg  ),
                 .th_passthrough_in (th_passthrough.interp_input_reg  ),
                 .th_passthrough_out(th_passthrough.interp_out_reg    )
);

assign pulse_out = zc_result_vld;
assign th_passthrough_out_vld = th_passthrough.interp_out_reg;
endmodule
