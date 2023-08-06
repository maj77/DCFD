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


module cfd #( IN_WIDTH = 32,
              PIPE_DLY = 10
           )( input  logic                clk      ,
              input  logic                clk_ser  ,
              input  logic                rst_p    ,
              input  logic [IN_WIDTH-1:0] sample_in,
              output logic                pulse_out
            );

localparam SCALE_FACTOR       = 12'b1100_1100_1101;
localparam SCALE_FACTOR_WIDTH = $bits(SCALE_FACTOR);
localparam SCALED_WIDTH       = SCALE_FACTOR_WIDTH + IN_WIDTH;
localparam ZERO_CROSS_WIDTH   = SCALED_WIDTH + 1;

logic [    IN_WIDTH-1:0] input_reg         ;
logic [    IN_WIDTH-1:0] sample_d          ;
logic [SCALED_WIDTH-1:0] sample_d_reg      ;
logic [SCALED_WIDTH-1:0] scaled_sample     ;

logic signed [ZERO_CROSS_WIDTH-1:0] sub_result        ;
logic signed [ZERO_CROSS_WIDTH-1:0] result_sample[1:0];
logic                               pulse             ;

logic signed [ZERO_CROSS_WIDTH-1:0] interp_samples [1:0];
logic signed [ZERO_CROSS_WIDTH-1:0] interp_samples_out  ;

always_ff @(posedge clk) begin
  if(rst_p)
    input_reg <= 0;
  else
    input_reg <= sample_in;
end

pipe_dly #( .DATA_WIDTH (IN_WIDTH  ),
            .DELAY      (PIPE_DLY  )
         )i_cfd_pipe_dly(
            .clk   (clk      ),
            .rst_p (rst_p    ),
            .data_i(input_reg),
            .data_o(sample_d )
          );
          
scaler #( .SCALE_FACTOR(SCALE_FACTOR),
          .IN_WIDTH    (IN_WIDTH    )
          // remaining params are calculated automatically           
       ) i_scaler (
          .clk   (clk          ),
          .rst_p (rst_p        ),
          .data_i(input_reg    ),
          .data_o(scaled_sample)
       );

always_ff @(posedge clk) begin
  sample_d_reg <= sample_d << SCALE_FACTOR_WIDTH; // shift from Q(0.32.0) to Q(0.32.12)
end

assign sub_result = sample_d_reg - scaled_sample;

always_ff @(posedge clk) begin
  if(rst_p)
    result_sample <= '{default:0};
  else
    result_sample[0] <= sub_result;
    result_sample[1] <= result_sample[0];
end

// interpolator which operates on base clock
interpolator #( .IN_WIDTH(ZERO_CROSS_WIDTH)
             )( 
                .clk        (clk             ),
                .rst_p      (rst_p           ),
                .sample_in_0(result_sample[1]),
                .sample_in_1(result_sample[0]),
                .samples_out(interp_samples  )
             );


serializer #( .DATA_WIDTH(ZERO_CROSS_WIDTH)
           )(
              .clk_ser (clk_ser           ),
              .clk_par ('b0               ),
              .rst_p   (rst_p             ),
              .data_in (interp_samples    ),
              .data_out(interp_samples_out)
            );
              
              
//always_comb begin
//  if(result_sample[0] > 0 && result_sample[1] < 0)
//    pulse = 1'b1;
//  else
//    pulse = 1'b0;
//end

//assign pulse_out = pulse;
endmodule
