`timescale 1ns / 1ps

module top_pwm(
    input clk,
    input rst,
    input [3:0] sw,
    output [2:0] rgb
    );
    
    parameter resolution = 8;
    parameter grad_thresh = 2499999; // ((125_000_000/50Hz)-1)
    
    logic [31:0] dvsr = 4882; // sysclk/(pwm_freq * 2**8)
    logic [resolution:0] duty;
    logic pwm_out1;
    
    integer counter;
    logic gradient_pulse;
    logic [resolution:0] duty_reg;
    
    pwm_enhanced #(.R(resolution)) pwm_inst1(.clk(clk), .rst(rst), .dvsr(dvsr), .duty(duty), .pwm_out(pwm_out1));
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            counter <= 0; 
            duty_reg <= 0;   
        end else begin
            if (counter < grad_thresh) begin
                counter <= counter + 1;
                gradient_pulse <= 0;
            end else begin
                counter <= 0;
                gradient_pulse <= 1;
            end
            
            if (gradient_pulse == 1) begin
                duty_reg <= duty_reg + 1;
            end
            
            if (duty_reg == 256) begin
                duty_reg <= 0;
            end    
        end    
    end
    
    assign duty = duty_reg;
    
    assign rgb[0] = (sw == 4'b0000) ? pwm_out1 : 1'b0;
    assign rgb[1] = 0;
    assign rgb[2] = 0;
    
endmodule
