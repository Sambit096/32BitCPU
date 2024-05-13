
`timescale 1ns/1ps

module AU_32b (input logic [31:0] a,b, // operands 
 input logic [1:0] ALUop, // ADD(ALUop=00), SUB(ALUop
						  //=01), Mult (ALUop =10), divide (ALUop =11)
 input logic clk, // clock signal
 input logic rst_n, //active-low reset signal used 
					//for initialization
 output logic [31:0] s, // The result of add/sub
 output logic [31:0] hi, // The left half of the 
						//product/remainder register for multiply/Divide
 output logic [31:0] lo, // The right half of the 
							//product/remainder register for multiply/Divide
 output logic zero // The zero flag
 );
 logic cin,cout;
 logic flag;
 add_sub_32 addmodule(.a(a),.b(b),.cin(cin),.flag(flag),.ALUop(ALUop),.s(s),.cout(cout));
 divider dividermodule(.clk(clk),.rst_n(rst_n),	.a(dividend),.b(divisor),.lo(quotient),.hi(remainder));
 multiplier multModule(.clk(clk),.rst_n(rst_n), .a(multiplicand), .b(multiplier),.hi(productLeft),.lo(productRight));
always @(posedge clk) begin 
if(ALUop==2'b00) begin
flag<=0;
s<=s;

end
else if(ALUop==2'b01) begin
flag<=1;
s<=s;
end
else if(ALUop==2'b11) begin 
hi<=remainder;
lo<=quotient;
end
else if(ALUop==2'b10) begin 
hi<=productLeft;
lo<=productRight;
end

end

 
endmodule

module add_sub_32 (
	input logic [31:0] a,b,
	input logic cin,
	input flag,
	input logic [1:0] ALUop,
	output logic [31:0]s,
	output cout
 );
        logic c1,c2,c3,c4,c5,c6,c7;
	
		adder_subtractor_4b D1 (.a(a[3:0]), .b(b[3:0]), .cin(ALUop[flag]), .s(s[3:0]), .cout(c1));//first Cin depends on LSB of ALUop[0]
		adder_subtractor_4b D2 (.a(a[7:4]), .b(b[7:4]), .cin(c1), .s(s[7:4]),       .cout(c2));
		adder_subtractor_4b D3 (.a(a[11:8]), .b(b[11:8]), .cin(c2), .s(s[11:8]),    .cout(c3));
		adder_subtractor_4b D4 (.a(a[15:12]),.b(b[15:12]),.cin(c3), .s(s[15:12]),   .cout(c4));
		adder_subtractor_4b D5 (.a(a[19:16]),.b(b[19:16]),  .cin(c4), .s(s[19:16]), .cout(c5));
		adder_subtractor_4b D6 (.a(a[23:20]),.b(b[23:20]),.cin(c5), .s(s[23:20]),   .cout(c6));
		adder_subtractor_4b D7 (.a(a[27:24]),.b(b[27:24]), .cin(c6), .s(s[27:24]),  .cout(c7));
		adder_subtractor_4b D8(.a(a[31:28]),.b(b[31:28]), .cin(c7), .s(s[31:28]),   .cout(cout));
 endmodule


//module 4bit_adder-sub calls carry look-ahead
module adder_subtractor_4b (input logic [3:0] a,b,
                   input logic cin,
                   input logic ctrl, 
                   output logic [3:0] s,
                   output cout );

        logic [3:0] new_b;
        logic ctrl_cin;
         // any one will work if equal to 1. 
         assign ctrl_cin = ctrl | cin;
         // According to opcode new_b will contain XOR of b and ctrl; if add then b,if sub then complement of b.
         assign new_b = b ^ {ctrl_cin,ctrl_cin,ctrl_cin,ctrl_cin};

// calling CLA_4b
CLA_4b add_sub (.a(a), .b(new_b), .cin(cin), .s(s), .cout(cout));

endmodule


//Calculating carries; carry lookahead 4 bit adder 
module CLA_4b (input logic [3:0] a,b,
        input logic cin,
        output logic [3:0] s,
        output logic cout);
        
logic [3:0] P, G;
logic [4:0] C;
assign G = a & b;
assign P = a | b;
assign C[0] = cin;
assign C[1] = G[0] | (P[0] & C[0]);
assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C[0]);
assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C[0]);
assign s = (a ^ b) ^ C[3:0]; 
assign cout = C[4];
endmodule
module multiplier(input logic clk, 
			      input logic rst_n,
				  input logic[31:0] multiplier,
				  input logic[31:0] multiplicand,
				  output logic[31:0] productLeft,
				  output logic[31:0] productRight);
				  
				  

logic[5:0] counter;
logic[63:0] prod_reg;

initial begin  
counter=6'd0;
end 
always@(posedge clk) begin 
$display("counter =%d",counter);
if(!rst_n) begin   //Checking whether reset signal is 0. Then we set everything to 0
productLeft<=0;
productRight<=0;
prod_reg<=0;
counter<=0;
end

else begin   //If reset is 1, then we do the operations
if(counter==0) begin   //check whether counter is 0 for the initial step
prod_reg[63:32]<= 32'd0; //Initializing the left half of the product register to 0
prod_reg[31:0]<=multiplier; //Initializing the right half of the product register to multiplier.

end
else if(counter<6'd33) begin  //Checking whether counter <33. So for 0'th iteration 1 counter(i.e. 0) and for another 32 iterations 32 counters. So when counter is 33 that means it should assign the productLeft and product right
if(prod_reg[0]==1) begin  //If the LSB(Rightmost bit) is 1
prod_reg[63:32]<=prod_reg[63:32]+multiplicand; //Add the left half of the product register with the multiplicant and assign it to the left half of the register
prod_reg[63:0]<=prod_reg[63:0]>>1; //Shift the whole register right by 1 bit.
end
else if(prod_reg[0]==0) begin   //If the LSB(Rightmost bit) is 0
prod_reg[63:0]<=prod_reg[63:0]>>1; //Shift the whole register right by 1 bit.
end
 //Increment the counter till 33

end
counter<=counter+1;
if(counter==6'd33) begin   //If counter is 33
productLeft<=prod_reg[63:32]; //Assign the left half of the prod_reg to productLeft
productRight<=prod_reg[31:0]; //Assign the right half of the prod_reg to productRight
counter<=0; //Reset the counter to 0.
end
end
end
endmodule

//Same logic for divider with the divider algorithm followed

module divider(input logic clk, 
			   input logic rst_n, 
			   input logic[31:0] dividend, 
			   input logic[31:0] divisor, 
			   output logic[31:0] quotient, 
			   output logic[31:0] remainder);


logic[63:0] rem_reg;
logic[5:0] counter;
initial begin 
counter=6'd0;
end
// I've not used while loop to check the counter as the always block
always@(posedge clk) begin 
//$display("counter =%d",counter);


if(!rst_n) begin  
quotient<=32'd0;
remainder<=32'd0;
rem_reg<=64'd0;
counter<=6'd0;
end
else begin 
if(counter==6'd0) begin  
rem_reg[63:32]<=32'h0;
rem_reg[31:0]<=dividend;
rem_reg[63:0]<=rem_reg[63:0]<<1'b1;

end
else if(counter<6'd33) begin 

rem_reg[63:32]<=rem_reg[63:32]-divisor;
if(rem_reg[63]==32'd1) begin  
rem_reg[63:32]<=rem_reg[63:32]+divisor;
rem_reg[63:0]<=rem_reg[63:0]<<1'b1;
rem_reg[0]<=1'b0;
end

else if(rem_reg[63]==1'b0) begin 
rem_reg[63:0]<=rem_reg[63:0]<<1'b1;
rem_reg[0]<=1'b1;
end

end
counter<=counter+1'b1;
if(counter==33) begin 
rem_reg[63:32]<=rem_reg[63:32]>>1'b1;
remainder[31:0]<=rem_reg[63:32];
quotient[31:0]<=rem_reg[31:0];
counter<=1'b0;
end
end
end 
endmodule



/*module testbench();

logic clk,rst_n;
logic [31:0] dividend,divisor;
logic[31:0] multiplier,multiplicand;

logic[31:0] productLeft,productRight;
logic[31:0] remainder, quotient;
divider testdivider(.clk(clk),.rst_n(rst_n),.dividend(dividend),.divisor(divisor),.quotient(quotient),.remainder(remainder));

multiplier testmult(.clk(clk), .rst_n(rst_n),.multiplier(multiplier),.multiplicand(multiplicand),.productLeft(productLeft),.productRight(productRight));
initial begin 
clk<=0;
end
always begin 

#10 clk<=1;
#10 clk<=0;

end

initial begin 
rst_n=0; #200

rst_n=1; #100

multiplier=32'd3; multiplicand=32'd2; #800;
multiplier=32'd5; multiplicand=32'd8; #800;
multiplier=32'd10; multiplicand=32'd2; #800;
dividend=32'd32; divisor=32'd7;  #800;

dividend=32'd8; divisor=32'd4;  #1000;


dividend=32'd8; divisor=32'd4;  #1000;


end

endmodule*/