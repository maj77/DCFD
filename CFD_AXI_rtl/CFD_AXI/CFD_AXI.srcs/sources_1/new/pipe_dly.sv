`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 29.07.2023 09:33:56
// Design Name: CFD
// Module Name: pipe_dly
// Description: module implements regitered delay line
// 
//////////////////////////////////////////////////////////////////////////////////


module pipe_dly #( DATA_WIDTH = 32,
                   DELAY      = 1
               )(
                  input  logic                  clk   ,
                  input  logic                  rst_p ,
                  input  logic                  vld_in,
                  input  logic [DATA_WIDTH-1:0] data_i,
                  output logic [DATA_WIDTH-1:0] data_o,
                  output logic                  vld_o
               );
                          
logic [DATA_WIDTH-1:0] data_d [DELAY-1:0]; 
logic                  vld    [DELAY-1:0];

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
