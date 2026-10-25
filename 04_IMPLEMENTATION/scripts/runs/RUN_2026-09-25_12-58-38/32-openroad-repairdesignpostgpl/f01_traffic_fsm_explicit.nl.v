module f01_traffic_fsm_explicit (clk,
    ena,
    night_mode,
    rst_n,
    uo_out);
 input clk;
 input ena;
 input night_mode;
 input rst_n;
 output [7:0] uo_out;

 wire _00_;
 wire _01_;
 wire _02_;
 wire _03_;
 wire _04_;
 wire _05_;
 wire _06_;
 wire _07_;
 wire _08_;
 wire _09_;
 wire _10_;
 wire _11_;
 wire _12_;
 wire _13_;
 wire _14_;
 wire _15_;
 wire _16_;
 wire _17_;
 wire net1;
 wire nc;
 wire net2;
 wire night_phase;
 wire \pc[0] ;
 wire \pc[1] ;
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net8;
 wire net9;
 wire net10;
 wire net11;

 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_0_Left_10 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_0_Right_0 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_1_Left_11 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_1_Right_1 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_2_Left_12 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_2_Right_2 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_3_Left_13 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_3_Right_3 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_4_Left_14 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_4_Right_4 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_5_Left_15 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_5_Right_5 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_6_Left_16 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_6_Right_6 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_7_Left_17 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_7_Right_7 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_8_Left_18 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_8_Right_8 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_9_Left_19 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_9_Right_9 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_0_20 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_0_21 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_1_22 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_2_23 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_3_24 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_4_25 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_5_26 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_6_27 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_7_28 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_8_29 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_9_30 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_9_31 ();
 sky130_fd_sc_hd__nor2_2 _18_ (.A(net11),
    .B(net2),
    .Y(net9));
 sky130_fd_sc_hd__and2b_2 _19_ (.A_N(net10),
    .B(net9),
    .X(net4));
 sky130_fd_sc_hd__a22o_2 _20_ (.A1(night_phase),
    .A2(net2),
    .B1(net9),
    .B2(net10),
    .X(net5));
 sky130_fd_sc_hd__and2b_2 _21_ (.A_N(net2),
    .B(net11),
    .X(net6));
 sky130_fd_sc_hd__and2b_2 _22_ (.A_N(net10),
    .B(net6),
    .X(net7));
 sky130_fd_sc_hd__a22o_2 _23_ (.A1(night_phase),
    .A2(net2),
    .B1(net6),
    .B2(net10),
    .X(net8));
 sky130_fd_sc_hd__nand2_2 _24_ (.A(net1),
    .B(\pc[0] ),
    .Y(_06_));
 sky130_fd_sc_hd__and3_2 _25_ (.A(net1),
    .B(\pc[1] ),
    .C(\pc[0] ),
    .X(_07_));
 sky130_fd_sc_hd__and2b_2 _26_ (.A_N(net2),
    .B(net1),
    .X(_08_));
 sky130_fd_sc_hd__and4b_2 _27_ (.A_N(net2),
    .B(\pc[0] ),
    .C(\pc[1] ),
    .D(net1),
    .X(_09_));
 sky130_fd_sc_hd__o21ai_2 _28_ (.A1(net10),
    .A2(_09_),
    .B1(net3),
    .Y(_10_));
 sky130_fd_sc_hd__a21oi_2 _29_ (.A1(net10),
    .A2(_09_),
    .B1(_10_),
    .Y(_00_));
 sky130_fd_sc_hd__a21o_2 _30_ (.A1(net10),
    .A2(_09_),
    .B1(net11),
    .X(_11_));
 sky130_fd_sc_hd__nand3_2 _31_ (.A(net10),
    .B(net6),
    .C(_07_),
    .Y(_12_));
 sky130_fd_sc_hd__and3_2 _32_ (.A(net3),
    .B(_11_),
    .C(_12_),
    .X(_01_));
 sky130_fd_sc_hd__o211a_2 _33_ (.A1(\pc[0] ),
    .A2(_08_),
    .B1(_06_),
    .C1(net3),
    .X(_02_));
 sky130_fd_sc_hd__a21o_2 _34_ (.A1(net1),
    .A2(\pc[0] ),
    .B1(\pc[1] ),
    .X(_13_));
 sky130_fd_sc_hd__nand2_2 _35_ (.A(net1),
    .B(net2),
    .Y(_14_));
 sky130_fd_sc_hd__and4b_2 _36_ (.A_N(_07_),
    .B(_13_),
    .C(_14_),
    .D(net3),
    .X(_03_));
 sky130_fd_sc_hd__a21o_2 _37_ (.A1(net1),
    .A2(net2),
    .B1(nc),
    .X(_15_));
 sky130_fd_sc_hd__nand2_2 _38_ (.A(nc),
    .B(net1),
    .Y(_16_));
 sky130_fd_sc_hd__and3_2 _39_ (.A(net3),
    .B(_15_),
    .C(_16_),
    .X(_04_));
 sky130_fd_sc_hd__xnor2_2 _40_ (.A(night_phase),
    .B(_16_),
    .Y(_17_));
 sky130_fd_sc_hd__and3b_2 _41_ (.A_N(_08_),
    .B(_17_),
    .C(net3),
    .X(_05_));
 sky130_fd_sc_hd__dfxtp_2 _42_ (.CLK(clk),
    .D(_00_),
    .Q(net10));
 sky130_fd_sc_hd__dfxtp_2 _43_ (.CLK(clk),
    .D(_01_),
    .Q(net11));
 sky130_fd_sc_hd__dfxtp_2 _44_ (.CLK(clk),
    .D(_02_),
    .Q(\pc[0] ));
 sky130_fd_sc_hd__dfxtp_2 _45_ (.CLK(clk),
    .D(_03_),
    .Q(\pc[1] ));
 sky130_fd_sc_hd__dfxtp_2 _46_ (.CLK(clk),
    .D(_04_),
    .Q(nc));
 sky130_fd_sc_hd__dfxtp_2 _47_ (.CLK(clk),
    .D(_05_),
    .Q(night_phase));
 sky130_fd_sc_hd__clkdlybuf4s25_1 input1 (.A(ena),
    .X(net1));
 sky130_fd_sc_hd__clkdlybuf4s25_1 input2 (.A(night_mode),
    .X(net2));
 sky130_fd_sc_hd__clkdlybuf4s25_1 input3 (.A(rst_n),
    .X(net3));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output10 (.A(net10),
    .X(uo_out[6]));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output11 (.A(net11),
    .X(uo_out[7]));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output4 (.A(net4),
    .X(uo_out[0]));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output5 (.A(net5),
    .X(uo_out[1]));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output6 (.A(net6),
    .X(uo_out[2]));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output7 (.A(net7),
    .X(uo_out[3]));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output8 (.A(net8),
    .X(uo_out[4]));
 sky130_fd_sc_hd__clkdlybuf4s25_1 output9 (.A(net9),
    .X(uo_out[5]));
endmodule
