`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  Sri Sai Nomula
// 
// Create Date: 08.09.2024 21:07:35
// Design Name: 
// Module Name: multicycle
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

module multicycle(
        input clk, rst,
        output [15:0]out
    );

    wire [7:0] PC, datamem_addr;
    wire [15:0] IM, IR, IPR;
    wire PCEn;
    wire PCSrc, IR_Enable, PC_Write, RegWrite, MemtoReg, MemWrite, z, g, ALUSrcA, IPR_Enable, IM_sel;
    wire [1:0] ALUSrcB;
    wire [1:0] ALUControl;
    wire [2:0] OpCode;
    wire [1:0] Funct;
    wire zout,gout;

    assign OpCode = IR[2:0];
    assign Funct = IR[13:12];
            
    Control_Path controller(
        .clk(clk),
        .rst(rst),
        .zout(zout),
        .gout(gout),
        .OpCode(OpCode),
        .Funct(Funct),
        .PCSrc(PCSrc),
        .PC_write(PC_Write),
        .z(z),
        .g(g),
        .IPR_enable(IPR_Enable),
        .IM_sel(IM_sel),
        .IR_enable(IR_Enable),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUControl(ALUControl),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .RegWrite(RegWrite)
    );
                      
    Data_Path datapath(
        .clk(clk),
        .rst(rst),
        .PCSrc(PCSrc),
        .PCEn(PCEn),
        .PC_write(PC_Write),
        .z(z),
        .g(g),
        .PC(PC),
        .IM_sel(IM_sel),
        .Instr(IM),
        .IPR_enable(IPR_Enable),
        .IPR_out(IPR),
        .IR_enable(IR_Enable),
        .Instruction(IR),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUControl(ALUControl),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .RegWrite(RegWrite),
        .datamem_addr(datamem_addr),
        .out(out),
        .zout(zout),
        .gout(gout)
    );
                                                           
endmodule