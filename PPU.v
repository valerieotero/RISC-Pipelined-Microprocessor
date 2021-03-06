// `include "register_file/PF1_Nazario_Morales_Victor_rf.v"
// `include "ALU-SSExtender/PF1_Ortiz_Colon_Ashley_Sign_Shift_Extender.v"
// `include "ALU-SSExtender/PF1_Ortiz_Colon_Ashley_ALU.v"


//CONTROL UNIT
module control_unit(output  ID_B_instr,BL, S, output  [8:0] C_U_out, input clk, Reset, asserted, input [31:0] A, output R14_CU_OUT, output [3:0] Rm, output [31:0] SSEI); 

    reg [2:0] instr;
     //**C_U_out = ID_shift_imm[6], ID_ALU_op[5:2], ID_load_instr [1], ID_RF_enable[0]

    reg change = 0;
    reg s_imm = 0; 
    reg rf_instr = 0; 
    reg l_instr = 0; 
    reg b_instr = 0; 
    reg m_rw = 0;
    reg m_size = 0;
    reg incon = 0;
    reg [31:0] ssi;

    reg [3:0] alu_op, rm_new ;
    reg b_bl =0; // branch or branch & link
    reg r_sr_off; // register or Scaled register offset
    reg u;
    reg rcu = 0;

    assign C_U_out[6] = s_imm;
    assign C_U_out[0] = rf_instr;
    assign C_U_out[1] = l_instr; 
    assign ID_B_instr = b_instr;
    assign C_U_out[5:2] = alu_op;
    assign C_U_out[7]  = m_rw;
    assign C_U_out[8]  = m_size;
    assign BL = b_bl;
    assign S = change;
    assign R14_CU_OUT = rcu;
    assign Rm = rm_new;
    assign SSEI = ssi;

    always@(*)
   

    begin
        // // $display("instruction %b", A);
        if(Reset == 1'b1 || A  == 32'b0 || asserted ==0) begin 
            s_imm = 0; 
            rf_instr = 0; 
            l_instr = 0; 
            b_instr = 0; 
            m_rw = 0;
            m_size = 0;
            alu_op = 4'b0000;
            change = 0;
            b_bl=0;
        end else begin 
            if(A[15:12] == 4'b1111) begin
                instr = 3'b101;
                incon = 1;
            end  else
               instr = A[27:25];
              
            case(instr)

                3'b000: //Data Procesing Shift_by_imm
                begin
                    change = A[20];
                    if(A[4] == 0)  begin
                        s_imm = 1; 
                        rf_instr = 1; 
                        l_instr = 0; 
                        b_instr = 0;
                        alu_op = A[24:21];
                        b_bl =0;
                        m_rw = 0;

                    end
                    
                    if(A[11:7] == 5'b0) begin
                        s_imm = 0; 
                        rf_instr = 1; 
                        l_instr = 0; 
                        b_instr = 0;
                        alu_op = A[24:21];
                        b_bl=0;
                        m_rw = 0;

                    end


                    
                end

                3'b001: //Data Procesing Immediate
                begin
                    change = A[20];
                    s_imm = 1; 
                    rf_instr = 1; 
                    l_instr = 0; 
                    b_instr = 0;
                    alu_op = A[24:21];
                    b_bl= 0;
                    m_rw = 0;

                end

                3'b010: //Load/Store Immediate Offset
                begin
                    change = 0;
                    s_imm = 1; 
                    l_instr = A[20]; 
                    b_instr = 0;
                    m_size = A[22];
                    b_bl= 0;

                    if(l_instr == 0) begin
                        rf_instr = 0;
                        m_rw = 1;
                        
                    end else begin
                        rf_instr = 1; 
                        m_rw = 0;
                        
                    end 

                    if(A[23] == 1)
                        alu_op = 4'b0100; //suma
                    else
                        alu_op = 4'b0010; //resta              
                end

                3'b011: //Load/Store Register Offset
                begin
                    change = 0;
                    if(A[4] == 1'b0  )begin
                        l_instr = A[20];
                        m_size = A[22];
                        s_imm = 0; 
                        b_instr = 0;
                        b_bl = 0;

                        if(A[23]== 1)
                            alu_op = 4'b0100; //suma
                        else
                            alu_op = 4'b0010; //resta
                            

                        if(l_instr == 0) begin
                            rf_instr = 0;
                            m_rw = 1;
                        end else begin
                            rf_instr = 1; 
                            m_rw = 0;

                        end
                    
                        if(A[11:4] == 8'b00000000)begin
                            r_sr_off = 0;
                            // s_imm = 0; 

                        end else begin
                            r_sr_off = 1;
                            // s_imm = 1; 
                        end   

                    end
                    
                end

                3'b101: //branches
                begin
                    b_instr = 1;
                    change = 0;

                    b_bl = A[24];
                        
                       //branch
                        if(b_bl == 0) begin
                            s_imm = 0; 
                            rf_instr = 0; 
                            l_instr = 0; 
                            alu_op = 4'b0010;
                            m_rw = 0;
                            m_size = 0;

                        end else begin
                        //branch & link begin
                            s_imm = 0; 
                            rf_instr = 1; 
                            l_instr = 0; 
                            alu_op = 4'b0100; //suma
                            m_rw = 0;
                            m_size = 0;
                            ssi = 32'b11100001101000001110000000001111; // 
                            rm_new = 4'b1110; // r14


                        end

                        if(incon == 1) begin// when instrc rd is 15 
                            rcu = 1'b1; //decide escoger Rm for when RD = 15
//                            rm_new = 4'b1110; // r14
                            //ssi = 32'b11100001101000001110000000001111;




                        end else begin
                            rcu = 1'b0; 
                          //  rm_new = 4'b1110; // r14
                            alu_op = 4'b1101;

                        end
                        
                    // end
                end
                

            endcase
            // $display("size", m_size);
                        // $display("alu %b",alu_op);
            // $display("instr %b", instr);
        end//  $display("ID_shift_imm = %b | ID_alu= %b | ID_load = %b | ID_RF= %b", C_U_out[6], C_U_out[5:2], C_U_out[1], C_U_out[0]);     
    //    $monitor("A: %b | s_imm: %b", A, C_U_out[6]);
                            // $monitor("alu %b | A: %b",alu_op, A);

    end

      /* else begin
            if(DataOut[27:24] == 4'b1011 && asserted == 1 )begin // For Branch and Link
            //     // DataOut = 32'b11100001101000001110000000001111; 
                ID_Bit31_0 <= DataOut;//{DataOut[31:28], 28'b0001101000001110000000001111};
                ID_Next_PC <= PC4;
                ID_Bit3_0 <=  4'b1111; 
                ID_Bit31_28 <= DataOut[31:28];
                ID_Bit19_16 <=  4'b0000; 
                ID_Bit15_12 <= 4'b1110;
                ID_Bit23_0 <=  DataOut[23:0]; //
                TA_PP <=  1'b0;
                // $display("DOUT 31 28: %b", DataOut[31:28]);
            end else if (DataOut[15:12] == 4'b1111) begin
              TA_PP <=1'b1;


            end */

endmodule


//Status Register
module Status_register(input [3:0] cc_in, input S, output reg [3:0] cc_out, input clk, Reset); //verify
    //Recordar que el registro se declara aquí y luego
    always @ (posedge clk)
    begin

        if(Reset)
            cc_out <= 4'b0000;
        // else begin
        if (S)
            cc_out <= cc_in;
        // end
        // $display("cc_out: %b | cc_in: %b", cc_out, cc_in);
    end


endmodule


//Condition verification
module Cond_Is_Asserted (input [3:0] cc_in, input [3:0] instr_condition, output asserted);
    //N - 3, Z - 2, C - 1, V - 0
    integer n = 0;
    integer z = 0;
    integer c = 0;
    integer v = 0;
    reg assrt = 0;

    assign asserted = assrt;


    always@(*) //posedge clk)
    begin
        n = cc_in[3];
        z = cc_in[2];
        c = cc_in[1];
        v = cc_in[0];
        // $display ("n: %b | z: %b | c: %b | v: %b " , cc_in[3], cc_in[2], cc_in[1], cc_in[0]);
        case(instr_condition)
            4'b0000: //(EQ) Equal
            begin
                if(z == 1)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //1
            4'b0001: //(NE) Not Equal
            begin
                if(z == 0)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //2
            4'b0010: //(CS/HS) Carry set/unsigned higher or same
           begin
                if(c == 1)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //3
            4'b0011: //(CC/LO) carry clear/ unsigned lower
           begin
                if(c == 0)
                    assrt = 1;
                else
                    assrt = 0;
            end
                     
            //4
            4'b0100: //(MI) Minus/negative
            begin
                if(n == 1)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //5
            4'b0101: //(PL) plus/positive or zero 
            begin
                if(n == 0)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //6
            4'b0110: //(VS) Overflow
            begin
                if(v == 1)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //7
            4'b0111: //(VC) No Overflow
            begin
                if(v == 0)
                    assrt = 1;
                else
                    assrt = 0;
            end
            
            //8
            4'b1000: //(HI) Unsigned Higher 
            begin
                if(c == 1 && z ==0)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //9
            4'b1001: //(LS) Unsigned Lower or same
            begin
                if(c == 0 || z == 1)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //10
            4'b1010: //(GE) Signed greater than or equal 
            begin
                if(v == n)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //11
            4'b1011: //(LT) Signed less than
            begin
                if(v != n)
                    assrt = 1;
                else
                    assrt = 0;
            end

            //12
            4'b1100: //(GT) Signed greater than
            begin
                if(z == 0 || n == v)
                    assrt = 1;
                else
                    assrt = 0;
            end 

            //13
            4'b1101: // (LE) Signed Less than or equal
             begin
                if(z == 1 || n != v)
                    assrt = 1;
                else
                    assrt = 0;
            end 

            //14
            4'b1110: //Always
            assrt = 1;

            //15
            4'b1111: 
            assrt = 0;

        endcase

        
        // $display("condition arsserted: %b | cond Instr: %b", assrt, instr_condition);
    end

endmodule

//conition handler (output condition asserted, branch)
module Condition_Handler(input asserted, b_instr,TA_PP, output reg choose_ta_r_nop);
    always@(*)
    begin
        if(TA_PP)
            choose_ta_r_nop = 1;
        else begin
            if(asserted == 1 && b_instr == 1 ) //|| ex_asserted ==1 && ex_b_instr == 1)
                choose_ta_r_nop = 1;
            else
                choose_ta_r_nop = 0; 
        end
    end

endmodule


//IF/ID PIPELINE REGISTER
module IF_ID_pipeline_register(output reg[23:0] ID_Bit23_0, output reg [31:0] ID_Next_PC,
                               output reg [3:0] ID_Bit19_16, ID_Bit3_0, output reg [3:0] ID_Bit31_28, 
                               output reg[3:0] ID_Bit15_12, output reg [31:0] ID_Bit31_0,
                               input choose_ta_r_nop, Hazard_Unit_Ld, clk, Reset,asserted, input [31:0] PC4, DataOut, output reg TA_PP);

    always@(posedge clk, posedge Reset)
    begin

        if(Reset==1) begin
            ID_Bit31_0 <= 32'b0;
            ID_Next_PC <= 32'b0;
            ID_Bit3_0 <= 4'b0;
            ID_Bit31_28 <= 4'b0;
            ID_Bit19_16 <= 4'b0;
            ID_Bit15_12 <= 4'b0;
            ID_Bit23_0 <= 24'b0;
            TA_PP<=1'b0;

        end 

       /* else begin
            if(DataOut[27:24] == 4'b1011 && asserted == 1 )begin // For Branch and Link
            //     // DataOut = 32'b11100001101000001110000000001111; 
                ID_Bit31_0 <= DataOut;//{DataOut[31:28], 28'b0001101000001110000000001111};
                ID_Next_PC <= PC4;
                ID_Bit3_0 <=  4'b1111; 
                ID_Bit31_28 <= DataOut[31:28];
                ID_Bit19_16 <=  4'b0000; 
                ID_Bit15_12 <= 4'b1110;
                ID_Bit23_0 <=  DataOut[23:0]; //
                TA_PP <=  1'b0;
                // $display("DOUT 31 28: %b", DataOut[31:28]);
            end else if (DataOut[15:12] == 4'b1111) begin
              TA_PP <=1'b1;


            end */
            else begin

                if(Hazard_Unit_Ld == 1 || asserted == 1 || choose_ta_r_nop == 0) begin
                        ID_Bit31_0 <= DataOut;
                        ID_Next_PC <= PC4;
                        ID_Bit3_0 <=  DataOut[3:0]; 
                        ID_Bit31_28 <= DataOut[31:28];
                        ID_Bit19_16 <=  DataOut[19:16]; 
                        ID_Bit15_12 <= DataOut[15:12];
                        ID_Bit23_0 <= DataOut[23:0];

                        
                end else begin // if(Hazard_Unit_Ld == 0 || asserted == 0|| choose_ta_r_nop == 1)begin
                        ID_Bit31_0 <= 32'b0;
                        ID_Next_PC <= 32'b0;
                        ID_Bit3_0 <= 4'b0; 
                        ID_Bit31_28 <= 4'b0;
                        ID_Bit19_16 <= 4'b0; 
                        ID_Bit15_12 <= 4'b0;
                        ID_Bit23_0 <= 24'b0;
                        TA_PP <=  1'b0;
                end
            end

    end
    //    $monitor("PC4: %d | instr:%b | asserted:%b ", PC4, ID_Bit31_0, asserted);
        // $monitor(" EX_alu_op: %b, ID_alu_op: %b,  ID_instr: %b, ex  instr: %b",  ID_CU[5:2], EX_ALU_OP, ID_Bit11_0, EX_Bit11_0);

   // end
endmodule


//ID/EX PIPELINE REGISTER
module ID_EX_pipeline_register(output reg [31:0] mux_out_1_A, mux_out_2_B, mux_out_3_C,
                               output reg [3:0] EX_Bit15_12, EX_Bit31_28, output reg EX_Shift_imm, output reg [3:0]  EX_ALU_OP, output reg EX_load_instr, EX_RF_instr, 
                               output reg [31:0] EX_Bit11_0,
                               output reg [7:0] EX_addresing_modes,
                               output reg EX_mem_size, EX_mem_read_write,EXBL, ex_S_M, ex_asserted, ex_b_instr,
                               
                               input [31:0] mux_out_1, mux_out_2, mux_out_3,
                               input [3:0] ID_Bit15_12, ID_Bit31_28, input [8:0] ID_CU, input  id_bl,
                               input [31:0] ID_Bit11_0,
                               input [7:0] ID_addresing_modes,
                               input  clk, Reset, s_M, asserted, b_instr,
                               input  [31:0] ID_Next_PC,
                               output reg [31:0] EX_Next_PC); 

    always@(posedge clk, posedge Reset)
    begin
        
        if(Reset==1) begin
            EX_Shift_imm <= 1'b0;
            EX_ALU_OP <= 4'b0;
            EX_load_instr <= 1'b0; 
            EX_RF_instr <= 1'b0;
            EX_mem_size <= 1'b0;
            EX_mem_read_write <= 1'b0;
            EX_Next_PC <= 1'b0;

            //Register File operands
            mux_out_1_A <= 32'b0;
            mux_out_2_B <= 32'b0;
            mux_out_3_C <= 32'b0;
        
            //Instruction bits
            EX_Bit15_12 <= 4'b0;
            EX_Bit11_0 <= 32'b0; // {20'b0, ID_Bit11_0};
            EX_addresing_modes <= 8'b0; //22-20

            EXBL <= 1'b0;
            ex_S_M  <= 1'b0;
            ex_asserted <= 1'b0;
            EX_Bit31_28 <= 4'b0;
            ex_b_instr <= 1'b0;

        end else begin
        //Control Unit signals  
            EX_Shift_imm <= ID_CU[6];
            EX_ALU_OP <= ID_CU[5:2];
            EX_load_instr <= ID_CU[1]; 
            EX_RF_instr <= ID_CU[0];
            EX_mem_size <= ID_CU[8];
            EX_mem_read_write <= ID_CU[7];
            EX_Next_PC <= ID_Next_PC;

            //Register File operands
            mux_out_1_A <= mux_out_1;
            mux_out_2_B <= mux_out_2;
            mux_out_3_C <= mux_out_3;
        
            //Instruction bits
            EX_Bit15_12 <= ID_Bit15_12;
            EX_Bit11_0 <= ID_Bit11_0; // {20'b0, ID_Bit11_0};
            EX_addresing_modes <= ID_addresing_modes; //22-20

            EXBL <= id_bl; 
            ex_S_M <= s_M;
            ex_asserted <= asserted;
            EX_Bit31_28 <= ID_Bit31_28;
            ex_b_instr <= b_instr;
        end
    //  $display("ID_EX reg");
    //  $display("ID_shift_imm = %b | ID_alu= %b | ID_load = %b | ID_RF= %b", ID_CU[6], ID_CU[5:2], ID_CU[1], ID_CU[0]);     
    //  $display("EX_shift_imm = %b | EX_alu= %b | EX_load = %b | EX_RF= %b", EX_Shift_imm, EX_ALU_OP, EX_load_instr, EX_RF_instr);     
        // $monitor("ID_alu_op: %b,  EX_alu_op: %b, ID_instr: %b, ex  instr: %b",  ID_CU[5:2], EX_ALU_OP, ID_Bit11_0, EX_Bit11_0);
    end
   
endmodule


//EX/MEM PIPELINE REGISTER
module EX_MEM_pipeline_register(input  [31:0] mux_out_3_C, A_O, input [3:0] EX_Bit15_12, cc_main_alu_out, input EX_load_instr, EX_RF_instr, EX_mem_read_write, EX_mem_size, input clk, EXBL,
                                output reg  [31:0] MEM_A_O, MEM_MUX3, output reg [3:0] MEM_Bit15_12, output reg MEM_load_instr, MEM_RF_Enable, MEM_mem_read_write, MEM_mem_size, input Reset, output reg MEMBL);


    always@(posedge clk, posedge Reset)
    begin

        if(Reset==1) begin
            MEM_A_O <= 32'b0;
            MEM_MUX3 <= 32'b0;
            MEM_Bit15_12 <= 4'b0;
            MEM_load_instr <= 1'b0;
            MEM_RF_Enable <= 1'b0;
            MEM_mem_read_write <= 1'b0;
            MEM_mem_size <=  1'b0;
            MEMBL <= 1'b0;
        end else begin
             MEM_A_O <= A_O;
            MEM_MUX3 <= mux_out_3_C;
            MEM_Bit15_12 <= EX_Bit15_12;
            MEM_load_instr <= EX_load_instr;
            MEM_RF_Enable <= EX_RF_instr;
            MEM_mem_read_write <= EX_mem_read_write;
            MEM_mem_size <=  EX_mem_size;
            MEMBL <= EXBL;
        end
    
    //  $display("EX_MEM reg");
    //  $display("EX_load = %b | EX_RF= %b", EX_load_instr, EX_RF_instr);     
    //  $display("MEM_load = %b | MEM_RF= %b", MEM_load_instr, MEM_RF_Enable);     

    end
   
endmodule


//MEM/WB PIPELINE REGISTER
module MEM_WB_pipeline_register(input  [31:0] alu_out, data_r_out, input [3:0] bit15_12, input MEM_load_instr, MEM_RF_Enable, clk, MEMBL,
                                    output reg  [31:0] wb_alu_out, wb_data_r_out, output reg [3:0] wb_bit15_12, output reg WB_load_instr, WB_RF_Enable, input Reset, output reg WBBL);

    always@(posedge clk, posedge Reset)
    begin
        if(Reset==1) begin
            wb_alu_out <= 32'b0;
            wb_data_r_out <= 32'b0;
            wb_bit15_12 <= 4'b0;
            WB_load_instr <= 1'b0;
            WB_RF_Enable <= 1'b0;
            WBBL <= 1'b0;
        end else begin
            wb_alu_out <= alu_out;
            wb_data_r_out <= data_r_out;
            wb_bit15_12 <= bit15_12;
            WB_load_instr <= MEM_load_instr;
            WB_RF_Enable <= MEM_RF_Enable;
            WBBL <= MEMBL;
        end
    // $display("MEM_WB reg");
     
    // $display("MEM_load = %b | MEM_RF= %b", MEM_load_instr, MEM_RF_Enable);  
    // $display("WB_load = %b | WB_RF= %b", WB_load_instr, WB_RF_Enable);           
    end
    
endmodule


//INSTRUCTION MEMORY 
module inst_ram256x8(output reg[31:0] DataOut, input [31:0]Address); //, input Reset);
                  
   reg[7:0] Mem[0:255]; //256 localizaciones 
   
    always @ (DataOut,Address) //,Reset)  
    begin

        // if (Reset) //&& Address == 32'b0)
        // begin        
        //     DataOut = 32'b00000000000000000000000000000000; 
        //     // $display("Inside Reset\n");   
        // end
             
        // else//Not Reset
        begin
        // $display("From inside Instr Mem, Address= %d\n", Address);

            if(Address%4==0) //Instructions have to start at even locations that are multiples of 4.                        
                 DataOut = {Mem[Address+0], Mem[Address+1], Mem[Address+2], Mem[Address+3]};                
                
            else                    
                DataOut= Mem[Address]; 
                     
        end 
        
        // $display("From inside Instr Mem, DataOut= %b\n", DataOut);    
         
    end 
endmodule                                
              

//DATA MEMORY
module data_ram256x8(output reg[31:0] DataOut, input ReadWrite, input[31:0] Address, input[31:0] DataIn, input Size);// Reset);

    reg[7:0] Mem[0:255]; //256 localizaciones 

    always @ (DataOut, ReadWrite, Address, DataIn, Size)// posedge Reset)       

        // if (Reset) 
        //     begin        
        //         DataOut = 32'b00000000000000000000000000000000;                   
        //     end

        // else
    begin              
        casez(Size) //"casez" to ignore dont care values
            1'b1: //BYTE
            begin 
                if (ReadWrite) //When Write 
                    begin
                        Mem[Address] = DataIn; 
                    end
                else //When Read
                    begin
                        DataOut= Mem[Address];
                    end                
            end      

            1'b0: //WORD
            begin
                if (ReadWrite) //When Write 
                    begin
                        Mem[Address] = DataIn[31:24];
                        Mem[Address + 1] = DataIn[23:16];
                        Mem[Address + 2] = DataIn[15:8]; 
                        Mem[Address + 3] = DataIn[7:0]; 
                    end                 
                else //When Read
                    begin
                            DataOut = {Mem[Address + 0], Mem[Address + 1], Mem[Address + 2], Mem[Address + 3]}; 
                    end  
            end        
        endcase
    end      
endmodule


/*Multiplexer for the 3 MUX in ID (este es uno general se puede simplemente 
cambiar las asignaturas segun lo que se necesite)
*/
module mux_4x2_ID(input [31:0] A_O, PW, M_O, X, input [1:0] HF_U, output [31:0] MUX_Out);
    reg [31:0] salida;

    assign MUX_Out = salida;

    always@(*)
    begin
        case(HF_U)
            2'b00: // A
            salida = X;

            2'b01://B
            salida = A_O; //EX_Rd

            2'b10://C
            salida = M_O; //MEM_Rd

            2'b11://D
            salida = PW; //WB_Rd
        endcase
    end

endmodule

//Multiplexer control Unit
module mux_2x1_ID(input [8:0] C_U, input BL,S,input  R14m, input [31:0] ssei, input [3:0] Rm, input HF_U, output [8:0] MUX_Out, output id_bl, S_M, output replacement, output [31:0] id_ssei, output [3:0] newrm);
    reg [8:0] salida;
    reg change;
    reg nbl;
    reg [3:0] newrd, nrm;
    reg [31:0]  ss;

    assign MUX_Out = salida;
    assign S_M = change;
    assign id_bl = nbl;
    assign replacement = newrd;
    assign id_ssei = ss;
    assign newrm = nrm;

    always@(*)
    begin
        case(HF_U)
            1'b0: // NOP
            begin
                salida = 10'b0;
                change = 1'b0;
                nbl =  1'b0;
                newrd  =  4'b0;
                ss=32'b0;
                nrm = 4'b0;
            end

            1'b1://Control Unit
            begin
                salida = C_U;
                change = S;
                nbl =  BL;
                newrd  =  R14m;
                ss= ssei;
                nrm= Rm;
            end
        endcase
        // $display("CU MEX OUT %b ", salida );//
    end

endmodule


/*Multiplexar for stages (este es uno general se puede simplemente 
cambiar las asignaturas segun lo que se necesite)
*/
module mux_2x1_Stages(input [31:0] A, B, input sig, output [31:0] MUX_Out);
    reg [31:0] salida;

    assign MUX_Out = salida;

    always@(*)
    begin
        
        case(sig)
            1'b0: 
            salida = A;

            1'b1:
            salida = B;
        endcase

    end

endmodule

module mux_2x1_Reg(input [3:0] A, B, input sig, output [3:0] MUX_Out);
    reg [3:0] salida;

    assign MUX_Out = salida;

    always@(*)
    begin
        
        case(sig)
            1'b0: 
            salida = A;

            1'b1:
            salida = B;
        endcase

    end

endmodule

module SExtender(input [23:0] in, output reg signed [31:0] out1);

    reg signed [31:0] twoscomp;
    reg  [31:0] result;
    reg  [31:0] shift_result; 
    reg signed [31:0] temp_reg;
    reg [7:0] fill;
    reg relleno;

    reg [31:0] in1;
    // assign out1 = result; 

    integer i=0;

    always@(*)
    begin
// 
        if(in[23] == 1) begin
            in1 = {8'b11111111, in[23:0]};
            twoscomp = ~(in1) + 1'b1;
          
            temp_reg = in1 <<< 2;
            // end
            out1 = temp_reg ;
        end else begin
            in1 = {8'b0, in[23:0]}; 
            out1 = in1 <<< 2;
        end
        // $display("for bbranch: %b", out1);
        // result = shift_result * 4;
       


    end
endmodule




//HAZARD UNIT
module hazard_unit(output reg [1:0] MUX1_signal, MUX2_signal, MUX3_signal, output reg MUXControlUnit_signal, 
                   output reg IF_ID_load, PC_RF_load,
                   input EX_load_instr, EX_RF_Enable, MEM_RF_Enable, WB_RF_Enable, ID_shift_imm, clk,
                   input [3:0] EX_Bit15_12, MEM_Bit15_12, WB_Bit15_12, ID_Bit3_0, 
                   ID_Bit19_16);
    always@(*)//posedge  clk)//*)
    begin
        
        IF_ID_load = 1'b1; //Disable pipeline Load
        PC_RF_load = 1'b1; //Disable PC load
        MUXControlUnit_signal = 1'b1; //NOP; its suppose to 
        MUX1_signal = 2'b00;
        MUX2_signal = 2'b00;
        MUX3_signal = 2'b01;

        // DATA Hazard-By Load Instr

        if(EX_load_instr)begin
            if (ID_Bit3_0 == EX_Bit15_12  && ID_shift_imm==0) begin// && ID_shift_imm==0)begin
         
            IF_ID_load = 1'b0; //Disable pipeline Load
            PC_RF_load = 1'b0; //Disable PC load
            MUXControlUnit_signal = 1'b0; //NOP; its suppose to 
            end
        // if(EX_load_instr  )
            if(ID_Bit19_16 == EX_Bit15_12 && ID_shift_imm==0) begin
            IF_ID_load = 1'b0; //Disable pipeline Load
            PC_RF_load = 1'b0; //Disable PC load
            MUXControlUnit_signal = 1'b0; //NOP
            end else begin
                //    IF_ID_load = 1'b0; //Disable pipeline Load
            // PC_RF_load = 1'b0; //Disable PC load
            MUXControlUnit_signal = 1'b1; 
            end
        end
        //DATA Forwarding
        if(WB_RF_Enable) begin// && ((ID_Bit19_16 == EX_Bit15_12)||(ID_Bit3_0 == EX_Bit15_12))) begin
            //Valor del Main ALU
            if(ID_Bit19_16 == WB_Bit15_12)
                MUX1_signal = 2'b11;
          
                     
           
            if(ID_Bit3_0 == WB_Bit15_12 && ID_shift_imm==0)
                MUX2_signal = 2'b11;
          
        end  
        
        
        if(MEM_RF_Enable) begin// && ((ID_Bit19_16 == EX_Bit15_12)||(ID_Bit3_0 == EX_Bit15_12))) begin
            //Valor del Main ALU
            if(ID_Bit19_16 == MEM_Bit15_12  )
                MUX1_signal = 2'b10;
                             
           
            if(ID_Bit3_0 == MEM_Bit15_12 && ID_shift_imm==0)
                MUX2_signal = 2'b10;
           
        end

        if(EX_RF_Enable) begin// && ((ID_Bit19_16 == EX_Bit15_12)||(ID_Bit3_0 == EX_Bit15_12))) begin
            //Valor del Main ALU
            if(ID_Bit19_16 == EX_Bit15_12)
                MUX1_signal = 2'b01;
                              
           
            if(ID_Bit3_0 == EX_Bit15_12 && ID_shift_imm==0)
                MUX2_signal = 2'b01;
       end
   
    end

endmodule


module Sign_Shift_Extender (input [31:0]A, B, input [3:0] Cin_1, output reg [31:0]shift_result, output reg C);
    reg [31:0] temp_reg, temp_reg1, temp_reg2, rm, rm1;
    integer num_of_rot;
    integer i;
    reg [1:0] by_imm_shift;
    reg [2:0] shifter_op;
    reg [1:0] shift;
 
    reg tc;
    reg relleno;
    reg Cin;
    reg U;

    always@(*)

    begin
        shifter_op = B[27:25];
        by_imm_shift = B[6:5];
        temp_reg = A;
        Cin = Cin_1[1];
        case(shifter_op)

            3'b000:
            begin //Shift_by_Imm
                // temp_reg = A;
                num_of_rot = B[11:7];
                // tc = C;
                
                case(by_imm_shift)
                    2'b00:
                    begin //LSL
                        // $display("temp_reg: %b", temp_reg);

                        if(num_of_rot == 5'b0)begin
                            shift_result = temp_reg;
                            C = Cin;
                        end else begin
                            // temp_reg = {20'b0, A[11:0]};
                            for(i=0; i<num_of_rot; i= i+1)begin
                                // tc = temp_reg[31];
                                temp_reg = {temp_reg[30:0], 1'b0};
                            end
                            
                            shift_result = temp_reg;
                            C = A[32 - num_of_rot];
                        end
                        // $display("Shift_LSL: %b", shift_result);

                    end 

                    2'b01:
                    begin //LSR
                        if(num_of_rot == 5'b0)begin
                            shift_result = 32'b0;
                            C = A[31];
                        end else begin
                            for(i=0; i<num_of_rot; i= i+1)begin
                                // tc = temp_reg[0];
                                temp_reg = {1'b0, temp_reg[31:1]};
                            end
                            
                            shift_result = temp_reg;
                            C = A[num_of_rot - 1];
                        end
                    end 
                    
                    2'b10:
                    begin //ASR
                        // $display("temp_reg: %b", temp_reg);

                        if(num_of_rot == 5'b0)begin   
                            if(temp_reg[31] == 1'b0) begin
                                shift_result = 32'b0;
                                C = A[31];
                            end else begin
                                shift_result = 32'b11111111111111111111111111111111;
                                C = A[31];
                            end   
                        end else begin 
                            relleno = A[31];
                            for(i=0; i<num_of_rot; i= i+1)begin
                                // tc = temp_reg[0];
                                temp_reg = {relleno, temp_reg[31:1]};
                            end
                            shift_result = temp_reg;
                            C = A[num_of_rot - 1];
                        end
                        // $display("Shift_ASR: %b", shift_result);

                    end 

                    2'b11:
                    begin //ROR
                        // $display("temp_reg: %b ", temp_reg);
                        if(num_of_rot == 5'b0)begin
                            
                            shift_result = {1'b0, temp_reg[31:1]};
                            C = A[0];
                        end else begin
                            
                            for(i=0; i<num_of_rot; i= i+1)begin
                                // tc = temp_reg[0];
                                temp_reg = {temp_reg[0], temp_reg[31:1]};
                            end
                            shift_result = temp_reg;
                            C = A[num_of_rot - 1];
                            // $display("shift_result_ROR: %b ", shift_result);
                        end
                    end
                endcase
            end 
            
            3'b001:
            begin //Imm_shift_op_32_Imm
                temp_reg = {24'b0, B[7:0]};
                num_of_rot = 2*(B[11:8]);

                for(i = 0; i<num_of_rot; i=i+1)begin
                    temp_reg = {temp_reg[0], temp_reg[31:1]};
                end
                    shift_result = temp_reg;

                if(B[11:8] != 4'b0)
                    C = A[31];

            end 

            3'b010:
            begin //Immediate Offset
                shift_result = {20'b0, B[11:0]}; //effective address
               
            end 
            
            3'b011:
            begin 
                if(B[11:4] == 8'b0) begin //Register Offset 
                //  if(U == 1)
                    shift_result = {28'b0, B[3:0]}; //effective address
                // else 
                //     shift_result = {20'b0, B[19:16]} - A; //effective address
                end else begin //Scaled Register Offset
                    shift = B[6:5];
                    case(shift)
                        2'b00:
                        begin //LSL
                            for(i=0; i<num_of_rot; i= i+1)begin
                                temp_reg = {temp_reg[30:0], 1'b0};
                            end
                            shift_result = temp_reg;
                        end 

                        2'b01:
                        begin //LSR
                            if(num_of_rot == 0)
                                temp_reg = 32'b0;
                            else begin
                                for(i=0; i<num_of_rot; i= i+1)begin
                                    // tc = temp_reg[0];
                                    temp_reg = {1'b0, temp_reg[31:1]};
                                end
                            end
                            // C = tc;
                            shift_result = temp_reg;
                        end 
                        
                        2'b10:
                        begin //ASR
                            // $display("temp_reg: %b", temp_reg);
                            if(num_of_rot == 0)begin
                                if(A[31] == 1)
                                    temp_reg = 32'b11111111111111111111111111111111;
                                else 
                                    temp_reg = 32'b0;
                            end else begin   
                                relleno = A[31];
                                for(i=0; i<num_of_rot; i= i+1)begin
                                    // tc = temp_reg[0];
                                    temp_reg = {relleno, temp_reg[31:1]};
                                end
                            end 
                            // C = tc;
                            shift_result = temp_reg;
                        end 

                        2'b11:
                        begin //ROR
                            if(num_of_rot == 0)begin                                
                                // for(i=0; i<31; i= i+1)begin
                                //     tc = temp_reg[31];
                                    // temp_reg1 = {temp_reg[30:0], 1'b0};
                                // end
                                // tc = temp_reg1[31];
                                // rm = {28'b0, A[3:0]};
                                // for(i=0; i<1; i= i+1)begin
                                   // tc = rm[0];
                                temp_reg = {1'b0, A[31:1]};
                                // end
                                // rm1 = temp_reg2;

                                // temp_reg = tc || rm1;
                            end else begin
                                for(i=0; i<num_of_rot; i= i+1)begin
                                    // tc = temp_reg[0];
                                    temp_reg = {temp_reg[0], temp_reg[31:1]};
                                end
                            end
                            // C = tc;
                            shift_result = temp_reg;
                        end
                    endcase
                    
                end
            end 

            // 3'b100:
            // begin
            //     other_tmp = B[15:0];
            //     for(i = 0; i<=16; i = i+1)begin
            //         if(other_tmp[i] == 1)
            //             count = count + 1;
            //     end
            //     tmp1 = {27'b0, 5'b{count}};
            //     shift_result = tmp1 * 4; 
            // end      
        endcase
    end
endmodule


//Author: Víctor A. Nazario Morales
//Created on: September 20, 2020
//Description: Defines all the needed components (here modules) for the correct functionality of
//a register file according to PF1 specifications.

module register_file(PA, PB, PD, PW, PCin, PCout, R14out, C, SA, SB, RFLd, HZPCld, CLK, RST);
    //Outputs
    output [31:0] PA, PB, PD, PCout, R14out;
    output [31:0] MO; //output of the 2x1 multiplexer
    output [1:0] R15MO; //Output of mux used to select which input to charge PCin or PW
    //Inputs
    input [31:0] PW, PCin;
    input [3:0] SA, SB, C;
    input RFLd, CLK, RST, HZPCld;

    wire [31:0] Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15;
    wire [15:0] E;

    //Binary Decoder
    binary_decoder bc (E, C, RFLd);

    //Multiplexers
    multiplexer muxA (PA, Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, SA);
    multiplexer muxB (PB, Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, SB);
    multiplexer muxD (PD, Q0, Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, C);


    //loadDecoder r15decoder(E[15], R15MO);

    //Added this 2x1 multi to handle R15 input variations
    //Here PC is equivalent to PW in the diagram and PCin
    //is the equivalent to the PC (which gets increaed by 4)
    twoToOneMultiplexer r15mux (PW, PCin, E[15], MO);


    //16 Registers
    register R0 (Q0, PW, E[0], CLK, RST);
    register R1 (Q1, PW, E[1], CLK, RST);
    register R2 (Q2, PW, E[2], CLK, RST);
    register R3 (Q3, PW, E[3], CLK, RST);
    register R4 (Q4, PW, E[4], CLK, RST);
    register R5 (Q5, PW, E[5], CLK, RST);
    register R6 (Q6, PW, E[6], CLK, RST);
    register R7 (Q7, PW, E[7], CLK, RST);
    register R8 (Q8, PW, E[8], CLK, RST);
    register R9 (Q9, PW, E[9], CLK, RST);
    register R10 (Q10, PW, E[10], CLK, RST);
    register R11 (Q11, PW, E[11], CLK, RST);
    register R12 (Q12, PW, E[12], CLK, RST);
    register R13 (Q13, PW, E[13], CLK, RST);
    register R14 (Q14, PW, E[14], CLK, RST);
    PCregister R15 (Q15, MO, HZPCld, CLK, RST);
    assign PCout = Q15;
    assign R14out = Q14;

endmodule

module binary_decoder(E, C, Ld);
    //Output
    output reg [15:0] E;
    //Inputs
    input [3:0] C;
    input Ld;

    always @(C, Ld)

        if(Ld)
            case(C)
                4'b0000: E <= 16'b0000000000000001;
                4'b0001: E <= 16'b0000000000000010;
                4'b0010: E <= 16'b0000000000000100;
                4'b0011: E <= 16'b0000000000001000;
                4'b0100: E <= 16'b0000000000010000;
                4'b0101: E <= 16'b0000000000100000;
                4'b0110: E <= 16'b0000000001000000;
                4'b0111: E <= 16'b0000000010000000;
                4'b1000: E <= 16'b0000000100000000;
                4'b1001: E <= 16'b0000001000000000;
                4'b1010: E <= 16'b0000010000000000;
                4'b1011: E <= 16'b0000100000000000;
                4'b1100: E <= 16'b0001000000000000;
                4'b1101: E <= 16'b0010000000000000;
                4'b1110: E <= 16'b0100000000000000;
                4'b1111: E <= 16'b1000000000000000;
            endcase
        else  E <= 16'b0000000000000000;

endmodule

module multiplexer(P, I0, I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15, S);
    //Output
    output reg [31:0] P;
    //Inputs
    input [31:0] I0, I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15;
    input [3:0] S;

    always @(S, I0, I1, I2, I3, I4, I5, I6, I7, I8, I9, I10, I11, I12, I13, I14, I15)

    case (S)
        4'b0000: P <= I0;
        4'b0001: P <= I1;
        4'b0010: P <= I2;
        4'b0011: P <= I3;
        4'b0100: P <= I4;
        4'b0101: P <= I5;
        4'b0110: P <= I6;
        4'b0111: P <= I7;
        4'b1000: P <= I8;
        4'b1001: P <= I9;
        4'b1010: P <= I10;
        4'b1011: P <= I11;
        4'b1100: P <= I12;
        4'b1101: P <= I13;
        4'b1110: P <= I14;
        4'b1111: P <= I15;

    endcase
endmodule

//This defines the multiplexer used to change inputs to r15 conditionally
module twoToOneMultiplexer(PW, PC, PWLd, MO);
    //Output
    output reg [31:0] MO;
    //Input
    input[31:0] PW, PC;
    input PWLd;

    //Whenever a change is produced in the signals, change the output
    //according with the stablished logic.
    always @(PW, PC, PWLd)
    begin
        if (PWLd)
            MO <= PW;
        else
            MO <= PC;
    end
endmodule

//module loadDecoder(RFLd, R15MO);
////When the binary decoder assigns a value of one to E[15] that means R15 has RFLd = 1,
//// thus we write PW instead of PCin. So R15 is going to be 1 which in terms means PW will be loaded.
////Otherwise we set it to 0 and PCin is loaded into the register.
//output reg[1:0] R15MO;
//input RFLd;
//
////What happens when both = 1?
////Does this means that the following is accomplished?
//
////El PC tendrá una señal de “load enable” que cuando esté activa permitirá que el valor externo se cargue en el PC cuando
////ocurra el “rising edge” del reloj del sistema, excepto cuando el puerto de entrada trate de escribir
////el mismo, lo cual tiene prioridad.
//always @ (RFLd)
//    begin
//        if(RFLd)
//          R15MO <= 1'b1;
//        else
//          R15MO <= 1'b0;
//    end
//endmodule


module register(Q, PW, RFLd, CLK, RST);
    //Output
    output reg [31:0] Q;
    //Inputs
    input [31:0] PW;
    input RFLd, CLK, RST;

    always @ (posedge CLK, posedge RST)
        if(RST) Q <= 0;

        else if(RFLd) Q <= PW;

endmodule

module PCregister(Q, MOin, HZPCld, CLK, RST);
    //Output
    output reg [31:0] Q;
    //Inputs
    input [31:0] MOin;
    input HZPCld, CLK, RST;

    always @ (posedge CLK, posedge RST)
        if(RST)
            Q <= 32'b0;

        else if(HZPCld)
            Q <= MOin;
endmodule






/*Creator: Ashley Ortiz Colon
*/

module alu(input signed [31:0] A, B, input [3:0] OPS, input [3:0] ccCin, output signed [31:0] S, output [3:0] Alu_Out); // N, Z, C, V);

    reg signed [32:0] OPS_result;

    integer tn = 0; 
    integer tz = 0; 
    integer tc = 0; 
    integer tv = 0; 
    integer ol = 0;
    integer Cin =0;



    assign Alu_Out[3] = tn; //Negative
    assign Alu_Out[2] = tz; //Zero 
    assign Alu_Out[1] = tc; //Carry Out
    assign Alu_Out[0] = tv; //Overflow

    // integer mod_cond_codes;

    assign S = OPS_result[31:0];
   
    always@(*)
    begin
        Cin = ccCin[1];
        // mod_cond_codes = B[20];
        // $display ("A: %d | B: %d | OPS:%b", A, B, OPS);
        //$display ("OPS:%b", OPS);
        case(OPS)
            //0
            4'b0000: //Logical AND
            OPS_result = A & B;

            //1
            4'b0001: //Logical Exclusive OR
            OPS_result = A ^ B;

            //2
            4'b0010: //Subtract
            begin
                OPS_result = A - B;  
                 if(A[31] != B[31])begin
                    if( A[31] == 0  && B[31] == 1 && OPS_result[31]== B[31]) 
                    // if(OPS_result[31] ==A[31])
                        tv = 1;
                    else if(A[31] == 1 && B[31] == 0 && OPS_result[31] ==B[31])// || OPS_result[31] == A[31]))
                        tv = 1;
                    else
                        tv = 0;
           
                end //else
                // tv= (A[31] & !B[31] & !OPS_result[31]) | (!A[31] & B[31] & OPS_result[31]);
                // ol = 1;
             //   $display("A-B: ");
            end
      

            //3
            4'b0011: //Reverse Subtract
            begin
                OPS_result = B - A;  
                    if(A[31] != B[31])begin

                        if( B[31] == 0 && A[31] == 1 && OPS_result[31] == A[31])
                            tv = 1;
                            // else
                            //     tv = 1;
                        else if(B[31] == 1 && A[31] == 0 && OPS_result[31]== A[31])
                            // if(OPS_result[31] == A[31])
                                tv = 1;
                        else
                                tv = 0;
                    end
            // tv=0;
                tv=	(!A[31] & B[31] & !OPS_result[31]) | (A[31] & !B[31] & OPS_result[31]);
                // ol = 2;
              //  $display("B-A: ");

            end
                     
            //4
            4'b0100: //Add
            begin
                OPS_result = A + B;
                 if(A[31] == B[31])begin
                    if(A[31] != OPS_result[31])
                        tv = 1;
                    else 
                        tv = 0;
                //else
                end else  tv = 0;

                //    tv = (A[31] & B[31] & !OPS_result[31]) | (!A[31] & !B[31] & OPS_result[31]);
                // ol = 3;
              //  $display("A+B: ");

            end
            //5
            4'b0101: //Add w. Carry
            begin
                OPS_result = A + B + Cin;
                 if(A[31] == B[31])begin
                    if(A[31] != OPS_result[31])
                        tv = 1;
                    else 
                        tv = 0;
                //else
                end else  tv = 0;

                // tv = (A[31] & B[31] & !OPS_result[31]) | (!A[31] & !B[31] & OPS_result[31]);
                // ol = 3;
            end

            //6
            4'b0110: //Subtract w. Carry
            begin
                OPS_result = A - B - !Cin; //(~{31'b0,Cin});
                 if(A[31] != B[31])begin
                    if( A[31] == 0  && B[31] == 1 && OPS_result[31]== B[31]) 
                    // if(OPS_result[31] ==A[31])
                        tv = 1;
                    else if(A[31] == 1 && B[31] == 0 && OPS_result[31] ==B[31])// || OPS_result[31] == A[31]))
                        tv = 1;
                    else
                        tv = 0;
           
                end //else
                //  tv= (A[31] & !B[31] & !OPS_result[31]) | (!A[31] & B[31] & OPS_result[31]);
                // ol = 4;
              //  $display("A-B-CARRY: ");

            end 
            //7
            4'b0111: //Reverse Subtract w. Carr
            begin 
                OPS_result = B - A - !Cin; //(~{31'b0,Cin}); 
                    if(A[31] != B[31])begin

                        if( B[31] == 0 && A[31] == 1 && OPS_result[31] == A[31])
                            tv = 1;
                         
                        else if(B[31] == 1 && A[31] == 0 && OPS_result[31]== A[31])
                            // if(OPS_result[31] == A[31])
                                tv = 1;
                        else
                                tv = 0;
                    end
            // tv=0;
                // tv=	(!A[31] & B[31] & !OPS_result[31]) | (A[31] & !B[31] & OPS_result[31]);
                // ol = 5;
               // $display("B-A-CARRY: ");

            end
            
            //8
            4'b1000: //Test 
            OPS_result = A & B;
            //flag update 

            //9
            4'b1001: //Test Equivalence
            OPS_result = A ^ B;
            //flag update

            //10
            4'b1010: //Compare
            begin
                OPS_result = A - B;  
               /* if(A[31] != B[31])begin
                    if( A[31] == 0  && B[31] == 1 && OPS_result[31]== B[31]) 
                    // if(OPS_result[31] ==A[31])
                        tv = 1;
                    else if(A[31] == 1 && B[31] == 0 && OPS_result[31] ==B[31])// || OPS_result[31] == A[31]))
                        tv = 1;
                    else
                        tv = 0;
           
                end *///else
               tv = (OPS_result[32]);//  != OPS_result[32]) ? 1:0;
            //     tv=0;
                // tv = (A[31] & !B[31] & !OPS_result[31]) | (!A[31] & B[31] & OPS_result[31]);
                // ol = 1;
               // $display("Compare: ");
            end

            //11
            4'b1011: //Compare Negated
            begin
                OPS_result = A + B;
              /*  if(A[31] == B[31])begin
                    if(A[31] != OPS_result[31])
                        tv = 1;
                    else 
                        tv = 0;
                //else
                end else  tv = 0;*/

                // tv = (OPS_result[31]  != OPS_result[32])? 1:0;

                tv = OPS_result[32]; // ^Cin ^ ;// !(A[31] ^ B[31]) && (B[31] ^ OPS_result[31]) ;// Cin ^ (OPS_result[32]); // == 1'b1) ; //&& (A[31] & B[31] & !OPS_result[31]) | (!A[31] & !B[31] & OPS_result[31]) ? 1:0; //(;
               // ol = 3;
            //    $display("Neg Compare: ");
            end


            //12
            4'b1100: //Logical Or
            OPS_result = A | B;

            //13
            4'b1101: //Move
            OPS_result = B;

            //14
            4'b1110: //Bit Clear
            OPS_result = A & (~B);

            //15
            4'b1111: //Move Not
            OPS_result = ~B;
        endcase
       // $display("%d",OPS_result[31:0]);
        //for when result is zero
        tz = (OPS_result == 32'b0) ? 1:0;
    
        
        //for when result is negative
        tn = (OPS_result[31] == 1'b1) ? 1:0;
        
        //for Carry out
        tc = OPS_result[32];
    

        //for when result provokes overflow
        // if(ol == 1) begin // subtract
        //     // if(A[31] != B[31])begin
        //         if( A[31] == 0  && B[31] == 1 && OPS_result[31]== B[31]) 
        //         // if(OPS_result[31] ==A[31])
        //             tv = 1;
        //         //else
        //         //tv = 0;

        //         else if(A[31] == 1 && B[31] == 0 && OPS_result[31] ==B[31])// || OPS_result[31] == A[31]))
        //             tv = 1;
        //         else
        //             tv = 0;
           
        //     // end //else
        //     //     tv=0;
            
        // end


        // if(ol == 2) begin //revers sub
        //     // if(A[31] != B[31])begin

        //         if( B[31] == 0 && A[31] == 1 && OPS_result[31] == A[31])
        //             tv = 1;
        //             // else
        //             //     tv = 1;
        //         else if(B[31] == 1 && A[31] == 0 && OPS_result[31]== A[31])
        //             // if(OPS_result[31] == A[31])
        //                 tv = 1;
        //         else
        //                 tv = 0;
        //     // end
        //     // tv=0;
        // end

        // if(ol ==3)begin // addition
        //     if(A[31] == B[31])begin
        //         if(A[31] != OPS_result[31])
        //             tv = 1;
        //         else 
        //             tv = 0;
        //      //else
        //     end else  tv = 0;

        // end

        // if(ol == 4) begin
        //     if((A + Cin) < (B + 1'b1 ) && OPS_result[31] == 1)
        //         tv = 0;
        //     else if((A+Cin) >= (B + 1'b1 ) && (OPS_result[31] == 0 || OPS_result[31] == A[31]))
        //         tv = 0;
        //     else
        //         tv = 1;
        // end 
        // if(ol == 5) begin
        //     if((B + Cin) < (A+ 1'b1 ) && OPS_result[31] == 1)
        //         tv = 0;
        //     else if((B+Cin) >= (A + 1'b1) && (OPS_result[31] == 0 || OPS_result[31] == B[31]))
        //         tv = 0;
        //     else
        //         tv = 1;
        // end
        
        
        //     // tv = 0;
        //     // ol = 0;

        // // $display ("A: %d | B: %d | OPS:%b", A, B, OPS);

        // // $monitor("alu result:", OPS_result);
    end

endmodule
