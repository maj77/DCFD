`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 22.03.2024 13:03:32
// Design Name: CFD
// Module Name: pipe_dly
// Description: module implements behavioral regitered delay line
// 
//////////////////////////////////////////////////////////////////////////////////


module pipe_dly_behav #( DELAY = 1
    )(
      input  logic clk   ,
      input  logic rst_p ,
      input  logic vld_in,
      input  real  data_i,
      output real  data_o,
      output logic vld_o
    );
    
real  data_d [DELAY-1:0]; 
logic vld    [DELAY-1:0];

always_ff @(posedge clk) begin
    if(rst_p) begin
        data_d <= '{default:0}; //- this type of reset may not work in vivado 2018.3
        vld    <= '{default:0};        
    end else begin
        data_d[0] <= data_i;
        vld[0]    <= vld_in;
        for (int n=1; n<DELAY; n=n+1) begin
            data_d[n] <= data_d[n-1];
            vld[n]    <= vld[n-1];
        end
    end
end

assign data_o = data_d[DELAY-1];
assign vld_o  = vld[DELAY-1];

endmodule
