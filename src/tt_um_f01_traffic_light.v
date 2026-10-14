`default_nettype none

module tt_um_f01_traffic_light (
    input  wire [7:0] ui_in,    // Các chân đầu vào cố định
    output wire [7:0] uo_out,   // Các chân đầu ra cố định (kết nối Đèn LED)
    input  wire [7:0] uio_in,   // Các chân I/O hai chiều (uio_in[0] = night_mode)
    output wire [7:0] uio_out,  // Các chân I/O hai chiều (đầu ra phụ)
    output wire [7:0] uio_oe,   // Chân cho phép xuất/nhập I/O (0=Input, 1=Output)
    input  wire       ena,      // Tín hiệu enable module
    input  wire       clk,      // Xung nhịp hệ thống
    input  wire       rst_n     // Tín hiệu reset tích cực mức thấp
);

    // Kết nối module FSM chính
    fsm_traffic_light fsm_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .uio_in (uio_in),
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_out(uio_out),
        .uio_oe (uio_oe)
    );

    // Triệt tiêu cảnh báo Verilator chuẩn Tiny Tapeout
    wire _unused = &{ena, 1'b0};

endmodule

`default_nettype wire