`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.09.2024 14:54:15
// Design Name: 
// Module Name: Control_Path
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


module Control_Path(
    input clk, rst, zout, gout,
    input [2:0]OpCode,
    input [1:0]Funct,
    output reg PCSrc, PC_write, z, g, IPR_enable, IM_sel, IR_enable, ALUSrcA, MemtoReg, MemWrite, RegWrite,
    output reg [1:0] ALUControl, ALUSrcB
    );
    
    reg [4:0] present_state , next_state;
    
    parameter S0=5'b00000, S1=5'b00001, S2=5'b00010, S3=5'b00011,  S4=5'b00100,  S5=5'b00101,  S6=5'b00110,
              S7=5'b00111, S8=5'b01000, S9=5'b01001, S10=5'b01010, S11=5'b01011, S12=5'b01100, S13=5'b01101;
    
    always @(posedge clk) 
        begin
            if (rst)
                present_state <= S0;    //Reset STATE
            else
                present_state <= next_state;
        end
     
    always @ (*)
        begin
            case(present_state)
                // State 0 (Reset State) [Load the First Instruction into Prefetch Register]
                S0 : begin
                        ALUSrcA <= 1'b0;  
                        ALUSrcB <= 2'b01; 
                        ALUControl <= 2'b00; 
                        PCSrc <= 1'b0;      
                        IM_sel <=1'b0;     
                        IPR_enable <= 1'b1; //To Prefetch 
                        IR_enable <= 1'b0; 
                        PC_write <= 1'b0;  
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        next_state <= S1;
                      end
                // State 1 (Fetch) [Load the Instruction from Prefetch Register to Fetch Register and Calculate the next PC Value]
                S1 : begin
                        ALUSrcA <= 1'b0;  //To Select Present PC and Increment it to next PC Address meanwhile
                        ALUSrcB <= 2'b01; //To Increment the Present PC by 1 PC <- PC + 1
                        ALUControl <= 2'b00; //To perform Addition Operation in ALU
                        PCSrc <= 1'b0;     //To store the next PC Value we have computed from the ALU 
                        IM_sel <=1'b1;     
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b1; //To store the Instruction into the IR Register
                        PC_write <= 1'b0;  
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        next_state <= S2;
                    end
         
                // State 2 (Decode)[We will do Prefetching and Decode the Instruction based on the OpCode and Access the Contents of Reg File]
                S2 : begin
                        ALUSrcA <= 1'b0;
                        ALUSrcB <= 2'b01;
                        ALUControl <= 2'b00;
                        PCSrc <= 1'b0;
                        IR_enable <= 1'b0; //We should not change Instruction. So, IR Register is disabled
                        PC_write <= 1'b1;   //We should Write the Next PC Value [PC -> PC + 1 ]
                        IM_sel <=1'b1;     //We need to get the next Instruction into the PreFetch Register
                        IPR_enable <= 1'b1; //Save the next instruction into Prefetch Register
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        //Move to the next state based on the OpCode          
                        if (OpCode == 3'b000) begin next_state <= S3; end// R type
                        else if (OpCode == 3'b001 || OpCode == 3'b010) begin next_state <= S5; end// Load or Store
                        else if (OpCode == 3'b110) begin next_state <= S8; end// JUMP
                        else if (OpCode == 3'b100) begin next_state <= S9; end// BEQ
                        else if (OpCode == 3'b101) begin next_state <= S10; end // BGE
                        else if (OpCode == 3'b011) begin next_state <= S11; end // ADD Immediate
                        else if (OpCode == 3'b111) begin next_state <= S13; end// HLT
                        else next_state <= S2;
                    end
                
                //State 3 (R-type Execute)[We will perform the desired operation on the Registers]
                S3 : begin
                        ALUSrcA <= 1'b1;    //To Select ALU Operand-1 from Reg File
                        ALUSrcB <= 2'b00;   //To Select ALU Operand-2 from Reg File
                        ALUControl <= Funct; //To Perform ALU Operation based on the Function Field In Instruction
                        PCSrc <= 1'b0;
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;	    //Keep Pointing to the Next PC Value from PC Register
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;                    
                        next_state <= S4;
                     end
                
                //State 4 (ALU WriteBack) [] 
                S4 : begin
                        ALUSrcA <= 1'b0;
                        ALUSrcB <= 2'b00;
                        ALUControl <= 2'b00;
                        PCSrc <= 1'b0;
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        MemtoReg <= 1'b0;    // We need to Store the ALU Result not from Data Memory
                        RegWrite <= 1'b1;    //We need to Store the Values into Registers
                        MemWrite <= 1'b0;
                        next_state <= S1;
                     end
                
                //State 5 (Load/Store MemAddr) [Calculating the Addr]
                S5 : begin
                        ALUSrcA <= 1'b1;    //To select the Source Address from Register File
                        ALUSrcB <= 2'b10;   //To select the Immediate Value that needs to be added 
                        ALUControl <= 2'b00;  //To Peform Addition
                        PCSrc <= 1'b0; 
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        MemtoReg <= 1'b0;
                        RegWrite<= 1'b0;
                        MemWrite <= 1'b0;
                        if (OpCode == 3'b001)   next_state <= S6;
                        else    next_state <= S7;
                     end
                
                //State 6 (Load MemRead)
                S6 : begin
                        //ALUSrcA <= 1'b0;
                        //ALUSrcB <= 2'b00;
                        //ALUControl <= 2'b00;
                        PCSrc <= 1'b0;
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        
                        MemtoReg <= 1'b1;       //We need to Write the Data from memory location to Register
                        RegWrite <= 1'b1;       //We need to write into Register File
                        MemWrite <= 1'b0;
                        next_state <= S1;
                     end
                 
                 //State 7 (Store MemWrite)
                 S7 : begin
                        //ALUSrcA <= 1'b0;
                        //ALUSrcB <= 2'b00;
                        //ALUControl <= 2'b00;
                        PCSrc <= 1'b0;
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        
                        MemtoReg <= 1'b0;   
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b1;   //We need to Write into Memory
                        next_state <= S1;
                      end
                      
                 //State 8 (Jump)
                 S8 : begin
                        //ALUSrcA <= 1'b0;
                        //ALUSrcB <= 2'b00;
                        //ALUControl <= 2'b00;
                        PCSrc <= 1'b1;      //We need to branch to the Immediate value provided
                        PC_write <= 1'b1;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable<= 1'b0;
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;
                        next_state <= S0;
                      end
                      
                 //State 9 (Branch on Equal)
                 S9 : begin
                        ALUSrcA <= 1'b1;        //To select the first operand from Reg-1
                        ALUSrcB <= 2'b00;       //To select the second operand from Reg-2
                        ALUControl <= 2'b01;    //To perform Subtraction
                        PCSrc <= 1'b1;          //We will keep the Branching address at the input of PC [If Branch is taken we will load with this]
                        PC_write <= 1'b0;
                        z <= 1'b1;              //To indicate we are performing Equal operation, this makes PCEnable if result is Zero
                        g <= 1'b0;
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;                        
                        if(zout==1'b1)
                            next_state <= S0;  //Branch is Taken 
                        else
                            next_state <= S1;  //Branch is Not Taken
                      end
                      
                 //State 10 (Branch on Greater than)
                 S10 : begin
                        ALUSrcA <= 1'b1;        //To get the first operand from Register -1
                        ALUSrcB <= 2'b00;       //To get the second operand from Register -2
                        ALUControl<= 2'b01;     //To perfomr Subtraction
                        PCSrc <= 1'b1;          //We will keep the Branching address at the input of PC [If Branch is taken we will load with this]
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b1;              //To indicate we are performing Greater than operation, this makes PCEnable if result is Greater than
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;
                        if(gout==1'b1)
                            next_state <= S0;      //Branch is Taken
                        else if(gout==1'b0)
                            next_state <=S1;       //Branch is Not Taken
                       end
                 
                 //State 11 (Add Immediate Execute)
                 S11 : begin
                        ALUSrcA <= 1'b1;        //To get the first value from Register File
                        ALUSrcB <= 2'b10;       //To Select the second value from Immediate value
                        ALUControl <= 2'b00;    //To perform Addition Operation
                        PCSrc <= 1'b0;    
                        PC_write <= 1'b0; 
                        z <= 1'b0;
                        g <= 1'b0;   
                        IM_sel <=1'b0;  
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;
                        next_state <= S12;
                       end
                       
                 //State 12 (ADDI WriteBack)
                 S12 : begin
                        //ALUSrcA <= 1'b0;
                        //ALUSrcB <= 2'b00;
                        //ALUControl <= 2'b00;
                        PCSrc <= 1'b0;
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0;
                        
                        MemtoReg <= 1'b0;       //We need to save the ALU Result into Register
                        RegWrite <= 1'b1;       //To Write into the Register
                        MemWrite <= 1'b0;
                        next_state <= S1;
                       end

                //State 13(Halt State)
                S13 : begin
                        ALUSrcA <= 1'b1;
                        ALUSrcB <= 2'b00;
                        ALUControl <= 2'b00;
                        PCSrc <= 1'b0;
                        PC_write <= 1'b0;
                        z <= 1'b0;
                        g <= 1'b0;
                        IM_sel <=1'b0;      
                        IPR_enable <= 1'b0;
                        IR_enable <= 1'b0; 
                        MemtoReg <= 1'b0;
                        RegWrite <= 1'b0;
                        MemWrite <= 1'b0;
                        next_state <= S13;
                      end
            endcase
        end    
   
endmodule
