module cpu (
    input logic [0:0] clk, rst_n,
    input logic [17:0] io0_in,
    output logic [31:0] io2_out
);

// RAM
logic [31:0] instruction_mem [4095:0];
logic [31:0] instruction;
logic [11:0] PC_FETCH;

// pipeline logic
logic [11:0] PC_EX;
logic [4:0] writeaddr_WB;
logic [0:0] regwrite_WB, stall_WB;
logic [1:0] regsel_WB;

// decoder input/output fields
logic [11:0] imm_EX;
logic [12:0] boffset_EX;
logic [6:0] funct7, opcode;
logic [4:0] readaddr2_EX, readaddr1_EX, writeaddr_EX;
logic [2:0] funct3;
logic [19:0] imm_long_EX, imm_long_WB;
logic [20:0] joffset_EX;

// control codes
logic [3:0] aluop_EX;
logic [0:0] alusrc_EX, gpiowe_EX, stall_EX;
logic [1:0] regsel_EX, pcsrc_EX, btype_EX; 

// regfile input/output fields
logic [31:0] readdata1_EX, readdata2_EX, writedata_EX, writedata_WB;

// are we branching?
logic [0:0] branch_EX;
assign branch_EX =  (btype_EX==2'b0  && writedata_EX==32'b0) ? 1'b1 :
                    (btype_EX==2'b1  && writedata_EX==32'b1) ? 1'b1 :
                    (btype_EX==2'b10 && writedata_EX!=32'b0) ? 1'b1 :
                    1'b0;

// branch/jump calculations
logic [11:0] branch_addr_EX, jal_addr_EX, jalr_addr_EX;
assign branch_addr_EX = PC_EX + {boffset_EX[12],boffset_EX[12:2]};
assign jal_addr_EX = PC_EX + joffset_EX[13:2];
assign jalr_addr_EX = readdata1_EX + {{2{imm_EX[11]}},imm_EX[11:2]};

// read RAM from file
initial $readmemh("program.rom", instruction_mem);
// out of bounds protection?
always_ff @(posedge clk) begin
    if (~rst_n) begin
        instruction <= 32'b0;
        PC_FETCH <= 12'b0;
    end else begin
        instruction <= instruction_mem[PC_FETCH];
        PC_FETCH <= 
            (pcsrc_EX==2'b11) ? jalr_addr_EX :
            (pcsrc_EX==2'b10) ? jal_addr_EX :
            (pcsrc_EX==2'b01 && branch_EX==1'b1) ? branch_addr_EX :
            PC_FETCH + 12'b1;
        // drive stall
        stall_EX <= (pcsrc_EX>2'b1 || (pcsrc_EX==2'b1 && branch_EX==1'b1)) ? 1'b1 : 1'b0; 
    end
end


// some kind of output from control
/*  if JAL, i = 1
    if JALR, i = 2
    if B, i = 3
THEN COMBINE WITH ZERO (if branch)
    if i = 3 and zero = 0
        i = 0
    */

// DECODER INSTANCE
decoder dcdr(
    .I(instruction),
    .stall(stall_EX),
    .imm(imm_EX),
    .joffset(joffset_EX),
    .funct7(funct7),
    .opcode(opcode),
    .rs2(readaddr2_EX),
    .rs1(readaddr1_EX),
    .rd(writeaddr_EX),
    .funct3(funct3),
    .imm_long(imm_long_EX),
    .boffset(boffset_EX)
);

// CONTROL INSTANCE
control ctrl(
                .imm(imm_EX),
                .funct7(funct7),
                .opcode(opcode),
                .funct3(funct3),
                .aluop(aluop_EX),
                .alusrc(alusrc_EX),
                .regwrite(regwrite_EX),
                .gpiowe(gpiowe_EX),
                .regsel(regsel_EX),
                .pcsrc(pcsrc_EX),
                .btype(btype_EX)
);

// REGFILE INSTANCE
regfile my_regfile( .clk(clk),
                    .rst(rst_n),
                    .we(regwrite_WB),
                    .readaddr1(readaddr1_EX),
                    .readaddr2(readaddr2_EX),
                    .writeaddr(writeaddr_WB),
                    .writedata(
                        regsel_WB==2'b11 ? PC_EX :
                        regsel_WB==2'b10 ? writedata_WB : 
                        regsel_WB==2'b01 ? {imm_long_WB,12'b0}
                      /*regsel_WB==2'b00*/ : {14'b0,io0_in}
                    ),
                    .readdata1(readdata1_EX),
                    .readdata2(readdata2_EX)
);

// ALU INSTANCE
alu my_ALU(
            .A(readdata1_EX), 
            .B(alusrc_EX ? {{20{imm_EX[11]}},imm_EX} : readdata2_EX),
            .op(aluop_EX),
            .R(writedata_EX)
);

// PIPELINE LOGIC
always @(posedge clk) begin
    // input data
    imm_long_WB <= imm_long_EX;
    // control codes
    regsel_WB <= regsel_EX;
    regwrite_WB <= regwrite_EX;
    PC_EX <= PC_FETCH;
    stall_WB <= stall_EX;
    // other fields
    writedata_WB <= writedata_EX;
    writeaddr_WB <= writeaddr_EX;
    // data found during operation
    if (gpiowe_EX) io2_out <= readdata1_EX;
end
endmodule
