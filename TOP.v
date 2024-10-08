`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.09.2024 16:09:48
// Design Name: 
// Module Name: TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TOP(
    input clk,rst,
    output [6:0]LED_out,
    output [3:0]digit,
    output [15:0]max
    );
    
    //wire  [15:0]Sum;
    multicycle Multicycle(
        .clk(clk), 
        .rst(rst), 
        .out(max)
    );

     seven_segment Seven_segment(
        .clock_100Mhz(clk),
        .reset(rst),
        .displayed_number(max),
        .Anode_Activate(digit),
        .LED_out(LED_out) 
     );
    
endmodule
