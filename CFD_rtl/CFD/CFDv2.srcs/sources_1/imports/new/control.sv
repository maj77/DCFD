`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: AGH
// Engineer: Marcin Maj
// 
// Create Date: 18.08.2024 08:56:09
// Module Name: control
// Project Name: CFD
// Description: 
// Additional Comments: CFD control module, includes FSM 
//////////////////////////////////////////////////////////////////////////////////


module control #( GATE_DELAY_NS = 2.5
    )(
        input  logic clk            ,
        input  logic rst_p          ,
        input  logic ext_trigger    , // in future probablu it will be received through AXI interface
        input  logic zc_trigger     , // 
        output logic counter_control, // 1 - counter is counting, 0 - counter stops execuntion and resets
        output logic result_proc_cntrl
    );

typedef enum {
    IDLE,
    DATA_PROCESSING,
    PROCESS_RESULT,
    DEAD_TIME
} state_t;

//////////////////////////////////////////////////////////////////////////////////
// FSM LOGIC
state_t STATE, NEXT_STATE;
always_ff @(posedge clk) begin : fsm_ff
  if (rst_p) begin
    STATE <= IDLE;
  end else begin
    STATE <= NEXT_STATE;
  end
end

always_comb begin : fsm_state_c
  //NEXT_STATE <= IDLE; // could be X, 
  case (STATE)
    IDLE: begin 
      if (ext_trigger==1'b1) begin
        NEXT_STATE = DATA_PROCESSING;
      end else begin
        NEXT_STATE = IDLE;
      end
    end
    DATA_PROCESSING: begin 
      if (zc_trigger==1'b1) begin
        NEXT_STATE = PROCESS_RESULT;
      end else begin
        NEXT_STATE = DATA_PROCESSING;
      end
    end
    PROCESS_RESULT : begin 
      NEXT_STATE = IDLE;
    end
    default : begin
      NEXT_STATE = IDLE;
    end
  endcase
end

// in case of combinational process and setting outputs based on STATE, vivado infers latch for counter_control
// always_comb begin : fsm_outputs 
  // case (STATE)
always_ff @(posedge clk) begin : fsm_outputs_ff
  case (NEXT_STATE)
    IDLE: begin
      result_proc_cntrl = 1'b0;
      counter_control = 1'b0;
    end
    DATA_PROCESSING: begin
      counter_control = 1'b1;
    end
    PROCESS_RESULT: begin
      result_proc_cntrl = 1'b1;
      counter_control = 1'b0;
    end
    default: begin
      counter_control   = 1'b0;
      result_proc_cntrl = 1'b0;
    end
  endcase


// assign counter_control = (STATE==PROCESS_RESULT)

end
endmodule
