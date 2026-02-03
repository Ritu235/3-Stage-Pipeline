
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
        $readmemb("input_ex_b.mem", stimulus_mem);
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
        if (addr == 19)
                addr <= 0;
            else
                addr <= addr + 1;
        end
end

wire [82:0] stim = stimulus_mem[addr];

// Unpack

wire [31:0] execute_imm;
wire [31:0] pc;
wire immediate_sel;
wire mem_write;
wire jal;
wire jalr;
wire lui;
wire alu;
wire branch;
wire mem_to_reg;

wire [4:0] dest_reg_sel;
wire [2:0] alu_op;
wire illegal_inst_w;
wire exception_w;


// Unpack
assign pc              = stim[81:50];
assign execute_imm     = stim[49:18];

assign immediate_sel   = stim[17];
assign alu             = stim[16];
assign lui             = stim[15];
assign jal             = stim[14];
assign jalr            = stim[13];
assign branch          = stim[12];
assign mem_write       = stim[11];
assign mem_to_reg      = stim[10];

assign dest_reg_sel    = stim[9:5];
assign alu_op          = stim[4:2];

assign illegal_inst_w  = stim[1];
assign exception_w    = stim[0];


////////////////////////////////////////////////////////////// DUT OUTPUTS////////////////////////////////////////////////////////////
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;
    wire [31:0] write_address;
    wire        branch_stall;

    wire [31:0] next_pc;
    wire        branch_taken;

    // -----------------------------
    // EX → WB
    // -----------------------------
    wire [31:0] wb_result;
    wire        wb_mem_write;
    wire        wb_alu_to_reg;
    wire [4:0]  wb_dest_reg_sel;
    wire        wb_branch;
    wire        wb_branch_nxt;
    wire        wb_mem_to_reg;
    wire [1:0]  wb_read_address;
    wire [2:0]  mem_alu_operation;

////////////////////////////////////////////////////////////// DUT INSTANCE////////////////////////////////////////////////////////////
execute dut (
    .clk               (clk),
    .reset             (reset),

    .reg_rdata1        (reg_rdata1),
    .reg_rdata2        (reg_rdata2),
    .execute_imm       (execute_imm),
    .pc                (pc),
    .fetch_pc          (fetch_pc),

    .immediate_sel     (immediate_sel),
    .mem_write         (mem_write),
    .jal               (jal),
    .jalr              (jalr),
    .lui               (lui),
    .alu               (alu),
    .branch            (branch),
    .arithsubtype      (arithsubtype),
    .mem_to_reg        (mem_to_reg),
    .stall_read        (stall_read),

    .dest_reg_sel      (dest_reg_sel),
    .alu_op            (alu_op),
    .dmem_raddr        (dmem_raddr),

    .wb_branch_i       (wb_branch_i),
    .wb_branch_nxt_i   (wb_branch_nxt_i),

    .alu_operand1     (alu_operand1),
    .alu_operand2     (alu_operand2),
    .write_address    (write_address),

    .next_pc           (next_pc),
    .branch_taken      (branch_taken),
    .branch_stall      (branch_stall),

    .wb_result         (wb_result),
    .wb_mem_write      (wb_mem_write),
    .wb_alu_to_reg     (wb_alu_to_reg),
    .wb_dest_reg_sel   (wb_dest_reg_sel),
    .wb_branch         (wb_branch),
    .wb_branch_nxt     (wb_branch_nxt),
    .wb_mem_to_reg     (wb_mem_to_reg),
    .wb_read_address   (wb_read_address),
    .mem_alu_operation (mem_alu_operation)
);


assign led =   wb_dest_reg_sel ;

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