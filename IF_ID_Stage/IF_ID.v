`timescale 1ns/1ps
module IF_ID
#(
    parameter [31:0] RESET = 32'h0000_0000
)
(
    input                   clk,
    input                   reset,
    input                   stall,
    output reg              exception,

    // Instruction memory interface
    input                   inst_mem_is_valid,
    input  [31:0]           inst_mem_read_data,

    // ----------------------------- // Signals previously read from pipe  // -----------------------------
    input                   stall_read_i,
    input  [31:0]           inst_fetch_pc,
    input  [31:0]           instruction_i,

    // -----------------------------    // WB-stage signals (passed in)    // -----------------------------
    input                   wb_stall,
    input                   wb_alu_to_reg,
    input                   wb_mem_to_reg,
    input  [4:0]            wb_dest_reg_sel,
    input  [31:0]           wb_result,
    input  [31:0]           wb_read_data,

    // -----------------------------    // Instruction memory address info    // -----------------------------
    input  [1:0]            inst_mem_offset,
    output [31:0] execute_immediate_w,
    output        immediate_sel_w,
    output        alu_w,
    output        lui_w,
    output        jal_w,
    output        jalr_w,
    output        branch_w,
    output        mem_write_w,
    output        mem_to_reg_w,
    output        arithsubtype_w,
    output [31:0] pc_w,
    output [4:0]  src1_select_w,
    output [4:0]  src2_select_w,
    output [4:0]  dest_reg_sel_w,
    output [2:0]  alu_operation_w,
    output        illegal_inst_w,
    output [31:0] instruction_o
);

//////////////// Including OPCODES ////////////////////////////
`include "opcode.vh"
//////////////////////////////
//////////////////////////////// LOCAL INTERNAL SIGNALS////////////////////////////////////////////////////////////

reg  [31:0] immediate;
reg         illegal_inst;

////////////////////////////////////////////////////////////// IF stage////////////////////////////////////////////////////////////


// TODO-1:
// Implement IF-stage instruction selection.
// - On stall_read_i = 1, insert a NOP
// - Otherwise, pass instruction/data from instruction memory

assign instruction_o = stall_read_i ? NOP : /* TODO-1*/

////////////////////////////////////////////////////////////// Exception detection////////////////////////////////////////////////////////////

// TODO-2:
// Assert exception when:
// - illegal instruction is detected
// - instruction fetch is misaligned (inst_mem_offset != 2'b00)

