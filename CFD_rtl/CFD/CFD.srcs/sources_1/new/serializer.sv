`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////// 
// Engineer: 
// 
// Create Date: 06.08.2023 11:57:51
// Design Name: 
// Module Name: serializer
// Description: convert 3 parallel data streams into serial stream
//
//////////////////////////////////////////////////////////////////////////////////


module serializer#( DATA_WIDTH = 32
    )(
      input  logic                         clk_par      ,
      input  logic                         clk_ser      ,
      input  logic                         rst_p        ,
      input  logic signed [DATA_WIDTH-1:0] data_in [1:0],
      output logic signed [DATA_WIDTH-1:0] data_out     
    );
    
logic [           1:0] cnt_r;
logic [DATA_WIDTH-1:0] data_r;


always_ff @(posedge clk_ser) begin
  if (rst_p) begin
    cnt_r <= 2'd0;
  end else begin
    if (cnt_r < 2'b10)
      cnt_r <= cnt_r + 2'd1;
    else
      cnt_r <= 2'd0;
  end    
end

always_ff @(posedge clk_ser) begin
  data_r <= data_in[cnt_r];
end

assign data_out = data_r;

endmodule
