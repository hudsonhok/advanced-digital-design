module decoder (
    input [31:0] I,
    input [0:0] stall,

    // instruction format fields
    output [11:0] imm,
    output [6:0] funct7, opcode,
    output [4:0] rs2, rs1, rd,
    output [2:0] funct3,
    output [19:0] imm_long,
    output [12:0] boffset,
    output [20:0] joffset
);

logic [31:0] instr;

assign instr = stall ? 32'b0 : I;

// universal
assign opcode = instr[6:0];

assign funct7 = instr[31:25];
assign rs2 = instr[24:20];
assign rs1 = instr[19:15];
assign funct3 = instr[14:12];
assign rd = instr[11:7];

// I-type
assign imm = instr[31:20];

// U-type
assign imm_long = instr[31:12];

// B-type
assign boffset = {instr[31],instr[7],instr[30:25],instr[11:8],1'b0};

// J-type (jal only)
assign joffset = {instr[31],instr[19:12],instr[20],instr[30:21],1'b0};

endmodule
