`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 13.08.2023 10:38:59
// Design Name: CFD
// Module Name: Counter
// Description: Module counts clock edges
//////////////////////////////////////////////////////////////////////////////////
//
// TODO: counting should be after latching start signal, and should end within 
//       specified amount of time

module counter #( CNT_WIDTH = 12
                )( 
                   input  logic                 clk            ,
                   input  logic                 rst_p          ,
                   input  logic                 counter_control,
                   output logic [CNT_WIDTH-1:0] out_clks
                );

logic [CNT_WIDTH-1:0] cnt_r;

always_ff @(posedge clk) begin : counter_proc
    if (rst_p) begin
        cnt_r <= '{default:0};
    end else begin
        if (counter_control==1'b1) begin
            cnt_r <= cnt_r + 1'b1;
        end else begin
            cnt_r <= '0;
        end
    end
end

assign out_clks = cnt_r;

endmodule