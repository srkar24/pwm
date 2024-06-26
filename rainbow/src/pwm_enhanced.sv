`timescale 1ns / 1ps

module pwm_enhanced
#(parameter int R = 8)
(
    input logic clk,
    input logic rst,
    input logic [31:0] dvsr,
    input logic [R:0] duty,
    output logic pwm_out
    );

//Counting ticks for PWM switching freq    
logic [31:0] q_reg;
logic [31:0] q_next;
//Counting for duty cycle
logic [R-1:0] d_reg;
logic [R-1:0] d_next;
//Duty cycle count value
logic [R:0] d_ext;
//PMW out
logic pwm_reg;
logic pwm_next;
logic tick;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        q_reg <= 1'b0;
        d_reg <= 1'b0;
        pwm_reg <= 1'b0;
    end else begin
        q_reg <= q_next;
        d_reg <= d_next;
        pwm_reg <= pwm_next;
    end
end

// prescale counter
assign q_next = (q_reg == dvsr) ? 1'b0 : (q_reg + 1'b1);
// duty cycle counter
assign tick = (q_reg == 0) ? 1'b1 : 1'b0;
assign d_next = (tick == 1'b1) ? (d_reg + 1) : d_reg;
assign d_ext = {1'b0, d_reg};
// comparison circuit 
assign pwm_next = (d_ext < duty) ? 1'b1 : 1'b0;
assign pwm_out = pwm_reg;

endmodule