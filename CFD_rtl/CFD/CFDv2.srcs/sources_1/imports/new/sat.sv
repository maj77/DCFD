`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Marcin Maj
// 
// Create Date: 06.08.2023 10:39:58
// Design Name: CFD
// Module Name: sat
// Description: Fully combinational saturation module, saturates signed values
//////////////////////////////////////////////////////////////////////////////////


module sat #(
      IN_WIDTH = 8,
      OUT_WIDTH = 7
    )(
      input  logic signed [ IN_WIDTH-1:0] data_i,
      output logic signed [OUT_WIDTH-1:0] data_o
    );
    

always_comb begin
  if (data_i[IN_WIDTH-1]) begin
    if (&data_i[IN_WIDTH-2:OUT_WIDTH-1]) begin
      data_o = data_i[OUT_WIDTH-1:0];
    end else begin
      data_o = {1'b1, {(OUT_WIDTH-1){1'b0}}};
    end
  end else begin
    if (|data_i[IN_WIDTH-2:OUT_WIDTH-1]) begin 
     data_o = {1'b0, {(OUT_WIDTH-1){1'b1}}};
    end else begin
      data_o = data_i[OUT_WIDTH-1:0];
    end
  end
end
    
endmodule
