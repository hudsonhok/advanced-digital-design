module control(
    // instruction format fields
    input logic [6:0] funct7, opcode,
    input logic[11:0] imm,
    input logic [2:0] funct3,

    // control unit fields
    output logic [3:0] aluop,
    output logic [0:0] alusrc, regwrite, gpiowe,
    output logic [1:0] regsel, pcsrc, btype
);

always @(*) begin
    aluop = 4'b0000;
    alusrc = 1'b0;
    regwrite = 1'b0;
    gpiowe = 1'b0;
    regsel = 2'b10;
    pcsrc = 2'b0;
    btype = 2'b11;
    
    case (opcode)
        7'b0110011 : begin                          // *** R-type ***
            // funct7  funct3
            // 0000000 000 add
            // 0100000 000 sub
            // 0000001 000 mul
            // 0000001 001 mulh
            // 0000000 001 sll
            // 0000000 010 slt
            // 0000001 011 mulhu
            // 0000000 011 sltu
            // 0000000 100 xor
            // 0000000 101 srl
            // 0100000 101 sra
            // 0000000 110 or
            // 0000000 111 and

            alusrc = 1'b0;
            regsel = 2'b10;
            regwrite = 1'b1;

            case(funct3)
                3'b000: begin
                    if (funct7 == 7'b0000000) begin         // add
                        aluop  = 4'b0011;
                    end
                    else if (funct7 == 7'b0100000) begin    // sub
                        aluop  = 4'b0100;
                    end
                    else if (funct7 == 7'b0000001) begin    // mul
                        aluop  = 4'b0101;
                    end
                end
                3'b001: begin
                    if (funct7 == 7'b0000001) begin         // mulh
                        aluop  = 4'b0110;
                    end
                    else if (funct7 == 7'b0000000) begin    // sll
                        aluop  = 4'b1000;
                    end
                end
                3'b010: begin                               // slt
                    aluop  = 4'b1100;
                end
                3'b011: begin
                    if (funct7 == 7'b0000001) begin         // mulhu
                        aluop  = 4'b0111;

                    end
                    else if (funct7 == 7'b0000000) begin    // sltu
                        aluop  = 4'b1101;
                    end
                end
                3'b100: begin                               // xor
                    aluop  = 4'b0010;
                end
                3'b101: begin
                    if (funct7 == 7'b0000000) begin         // srl
                        aluop  = 4'b1001;

                    end
                    else if (funct7 == 7'b0100000) begin    // sra
                        aluop  = 4'b1000;
                    end
                end
                3'b110: begin                               // or
                    aluop  = 4'b0001;
                end
                3'b111: begin                               // and
                    aluop  = 4'b0000;
                end
            endcase
        end
        7'b0010011 : begin                          // *** I-type ***
            // funct3
            // 000 addi
            // 001 slli     funct7 (31:25) = 0000000
            // 100 xori
            // 101 srai     funct7 (31:25) = 0100000
            // 101 srli     funct7 (31:25) = 0000000
            // 110 ori
            // 111 andi
            // cssrw ??
            alusrc = 1'b1;
            regsel = 2'b10;
            regwrite = 1'b1;
            case(funct3)
                3'b000: begin                               // addi
                    aluop  = 4'b0011;
                end
                3'b001: begin                               // slli
                    aluop  = 4'b1000;
                end
                3'b100: begin                               // xori
                    aluop  = 4'b0010;
                end
                3'b101: begin
                    if (funct7 == 7'b0100000) begin         // srai
                        aluop  = 4'b1010;
                    end
                    else if (funct7 == 7'b0000000) begin    // srli
                        aluop  = 4'b1001;
                    end
                end
                3'b110: begin                               // ori
                    aluop  = 4'b0001;
                end
                3'b111: begin                               // andi
                    aluop  = 4'b0000;
                end
            endcase
        end
        7'b1100011 : begin                          // *** B-type ***
            // btype:
            //      0 (rex == 0)
            //      1 (rex == 1)
            //      2 (rex != 0)
            // alusrc = 1'b0;
            regwrite = 1'b0;
            pcsrc = 2'b1;
            case(funct3)
                3'b000 : begin                                    // beq
                    aluop = 4'b0100;
                    btype = 2'b0;
                end
                3'b100 : begin                                   // blt
                    aluop = 4'b1100;
                    btype = 2'b1;
                end
                3'b101 : begin                                    // bge
                    aluop = 4'b1100;
                    btype = 2'b0;
                end
                3'b110 : begin                                   // bltu
                    aluop = 4'b1101;
                    btype = 2'b1;
                end
                3'b111 : begin                                   // bgeu
                    aluop = 4'b1101;
                    btype = 2'b0;
                end
            endcase
            
        end
        7'b1101111 : begin                          // *** jal ***
            regsel = 2'b11;
            regwrite = 1'b1;
            pcsrc = 2'b10;
        end
        7'b1100111 : begin                          // *** jalr ***
            regsel = 2'b11;
            regwrite = 1'b1;
            pcsrc = 2'b11;
            
        end
        7'b1110011 : begin                          // *** CSRRW ***
            if (imm == 12'hf02) begin                      // HEX, output
                regwrite = 1'b0;
                gpiowe = 1'b1;                
            end else if (imm == 12'hf00) begin             // SW, input
                regsel = 2'b00;
                regwrite = 1'b1;
            end
        end
        7'b0110111 : begin                          // *** U-type ***
            // lui is the only implemented U-type instruction
            regsel = 2'b01;
            regwrite = 1'b1;
        end
    endcase
end
endmodule
