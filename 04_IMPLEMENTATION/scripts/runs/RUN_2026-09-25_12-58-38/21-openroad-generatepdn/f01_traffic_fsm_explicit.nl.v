module f01_traffic_fsm_explicit (clk,
    ena,
    night_mode,
    rst_n,
    uo_out,
    VPWR,
    VGND);
 input clk;
 input ena;
 input night_mode;
 input rst_n;
 output [7:0] uo_out;
 inout VPWR;
 inout VGND;

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
 wire nc;
 wire night_phase;
 wire \pc[0] ;
 wire \pc[1] ;

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
 sky130_fd_sc_hd__nor2_2 _18_ (.A(uo_out[7]),
    .B(night_mode),
    .Y(uo_out[5]));
 sky130_fd_sc_hd__and2b_2 _19_ (.A_N(uo_out[6]),
    .B(uo_out[5]),
    .X(uo_out[0]));
 sky130_fd_sc_hd__a22o_2 _20_ (.A1(night_phase),
    .A2(night_mode),
    .B1(uo_out[5]),
    .B2(uo_out[6]),
    .X(uo_out[1]));
 sky130_fd_sc_hd__and2b_2 _21_ (.A_N(night_mode),
    .B(uo_out[7]),
    .X(uo_out[2]));
 sky130_fd_sc_hd__and2b_2 _22_ (.A_N(uo_out[6]),
    .B(uo_out[2]),
    .X(uo_out[3]));
 sky130_fd_sc_hd__a22o_2 _23_ (.A1(night_phase),
    .A2(night_mode),
    .B1(uo_out[2]),
    .B2(uo_out[6]),
    .X(uo_out[4]));
 sky130_fd_sc_hd__nand2_2 _24_ (.A(ena),
    .B(\pc[0] ),
    .Y(_06_));
 sky130_fd_sc_hd__and3_2 _25_ (.A(ena),
    .B(\pc[1] ),
    .C(\pc[0] ),
    .X(_07_));
 sky130_fd_sc_hd__and2b_2 _26_ (.A_N(night_mode),
    .B(ena),
    .X(_08_));
 sky130_fd_sc_hd__and4b_2 _27_ (.A_N(night_mode),
    .B(\pc[0] ),
    .C(\pc[1] ),
    .D(ena),
    .X(_09_));
 sky130_fd_sc_hd__o21ai_2 _28_ (.A1(uo_out[6]),
    .A2(_09_),
    .B1(rst_n),
    .Y(_10_));
 sky130_fd_sc_hd__a21oi_2 _29_ (.A1(uo_out[6]),
    .A2(_09_),
    .B1(_10_),
    .Y(_00_));
 sky130_fd_sc_hd__a21o_2 _30_ (.A1(uo_out[6]),
    .A2(_09_),
    .B1(uo_out[7]),
    .X(_11_));
 sky130_fd_sc_hd__nand3_2 _31_ (.A(uo_out[6]),
    .B(uo_out[2]),
    .C(_07_),
    .Y(_12_));
 sky130_fd_sc_hd__and3_2 _32_ (.A(rst_n),
    .B(_11_),
    .C(_12_),
    .X(_01_));
 sky130_fd_sc_hd__o211a_2 _33_ (.A1(\pc[0] ),
    .A2(_08_),
    .B1(_06_),
    .C1(rst_n),
    .X(_02_));
 sky130_fd_sc_hd__a21o_2 _34_ (.A1(ena),
    .A2(\pc[0] ),
    .B1(\pc[1] ),
    .X(_13_));
 sky130_fd_sc_hd__nand2_2 _35_ (.A(ena),
    .B(night_mode),
    .Y(_14_));
 sky130_fd_sc_hd__and4b_2 _36_ (.A_N(_07_),
    .B(_13_),
    .C(_14_),
    .D(rst_n),
    .X(_03_));
 sky130_fd_sc_hd__a21o_2 _37_ (.A1(ena),
    .A2(night_mode),
    .B1(nc),
    .X(_15_));
 sky130_fd_sc_hd__nand2_2 _38_ (.A(nc),
    .B(ena),
    .Y(_16_));
 sky130_fd_sc_hd__and3_2 _39_ (.A(rst_n),
    .B(_15_),
    .C(_16_),
    .X(_04_));
 sky130_fd_sc_hd__xnor2_2 _40_ (.A(night_phase),
    .B(_16_),
    .Y(_17_));
 sky130_fd_sc_hd__and3b_2 _41_ (.A_N(_08_),
    .B(_17_),
    .C(rst_n),
    .X(_05_));
 sky130_fd_sc_hd__dfxtp_2 _42_ (.CLK(clk),
    .D(_00_),
    .Q(uo_out[6]));
 sky130_fd_sc_hd__dfxtp_2 _43_ (.CLK(clk),
    .D(_01_),
    .Q(uo_out[7]));
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
endmodule