always @(posedge clk or negedge reset) begin
    if (!reset)
        exception <= 1'b0;
    else if (illegal_inst || inst_mem_offset != 2'b00)
        exception <= /* TODO-2*/;
end
////////////////////////////////////////////////////////////// ID stage: immediate generation///////////////////////////////////////////////////////////

// Generate 32-bit immediates for:
// JAL, JALR, BRANCH, LOAD, STORE, ARITH-I, LUI
// For unsupported opcodes, set illegal_inst = 1
//
// Definitions:
// - instruction_i[31] is the sign bit
// - "Sign-extend" means: replicate instruction_i[31] to fill all unused MSBs
// - The number of replicated bits is implied by the immediate bit ranges below
// - All immediates must be exactly 32 bits wide

always @(*) begin
	immediate	= 32'h0;
	illegal_inst = 1'b0;

	case (instruction_i[`OPCODE])

    	// JALR:
    	// Lower 12 bits  = instruction_i[31:20]
    	// Upper 20 bits  = Sign-extend
    	JALR  : immediate = {{20{instruction_i[31]}}, instruction_i[31:20]};

    	// BRANCH:
    	// immediate[12]   = instruction_i[31]   (sign bit)
    	// immediate[11]   = instruction_i[7]
    	// immediate[10:5] = instruction_i[30:25]
    	// immediate[4:1]  = instruction_i[11:8]
    	// immediate[0]	= 1'b0
    	// immediate[31:13]= Sign-extend
    	BRANCH: immediate = // TODO: assemble bits exactly as specified above

    	// LOAD:
    	// Lower 12 bits  = instruction_i[31:20]
    	// Upper 20 bits  = Sign-extend
    	LOAD  : immediate = // TODO: assemble bits exactly as specified above

    	// STORE:
    	// Lower 5 bits   = instruction_i[11:7]
    	// Next 7 bits	= instruction_i[31:25]
    	// Upper 20 bits  = Sign-extend
    	STORE : immediate = // TODO: assemble bits exactly as specified above

    	// ARITH-I:
    	// If FUNC3 is SLL or SR:
    	//   immediate[4:0]  = instruction_i[24:20]
    	//   immediate[31:5] = 0
    	// Else:
    	//   Lower 12 bits  = instruction_i[31:20]
    	//   Upper 20 bits  = Sign-extend
    	ARITHI: immediate =
             	(instruction_i[`FUNC3] == SLL ||
              	instruction_i[`FUNC3] == SR)
             	? // TODO: assemble bits exactly as specified above
             	: {{20{instruction_i[31]}}, instruction_i[31:20]};


    	// ARITH-R:
    	// No immediate
    	ARITHR: immediate = 32'h0;

    	// LUI:
    	// Upper 20 bits = instruction_i[31:12]
    	// Lower 12 bits = 0
    	LUI   : immediate = // TODO: assemble bits exactly as specified above

    	// JAL:
    	// immediate[20]	= instruction_i[31]   (sign bit)
    	// immediate[19:12] = instruction_i[19:12]
    	// immediate[11]	= instruction_i[20]
    	// immediate[10:1]  = instruction_i[30:21]
    	// immediate[0] 	= 1'b0
    	// immediate[31:21] = Sign-extend
    	JAL   : immediate = // TODO: assemble bits exactly as specified above

    	default: illegal_inst = 1'b1;
	endcase
end

////////////////////////////////////////////////////////////// ID → EX Register////////////////////////////////////////////////////////////

// TODO-4:
// Generate control signals based on opcode
// alu, lui, jal, jalr, branch, mem_write, mem_to_reg, arithsubtype

id_ex_reg u_id_ex (
	.clk        	(clk),
	.reset_n    	(reset),
	.stall_n    	(stall_read_i),

	// From ID
	.immediate_i	(immediate),
	.immediate_sel_i(
    	(instruction_i[`OPCODE] == JALR)  ||(instruction_i[`OPCODE] == LOAD)  ||
    	(instruction_i[`OPCODE] == ARITHI)
	),
	.alu_i      	(/* TODO: If instruction opcode is ARITHI or ARITHR*/),
	.lui_i      	(instruction_i[`OPCODE] == LUI),
	.jal_i      	(/* TODO: If instruction opcode is JAL*/),
	.jalr_i     	(instruction_i[`OPCODE] == JALR),
	.branch_i   	(/* TODO: If instruction opcode is BRANCH*/),
	.mem_write_i	(instruction_i[`OPCODE] == STORE),
	.mem_to_reg_i   (instruction_i[`OPCODE] == LOAD),
	.arithsubtype_i (
    	instruction_i[`SUBTYPE] &&
    	!(instruction_i[`OPCODE] == ARITHI &&
      	instruction_i[`FUNC3] == ADD)
	),
	.pc_i       	(inst_fetch_pc),
	.src1_sel_i 	(instruction_i[`RS1]),
	.src2_sel_i 	(instruction_i[`RS2]),
	.dest_reg_sel_i (instruction_i[`RD]),
	.alu_op_i   	(instruction_i[`FUNC3]),
	.illegal_inst_i (illegal_inst),

	// To EX (WIRES)
	.execute_immediate_o (execute_immediate_w),
	.immediate_sel_o 	(immediate_sel_w),
	.alu_o           	(alu_w),
	.lui_o           	(lui_w),
	.jal_o           	(jal_w),
	.jalr_o          	(jalr_w),
	.branch_o        	(branch_w),
	.mem_write_o     	(mem_write_w),
	.mem_to_reg_o    	(mem_to_reg_w),
	.arithsubtype_o  	(arithsubtype_w),
	.pc_o            	(pc_w),
	.src1_sel_o      	(src1_select_w),
	.src2_sel_o      	(src2_select_w),
	.dest_reg_sel_o  	(dest_reg_sel_w),
	.alu_op_o        	(alu_operation_w),
	.illegal_inst_o  	(illegal_inst_w)
);
endmodule


////////////////////////////////////////////////////////////// ID → EX register module////////////////////////////////////////////////////////////

module id_ex_reg (
    input         clk,
    input         reset_n,
    input         stall_n,

    // Inputs from ID
    input  [31:0] immediate_i,
    input         immediate_sel_i,
    input         alu_i,
    input         lui_i,
    input         jal_i,
    input         jalr_i,
    input         branch_i,
    input         mem_write_i,
    input         mem_to_reg_i,
    input         arithsubtype_i,
    input  [31:0] pc_i,
    input  [4:0]  src1_sel_i,
    input  [4:0]  src2_sel_i,
    input  [4:0]  dest_reg_sel_i,
    input  [2:0]  alu_op_i,
    input         illegal_inst_i,

    // Outputs to EX
    output reg [31:0] execute_immediate_o,
    output reg        immediate_sel_o,
    output reg        alu_o,
    output reg        lui_o,
    output reg        jal_o,
    output reg        jalr_o,
    output reg        branch_o,
    output reg        mem_write_o,
    output reg        mem_to_reg_o,
    output reg        arithsubtype_o,
    output reg [31:0] pc_o,
    output reg [4:0]  src1_sel_o,
    output reg [4:0]  src2_sel_o,
    output reg [4:0]  dest_reg_sel_o,
    output reg [2:0]  alu_op_o,
    output reg        illegal_inst_o
);

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        execute_immediate_o <= 32'h0;
        immediate_sel_o     <= 1'b0;
        alu_o               <= 1'b0;
        lui_o               <= 1'b0;
        jal_o               <= 1'b0;
        jalr_o              <= 1'b0;
        branch_o            <= 1'b0;
        mem_write_o         <= 1'b0;
        mem_to_reg_o        <= 1'b0;
        arithsubtype_o      <= 1'b0;
        pc_o                <= 32'h0;
        src1_sel_o          <= 5'h0;
        src2_sel_o          <= // TODO: Clear the signal on reset;
        dest_reg_sel_o      <= // TODO: Clear the signal on reset;
        alu_op_o            <= 3'h0;
        illegal_inst_o      <= 1'b0;
    end
    else if (!stall_n) begin
        execute_immediate_o <= immediate_i;
        immediate_sel_o     <= immediate_sel_i;
        alu_o               <= alu_i;
        lui_o               <= lui_i;
        jal_o               <= jal_i;
        jalr_o              <= jalr_i;
        branch_o            <= // TODO: Store the corresponding signal in a flip flop;
        mem_write_o         <= // TODO: Store the corresponding signal in a flip flop;
        mem_to_reg_o        <= mem_to_reg_i;
        arithsubtype_o      <= arithsubtype_i;
        pc_o                <= pc_i;
        src1_sel_o          <= src1_sel_i;
        src2_sel_o          <= src2_sel_i;
        dest_reg_sel_o      <= dest_reg_sel_i;
        alu_op_o            <= alu_op_i;
        illegal_inst_o      <= illegal_inst_i;
    end
end

endmodule
