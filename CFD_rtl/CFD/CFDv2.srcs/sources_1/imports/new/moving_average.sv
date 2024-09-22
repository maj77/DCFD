`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AGH
// Engineer: Marcin Maj
// 
// Create Date: 30.05.2024 00:30:01
// Additional Comments: POSSIBLE AVERAGING OVER 4 and 8 samples
// 
//////////////////////////////////////////////////////////////////////////////////


module moving_average #(
    DATA_WIDTH = 24,
    NO_AVG_SAMP = 4
)(  
    input  logic                              clk,
    input  logic                              rst_p,
    input  logic signed [DATA_WIDTH-1:0            ] data_in,
    output logic signed [DATA_WIDTH+NO_AVG_SAMP-1:0] data_out
);
                      
logic signed [DATA_WIDTH-1:0            ] sample_r [NO_AVG_SAMP-1:0];
logic signed [DATA_WIDTH+NO_AVG_SAMP-1:0] sample_sum;
//logic [DATA_WIDTH+NO_AVG_SAMP-1:0] sample_sum2

always @(posedge clk) begin
    if (rst_p == 1'b1) begin
        sample_r <= '{default:0};
    end else begin
        sample_r[0] = data_in;
        for(integer i=1; i<NO_AVG_SAMP; i=i+1) begin
            sample_r[i] <= sample_r[i-1];
        end
    end
end

//always_comb begin
//    sample_sum = '{default:0};
//    for(integer i=0; i<NO_AVG_SAMP; i=i+1) begin
//        sample_sum = sample_sum + sample_r[i];
////        $display("iter %d", i);
//    end
//end

//always_ff @(posedge clk) begin
//    data_out <= sample_sum;
//end
generate 
    if (NO_AVG_SAMP == 4)
        assign sample_sum = sample_r[0] + sample_r[1] + sample_r[2] + sample_r[3]; // couldn't parametrize this sum....
    else if (NO_AVG_SAMP == 8)
        assign sample_sum = sample_r[0] + sample_r[1] + sample_r[2] + sample_r[3] + sample_r[4] + sample_r[5] + sample_r[6] + sample_r[7];
    else if (NO_AVG_SAMP == 16)
        assign sample_sum = sample_r[0] + sample_r[1] + sample_r[2] + sample_r[3] + sample_r[4] + sample_r[5] + sample_r[6] + sample_r[7] + sample_r[8] + sample_r[9] + sample_r[10] + sample_r[11] + sample_r[12] + sample_r[13] + sample_r[14] + sample_r[15];
endgenerate

assign data_out = sample_sum >>> $clog2(NO_AVG_SAMP);

endmodule
