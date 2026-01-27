`timescale 1ns/1ps
module tb_if_id ;
///////////////////////////////////////////////////////////// PARAMETERS////////////////////////////////////////////////////////////
parameter INPUT_LOG  = "inputs.txt";
parameter OUTPUT_LOG = "outputs.txt";

////////////////////////////////////////////////////////////// CLOCK & RESET////////////////////////////////////////////////////////////
reg clk;
reg reset;

////////////////////////////////////////////////////////////// DUT INPUTS////////////////////////////////////////////////////////////
reg stall;
reg inst_mem_is_valid;
reg [31:0] inst_mem_read_data;

reg stall_read_i;
reg [31:0] inst_fetch_pc;
reg [31:0] instruction_i;

reg wb_stall;
reg wb_alu_to_reg;
reg wb_mem_to_reg;
reg [4:0] wb_dest_reg_sel;
reg [31:0] wb_result;
reg [31:0] wb_read_data;

reg [1:0] inst_mem_offset;

////////////////////////////////////////////////////////////// DUT OUTPUTS////////////////////////////////////////////////////////////
wire exception;
wire [31:0] execute_immediate_w;
wire immediate_sel_w;
wire alu_w;
wire lui_w;
wire jal_w;
wire jalr_w;
wire branch_w;
wire mem_write_w;
wire mem_to_reg_w;
wire arithsubtype_w;
wire [31:0] pc_w;
wire [4:0] src1_select_w;
wire [4:0] src2_select_w;
wire [4:0] dest_reg_sel_w;
wire [2:0] alu_operation_w;
wire illegal_inst_w;
wire [31:0] instruction_o;

////////////////////////////////////////////////////////////
// FILE HANDLES
////////////////////////////////////////////////////////////
integer in_fd;
integer out_fd;
integer cycle;

reg [1023:0] line;
integer cycle_in;
reg [31:0] pc_in;
reg [31:0] instr_in;

// Dummy vars for unused columns
reg stall_i;
reg stall_r_i;
reg valid_i;
reg [1:0] offset_i;
reg wb_stall_i;
reg [4:0] wb_dest_i;
reg [31:0] wb_result_i;
reg [31:0] wb_rdata_i;

////////////////////////////////////////////////////////////// DUT INSTANCE////////////////////////////////////////////////////////////
IF_ID dut (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .exception(exception),

    .inst_mem_is_valid(inst_mem_is_valid),
    .inst_mem_read_data(inst_mem_read_data),

    .stall_read_i(stall_read_i),
    .inst_fetch_pc(inst_fetch_pc),
    .instruction_i(instruction_i),

    .wb_stall(wb_stall),
    .wb_alu_to_reg(wb_alu_to_reg),
    .wb_mem_to_reg(wb_mem_to_reg),
    .wb_dest_reg_sel(wb_dest_reg_sel),
    .wb_result(wb_result),
    .wb_read_data(wb_read_data),

    .inst_mem_offset(inst_mem_offset),

    .execute_immediate_w(execute_immediate_w),
    .immediate_sel_w(immediate_sel_w),
    .alu_w(alu_w),
    .lui_w(lui_w),
    .jal_w(jal_w),
    .jalr_w(jalr_w),
    .branch_w(branch_w),
    .mem_write_w(mem_write_w),
    .mem_to_reg_w(mem_to_reg_w),
    .arithsubtype_w(arithsubtype_w),
    .pc_w(pc_w),
    .src1_select_w(src1_select_w),
    .src2_select_w(src2_select_w),
    .dest_reg_sel_w(dest_reg_sel_w),
    .alu_operation_w(alu_operation_w),
    .illegal_inst_w(illegal_inst_w),
    .instruction_o(instruction_o)
);

////////////////////////////////////////////////////////////// CLOCK////////////////////////////////////////////////////////////
always #5 clk = ~clk;

////////////////////////////////////////////////////////////// TEST SEQUENCE////////////////////////////////////////////////////////////
initial begin
    clk = 0;
    reset = 0;
    cycle = 0;

    stall = 0;
    stall_read_i = 0;
    inst_mem_is_valid = 0;
    inst_mem_offset = 2'b00;

    wb_stall = 0;
    wb_alu_to_reg = 0;
    wb_mem_to_reg = 0;
    wb_dest_reg_sel = 0;
    wb_result = 0;
    wb_read_data = 0;

    inst_fetch_pc = 0;
    instruction_i = 0;
    inst_mem_read_data = 0;

    // Open files
    in_fd  = $fopen(INPUT_LOG, "r");
    out_fd = $fopen(OUTPUT_LOG, "w");

    if (in_fd == 0) begin
        $display("ERROR: Cannot open input.txt");
        $finish;
    end

    // Skip header
    $fgets(line, in_fd);

    // Output header
     $fwrite(out_fd,
        "pc_w execute_immediate_w immediate_sel_w alu_w lui_w jal_w jalr_w  branch_w mem_write_w mem_to_reg_w dest_reg_sel_w  alu_operation_w illegal_inst_w exception\n"
    );


    // Apply reset
    #20 reset = 1;

    ////////////////////////////////////////////////////////////// MAIN TRACE-DRIVENLOOP////////////////////////////////////////////////
    while (!$feof(in_fd)) begin
        $fgets(line, in_fd);
        @(posedge clk);
  
        // Parse input.txt correctly
        $sscanf(line,
             "%h\t %h\t %b\t %b\t %b\t %b\t %b\t %d\t %h\t %h\t\n",
            inst_fetch_pc,
            instruction_i,
            stall,
            stall_read_i,
            inst_mem_is_valid,
            inst_mem_offset,
            wb_stall,
            wb_dest_reg_sel,
            wb_result,
            wb_read_data
        );
#20;
      
        // Log outputs
 $fwrite(out_fd,
    "%h\t %h\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %d\t %b\t %b\t %b\t %b\t\n",
    pc_w,
    execute_immediate_w,
    immediate_sel_w,
    alu_w,
    lui_w,
    jal_w,
    jalr_w,
    branch_w,
    mem_write_w,
    mem_to_reg_w,
    dest_reg_sel_w,
    alu_operation_w,
    illegal_inst_w,
    exception
);
    end
    $fclose(in_fd);
    $fclose(out_fd);
    #20 $finish;
end
endmodule
