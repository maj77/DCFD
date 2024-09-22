`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  AGH
// Engineer: Marcin Maj
// 
// Create Date        : 17.08.2024 10:01:16
// Design Name        : CFD 
// Project Name       : Constant Fraction Discriminator
// Target Devices     : temporary for zedboard but final target device is ultrascale
// Tool Versions      : vivado 2018.3
// Additional Comments: 4dasquaw
//////////////////////////////////////////////////////////////////////////////////


module scale_delay #(
        IN_WIDTH           = 12    ,
        PIPE_DLY           = 142,
        SCALE_FACTOR_WIDTH = 12    ,
        OUT_WIDTH          = IN_WIDTH + SCALE_FACTOR_WIDTH + 1
    )(
        input  logic                          clk         ,
        input  logic                          rst_p       ,
        input  logic [SCALE_FACTOR_WIDTH-1:0] sf          ,
        input  logic [          IN_WIDTH-1:0] sample_in   ,
        output logic [         OUT_WIDTH-1:0] sample_0_out, // neg_sample in matlab
        output logic [         OUT_WIDTH-1:0] sample_1_out  // pos_sample in matalb
    );

localparam SCALED_WIDTH = SCALE_FACTOR_WIDTH + IN_WIDTH;

logic delay_vld;

logic [    IN_WIDTH-1:0] input_reg    ; // Q(0.12.0)
logic [    IN_WIDTH-1:0] sample_d     ; // Q(0.12.0)
logic [SCALED_WIDTH-1:0] sample_d_reg ; // Q(0.12.12)
logic [SCALED_WIDTH-1:0] scaled_sample; // Q(0.12.12)
logic [SCALE_FACTOR_WIDTH-1:0] sf_r   ; // Q(0.0.12), default value is 12'b1100_1100_1101;

logic signed [OUT_WIDTH-1:0] sub_result       ; // Q(1.12.12)
logic signed [OUT_WIDTH-1:0] zc_sample_in[1:0]; // Q(1.12.12)

always_ff @(posedge clk) begin : input_data_ff
    if (rst_p) begin
        input_reg <= '{default:0};
        sf_r      <= '{default:0};
    end else begin
        input_reg <= sample_in;
        sf_r      <= sf;
    end
end

pipe_dly #( .DATA_WIDTH (IN_WIDTH),
            .DELAY      (PIPE_DLY)
)i_cfd_pipe_dly(
            .clk   (clk      ),
            .rst_p (rst_p    ),
            .vld_in(1'b1     ),
            .data_i(input_reg),
            .data_o(sample_d ),
            .vld_o (delay_vld)
);

scaler #( .IN_WIDTH    (IN_WIDTH          ), 
          .SCALE_WIDTH (SCALE_FACTOR_WIDTH)
) i_scaler (
          .clk      (clk          ),
          .rst_p    (rst_p        ),
          .data_i   (input_reg    ),
          .sf_in    (sf_r         ),
          .data_o   (scaled_sample)
);

always_ff @(posedge clk) begin : scale_delayed_sample_ff
    if(rst_p) begin
        sample_d_reg <= '{default:0};
    end else begin
        sample_d_reg <= sample_d << SCALE_FACTOR_WIDTH; // SCALE_FACTOR_WIDTH always means number of fractional bits, because sf must be within (0,1) range
    end
end
      
assign sub_result  = sample_d_reg - scaled_sample;

always_ff @(posedge clk) begin : output_ffs
    if(rst_p) begin
        zc_sample_in <= '{default:0};
    end else begin
        zc_sample_in[0] <= sub_result;
        zc_sample_in[1] <= zc_sample_in[0];
    end
end

assign sample_0_out = zc_sample_in[1];
assign sample_1_out = zc_sample_in[0];
endmodule
