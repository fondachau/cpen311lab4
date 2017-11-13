
`default_nettype none
module lab4top(

    //////////// CLOCK //////////
    CLOCK_50,

    //////////// LED //////////
    LEDR,

    //////////// KEY //////////
    KEY,

    //////////// SW //////////
    SW,

    //////////// SEG7 //////////
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5,


);

//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input                       CLOCK_50;

//////////// LED //////////
output           [9:0]      LEDR;

//////////// KEY //////////
input            [3:0]      KEY;

//////////// SW //////////
input            [9:0]      SW;

//////////// SEG7 //////////
output           [6:0]      HEX0;
output           [6:0]      HEX1;
output           [6:0]      HEX2;
output           [6:0]      HEX3;
output           [6:0]      HEX4;
output           [6:0]      HEX5;


//=======================================================
//  REG/WIRE declarations
//=======================================================
// Input and output declarations
logic CLK_50M;
logic  [7:0] LED;
assign CLK_50M =  CLOCK_50;
assign LEDR[7:0] = LED[7:0];

wire Clock_1KHz, Clock_1Hz;
wire Sample_Clk_Signal;

       
logic [7:0] Seven_Seg_Val[5:0];
logic [3:0] Seven_Seg_Data[5:0];
    
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst0(.ssOut(Seven_Seg_Val[0]), .nIn(Seven_Seg_Data[0]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst1(.ssOut(Seven_Seg_Val[1]), .nIn(Seven_Seg_Data[1]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst2(.ssOut(Seven_Seg_Val[2]), .nIn(Seven_Seg_Data[2]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst3(.ssOut(Seven_Seg_Val[3]), .nIn(Seven_Seg_Data[3]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst4(.ssOut(Seven_Seg_Val[4]), .nIn(Seven_Seg_Data[4]));
SevenSegmentDisplayDecoder SevenSegmentDisplayDecoder_inst5(.ssOut(Seven_Seg_Val[5]), .nIn(Seven_Seg_Data[5]));

assign HEX0 = Seven_Seg_Val[0];
assign HEX1 = Seven_Seg_Val[1];
assign HEX2 = Seven_Seg_Val[2];
assign HEX3 = Seven_Seg_Val[3];
assign HEX4 = Seven_Seg_Val[4];
assign HEX5 = Seven_Seg_Val[5];
 



logic [31:0]Q;
logic [7:0]address;
logic [7:0]data;
logic wren;
logic [7:0]address1;
logic [7:0]data1;
logic wren1;
logic [7:0]address2;
logic [7:0]data2;
logic wren2;
logic [7:0] datain;
logic reset;
logic writing;
logic doneinput;
logic swapping;
logic doneswap;
logic restartcounter1;
logic restartcounter2;
logic [31:0] count;
logic [31:0] j;
logic [23:0] secret_key_24_bit;
logic test;
logic [7:0] valuei;
logic [7:0] valuej;

counter counterinmemory (.clk(CLK_50M), .reset(restartcounter1),.Q(Q),.writing(writing));
counter counterswapmemory (.clk(doneswap), .reset(doneinput), .Q(count),.writing(swapping));
statemachine1 storingmemory(.clk(CLK_50M),.reset(reset),.writing(writing),.doneinput(doneinput),.wren(wren1),.address(address1),.data(data1),.Q(Q));
statemachine2 swappingmemory(.clk(CLK_50M),
.reset(reset), 
.swapping(swapping), 
.wren(wren2),
.doneswap(doneswap),
.j(j),
.data(data2),
.valuej(valuej),
.valuei(valuei),
.count(count),
.secret_key_24_bit(secret_key_24_bit),
.address(address2),
.datain(datain)
);


//wren write read enable?1 write? looks like always reading value
s_memory forloop1(.address(address),.clock(CLK_50M),.data(data),.wren(wren),.q(datain));
mux2 muxaddress(.sel(writing), .a(address2),.b(address1),.c(address));
mux2 muxdata(.sel(writing), .a(data2),.b(data1),.c(data));
mux2 muxwren(.sel(writing), .a(wren2),.b(wren1),.c(wren));
assign LED[7:0]=KEY[2]?count:{writing,doneswap,doneinput,swapping,restartcounter1,restartcounter2,wren2,wren1};
//assign LED[0] = writing;
//assign LED[1] =doneswap;
//assign LED[2] =doneinput;
//assign LED[3] =swapping;
//assign LED[4] = restartcounter1;
//assign LED[5] =restartcounter2;
//assign LED[6] =wren2;
//assign LED[7] =wren1;


assign secret_key_24_bit = 24'b00000000_00000010_01001001;

endmodule 


module counter(input logic clk, 
input logic reset,
 output logic [31:0] Q,
 output logic writing);
always_ff @ (posedge (clk))
begin 
	if (reset)
		begin
		Q=32'b0;
		writing=1'b0;
		end
	else if (Q>32'd255)begin
		Q=Q;
		writing<=1'b1;
		end
	else begin
		Q=Q+32'b1;
		writing=1'b0;
		end
end
endmodule

module counter2(input logic clk, 
input logic reset,
 output logic [31:0] Q,
 output logic writing);
always_ff @ (posedge (clk))
begin 
	if (reset)
		begin
		Q<=32'b0;
		writing<=1'b0;
		end
	else if (Q>32'd256)begin
		Q<=Q;
		writing<=1'b1;
		end
	else begin
		Q<=Q+32'b1;
		writing<=1'b0;
		end
end
endmodule



module statemachine2 (input logic clk, 
input logic reset, 
input logic swapping, 
output logic wren, 
output logic doneswap,
input logic [7:0] datain,
output logic [7:0] data,
output logic [7:0] address, 
input logic [31:0] count,
output logic [31:0] j,
output logic [7:0] valuei,
output logic [7:0] valuej,
input logic [23:0]secret_key_24_bit);
//logic [31:0] i;
logic [4:0] state;


byte  secret_key [3];
parameter [4:0] idle = 5'b00000;
parameter [4:0] readi = 5'b01001;
parameter [4:0] waitreadi = 5'b01100;
parameter [4:0] storereadi = 5'b01000;
parameter [4:0] determinj = 5'b00001;
parameter [4:0] readj = 5'b10001;
parameter [4:0] waitreadj = 5'b10100;
parameter [4:0] storereadj = 5'b10101;
parameter [4:0] writei = 5'b00010;
parameter [4:0] writej = 5'b00011;
parameter [4:0] waitwritei = 5'b10011;



assign secret_key[0] = secret_key_24_bit[23:16];                           //initializing first part of secret key
assign secret_key[1] = secret_key_24_bit[15:8];                           //initializing second part of secret key
assign secret_key[2] = secret_key_24_bit[7:0];  
assign wren = state[1];
always_ff @ (posedge clk, posedge reset)
	begin
	if (reset) state<=idle;
	else 
		begin
		case(state)
		
		idle: if(swapping==0)begin
		state<=readi;
		end
		else 
		state<=idle;
		
		readi: if(swapping==0)
		begin
		doneswap=1'b0;
		state<=waitreadi;
		address<=count[7:0];
		end
		else
		begin 
		state<=idle;
		end
		
		
		waitreadi:
		state<=storereadi;
		
		storereadi:
		begin
		state<=determinj;
		valuei<=datain;
		data<=datain;
		end
		
		determinj:
		begin
		j<=(j+valuei+ secret_key[(count %3)])%256;
		state<=readj;
		end
		
		readj:
		begin
		state<=waitreadj;
		address<=j[7:0];
		end
		
		
		waitreadj:state<=storereadj;
		
		storereadj:
		begin
		state<=writej;
		valuej<=datain;
		end
		
		writej:
		begin
		address<=j[7:0];
		data<=valuei;
		state<=writei;
		end 
		
		writei:
		begin
		state<=waitwritei;
		address<=count[7:0];
		data<=valuej;
		doneswap<=1'b1;
		end
		
		waitwritei:
		state<=readi;
		
		default:state<=idle;
		endcase
		end
		end
endmodule

/*
module statemachine2 (input logic clk, 
output logic test,
input logic reset, 
input logic swapping, 
output logic wren, 
output logic doneswap,
input logic [7:0] datain,
output logic [7:0] data,
output logic [7:0] address, 
output logic [31:0] count,
output logic [7:0] j,
input logic [23:0]secret_key_24_bit);
//logic [31:0] i;
logic [2:0] state;
logic [7:0] valuei;
logic [7:0] valuej;

byte  secret_key [3];
parameter [3:0] idle = 4'b0000;
parameter [3:0] writei = 4'b0010;
parameter [3:0] determinj = 4'b0001;
parameter [3:0] writej = 4'b0011;
parameter [3:0] waitreadj = 4'b1101;
parameter [3:0] waitreadi = 4'b1100;
parameter [3:0] readi = 4'b0100;
parameter [3:0] readj = 4'b0101;

assign secret_key[0] = secret_key_24_bit[7:0];                           //initializing first part of secret key
assign secret_key[1] = secret_key_24_bit[15:8];                           //initializing second part of secret key
assign secret_key[2] = secret_key_24_bit[23:16];  
assign wren = state[1];

always_ff @ (posedge clk, posedge reset)
	begin
	if (reset) state<=idle;
	else 
		begin
		case(state)
		
		idle: if(count<256)begin
			state<=readi;
			doneswap<=1'b0;

			end
			else begin 

			state<=idle;
			doneswap<=1'b0;
			end
		readi: 
			begin
			doneswap<=1'b0;
			state<=waitreadi;
			address<=count[7:0];
			valuei<=datain;
			end
		waitreadi:begin
			state<=determinj;
			address<=count[7:0];
			valuei<=datain;
			end
		determinj:
			begin
			
			j<=j+valuei+ secret_key[(count %3)];
			state<=readj;
			end
		
		readj:
			begin
			state<=waitreadj;
			address<=j;
			valuej<=datain;
			end
		waitreadj:begin
			state<=writei;
			address<=j;
			valuej<=datain;
			end
		writei:
			begin
			state<=writej;
			address<=count[7:0];
			data<=valuej;
			end 
		
		writej:if (count>255) begin
			state<=idle;
			address<=j;
			data<=valuei;
			doneswap<=1'b1;
			test=1'b0;
			end
			else
			begin
			address<=j;
			data<=valuei;
			state<=readi;
			doneswap<=1'b1;
			count<=count+32'b1;
			test=1'b1;
			end
		
		default:state<=idle;
		endcase
		end
		end
endmodule
*/

module statemachine1 (input logic clk,
 input logic reset,
 input logic writing, 
 output logic wren,
 output logic doneinput,
 output logic [7:0] data,
 output logic [7:0] address,
 input logic [31:0] Q);
logic [2:0] state;
parameter [2:0] idle = 3'b000;
parameter [2:0] write = 3'b010;
parameter [2:0] wait1 = 3'b110;
always_ff @ (posedge clk, posedge reset)
	begin
	if (reset) state<=idle;
	else 
		begin
		case(state)
		idle: if(writing==0)begin
			state<=write;
			end
			else
			begin 
	
			state<=idle;
			doneinput<=1'b0;
			end
		write:if(writing==0)begin

			address<=Q[7:0];
			data<=Q[7:0];
			state<= write;
			end	
			else begin
			state<=idle;
			doneinput<=1'b1;
			address<=Q[7:0];
			data<=Q[7:0];
			end
	
		default: state<=idle;
		endcase
		end//end else 
		end//end alwaysff
		
assign wren = state[1];
endmodule

module mux2 #(parameter width = 32)(input logic sel, input logic [width-1:0] a,input logic [width-1:0] b,output logic [width-1:0] c);
assign c=sel?a:b;
endmodule
