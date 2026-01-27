
module top_module (
    input  wire        clock,        // 100 MHz
    input  wire        reset,      // Active-HIGH (BTNC)
    output wire  [15:0] led         // LED[15:0] ACTIVE-LOW
);

//reg clock=0;
//always #5 clock = ~clock;

//reg reset;
//initial begin reset = 0; #20 reset = 1; end

reg[7:0]  addr=0;

(* rom_style = "block" *)
reg [138:0] stimulus_mem [0:16];

initial begin
        $readmemb("inputb.mem", stimulus_mem);
end
    // Clock Divider
clock_divider #(
    .DIVISOR(100_000_000)
) clk_div_u (
    .clk   (clock),
    .reset (reset),
    .clk_en(clk)
);
always @(posedge clk) begin
    if (!reset)
        addr <= 0;
    else begin
        if (addr == 17)
                addr <= 0;
            else
                addr <= addr + 1;
        end
end

wire [138:0] stim = stimulus_mem[addr];

// Unpack

wire [31:0] inst_fetch_pc;
wire [31:0] instruction_i;

wire stall;
wire stall_read_i;
wire inst_mem_is_valid;
wire [1:0] inst_mem_offset;
wire wb_stall;

wire [4:0] wb_dest_reg_sel;
wire [31:0] wb_result;
wire [31:0] wb_read_data;


// Unpack
assign inst_fetch_pc      = stim[138:107];
assign instruction_i     = stim[106:75];
assign stall              = stim[74];
assign stall_read_i       = stim[73];
assign inst_mem_is_valid  = stim[72];
assign inst_mem_offset    = stim[71:70];
assign wb_stall           = stim[69];
assign wb_dest_reg_sel    = stim[68:64];
assign wb_result          = stim[63:32];
assign wb_read_data       = stim[31:0];

reg [31:0] inst_mem_read_data;
reg wb_alu_to_reg;
reg wb_mem_to_reg;

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

////////////////////////////////////////////////////////////// DUT INSTANCE////////////////////////////////////////////////////////////
IF_ID u_if_id (
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

assign led = execute_immediate_w;

endmodule

module clock_divider(
    input  wire clk,
    input  wire reset,
    output reg  clk_en
);
    parameter DIVISOR = 100_000_000;
    reg [26:0] counter;

    always @(posedge clk) begin
        if (!reset) begin
            counter <= 0;
            clk_en <= 1'b0;
        end
        else if (counter == DIVISOR-1) begin
            counter <= 0;
            clk_en <= ~clk_en;
        end
        else begin
            counter <= counter + 1;
        end
    end
    
endmodule


/*module clock_divider(
    input  wire clk,
    input  wire reset,
    output reg  clk_en
);

    always @(*) begin
            clk_en = clk;
    end
 
endmodule
*/