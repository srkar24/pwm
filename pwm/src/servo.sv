`timescale 1ns / 1ps

module servo_pwm
(
input wire clk,
input wire rst,
output wire servo,
input wire[3:0] sw
);

    parameter resolution = 8;
    parameter grad_thresh = 1249999; // ((125_000_000/50Hz*2)-1)
    logic [31:0] dvsr = 4882; // sysclk/(pwm_freq * 2**8)
    
    logic pwm_out_sine;
    
    logic clk_pulse;
    integer counter;
    
    logic [resolution:0] duty_reg2;
    logic [resolution:0] duty_sine;
    logic [resolution:0] sine_data;
    logic [resolution:0] addr;
    
    logic [resolution-1:0] rom [0:(2**resolution)-1];
    integer signed angle, sin_scaled;
    logic signed [11:0] MATH_PI = 12'b1111_0101_1011;
    integer i;
    
    always @(*) begin
        for (i=0; i<(2**resolution-1); i=i+1) begin
            angle = (i) * ((2 * MATH_PI) / (2**resolution));
            sin_scaled = (1 + $sin(angle)) * (2**resolution - 1) / 2;
            rom [i] = $floor(sin_scaled);  
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= 1'b0;
            clk_pulse <= 1'b0;
        end else begin
            if (counter < 12500000) begin
                counter <= counter + 1;
            end else begin
                counter <= 0;
                clk_pulse <= ~clk_pulse;
            end
        end 
    end
    
    //For the sine pwm dimmer
    always @(posedge clk_pulse) begin
        if (rst) begin
            duty_reg2 <= 1'b0;
        end else begin
            if (duty_reg2 <= 2**resolution) begin
                addr <= addr + 1;
                sine_data <= rom [addr];
                duty_reg2 <= {1'b0, sine_data};
            end else begin
                duty_reg2 <= 0;
            end 
        end 
    end    
    
    pwm_enhanced #(.R(resolution)) pwm_inst2(.clk(clk), .rst(rst), .dvsr(dvsr), .duty(duty_sine), .pwm_out(pwm_out_sine));

    assign duty_sine = duty_reg2;
    assign servo = (sw == 4'b0000) ? pwm_out_sine:0;

endmodule