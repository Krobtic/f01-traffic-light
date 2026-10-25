# F01 · Sơ đồ khối bên trong (Block Diagram)

---

## 1. Cấu trúc thật, vẽ theo RTL và netlist

F01 chia thành **bốn khối con** rõ rệt. Chỉ khối 1 là FSM; ba khối còn lại là datapath
điều khiển và giải mã.

```
   ena ──┬──────────────────────────────────────────────────────────────┐
 rst_n ──┼──┬───────────────────────────────────────────────────────┐   │
night_mode┼─┼──┬─────────────────────────────┬──────────────────┐   │   │
          │ │  │                             │                  │   │   │
          │ │  ▼                             ▼                  │   │   │
   ┌──────┼─┼──────────────┐    ┌────────────────────────┐      │   │   │
   │ ② BỘ ĐẾM PHA          │    │ ③ BỘ ĐẾM NHẤP NHÁY ĐÊM │      │   │   │
   │    pc[1:0]  (2 FF)    │    │    nc (1 FF)           │      │   │   │
   │                       │    │    night_phase (1 FF)  │      │   │   │
   │  tick = (pc==P-1)     │    │  lật khi nc==NIGHT-1   │      │   │   │
   └───────────┬───────────┘    └───────────┬────────────┘      │   │   │
               │ tick                       │ night_phase       │   │   │
               ▼                            │                   │   │   │
   ┌───────────────────────┐                │                   │   │   │
   │ ① FSM 4 PHA           │                │                   │   │   │
   │   state[1:0] (2 FF)   │                │                   │   │   │
   │   NS_G→NS_Y→EW_G→EW_Y │◀───────────────┼───────────────────┘   │   │
   │   (đóng băng khi đêm) │                │   night_mode          │   │
   └───────────┬───────────┘                │                       │   │
               │ state[1:0]                 │                       │   │
               ├────────────────────────────┼───────────────────────┼───┼──▶ uo_out[7:6]
               ▼                            ▼                       │   │
   ┌─────────────────────────────────────────────────────────────┐  │   │
   │ ④ BẢNG GIẢI MÃ ĐẦU RA + LỚP PHỦ ĐÊM  (6 cell tổ hợp)        │  │   │
   │                                                             │  │   │
   │   uo_out[0] = nor3(s1, s0, night)      ← hướng 1 XANH        │  │   │
   │   uo_out[1] = (s0 & ~s1 & ~night) | (night & night_phase)    │  │   │
   │   uo_out[2] = nor2(~s1, night)         ← hướng 1 ĐỎ          │  │   │
   │   uo_out[3] = nor3(~s1, s0, night)     ← hướng 2 XANH        │  │   │
   │   uo_out[4] = (s0 &  s1 & ~night) | (night & night_phase)    │  │   │
   │   uo_out[5] = nor2(s1, night)          ← hướng 2 ĐỎ          │  │   │
   └─────────────────────────────────────────────────────────────┘  │   │
                                                                     ▼   ▼
                                            (rst_n, ena tới TẤT CẢ thanh ghi)
```

`s1 = state[1] = uo_out[7]`, `s0 = state[0] = uo_out[6]` — xem §3.

## 2. Bảng ánh xạ RTL → phần cứng sinh ra

Số cell lấy từ `06_GDSII/synthesis/synth_stat.txt` (32 cell, 279,0176 µm²), diện tích từng
cell lấy từ liberty `sky130_fd_sc_hd__tt_025C_1v80`.

| Khối | Dòng RTL (`f01_traffic_fsm.sv`) | Cell sinh ra | Diện tích (µm²) |
|---|---|---|---:|
| ① FSM 4 pha | `:14–21` enum, `:33–44` case, `:55` `state <= next_state` | 2 × `dfxtp_1` + logic next-state (`_24_` `and4b_1`, `_25_` `o21ai_0`, `_26_` `a21oi_1`, `_27_` `a21o_1`, `_28_` `nand3_1`, `_29_` `a21boi_0`) | 40,0384 (FF) + 40,0384 (logic) |
| ② Bộ đếm pha | `:22` `logic [PW-1:0] phase_cnt`, `:68–73` | 2 × `dfxtp_1` + `_20_` `clkinv_1`, `_22_` `and2_0`, `_33_` `mux2i_1`, `_34_` `and2_0`, `_35_` `o22ai_1`, `_36_` `o211a_1` | 40,0384 (FF) + 42,5408 (logic) |
| ③ Bộ đếm đêm | `:23–24`, `:57–64` | 2 × `dfxtp_1` + `_30_` `nand2_1`, `_31_` `xnor2_1`, `_32_` `and3_1`, `_37_` `a21oi_1`, `_38_` `nand2_1`, `_39_` `nor2_1` | 40,0384 (FF) + 31,2800 (logic) |
| ④ Giải mã đầu ra | `:78–111` | `_40_` `nor2_1`, `_41_` `nor3_1`, `_42_` `a22o_1`, `_43_` `nor2_1`, `_44_` `nor3_1`, `_45_` `a22o_1` | 35,0336 |
| Chung (`_21_` `clkinv_1`, `_23_` `nand2b_1`) | `:54` `else if (ena)`, `:29` `if (night_mode)` | 2 cell dùng chung nhiều khối | 10,0096 |
| | | **Tổng 32 cell** | **279,0176** ✅ |

Tổng cột cuối khớp **chính xác** con số Yosys báo (`Chip area … 279.017600`).

**Phân chia tuần tự / tổ hợp:**

| Nhóm | Diện tích (µm²) | Tỉ lệ |
|---|---:|---:|
| 6 × `dfxtp_1` (tuần tự) | 120,1152 | **43,05 %** |
| 26 cell tổ hợp | 158,9024 | **56,95 %** |

Kiểm chéo bằng `06_GDSII/power/power_report.txt`: Sequential **92,8 %**, Combinational
**7,2 %** của tổng 2,76e-05 W. Hai tỉ lệ rất lệch nhau — **không mâu thuẫn**: flip-flop
tiêu công suất nội tại ở **mọi** cạnh clock, còn logic tổ hợp của F01 chuyển trạng thái
rất thưa (mỗi `PHASE_TICKS` chu kỳ mới có một lần đổi pha).

## 3. Phát hiện quan trọng trong netlist: thanh ghi trạng thái **chính là** cổng ra

Trích `06_GDSII/synthesis/netlist.v`:

```verilog
sky130_fd_sc_hd__dfxtp_1 _46_ (.CLK(clk), .D(_00_), .Q(uo_out[6]));
sky130_fd_sc_hd__dfxtp_1 _47_ (.CLK(clk), .D(_01_), .Q(uo_out[7]));
```

Không có net trung gian tên `state`. Yosys nhận ra `uo_out[7:6] = state;` là phép nối dây
thuần, nên **hợp nhất** thanh ghi trạng thái với cổng ra. Hệ quả:

1. `uo_out[7:6]` **không** phải là bản sao của trạng thái — nó **là** trạng thái. Mã trạng
   thái ra chân là **miễn phí**, 0 cell.
2. Logic giải mã đầu ra đọc trực tiếp `uo_out[6]`/`uo_out[7]` làm đầu vào (xem `_41_`,
   `_42_`, `_44_`, `_45_`). Điều này trông lạ khi đọc netlist lần đầu — một cổng **ra**
   xuất hiện ở chân **vào** của cell khác — nhưng hoàn toàn hợp lệ.
3. **Đây cũng là lý do Yosys KHÔNG đổi sang mã hoá one-hot** — phân tích ở `fsm.md` §5.

## 4. Chia sẻ logic giữa các bit đầu ra

Netlist cho thấy Yosys tái sử dụng đầu ra của cell này làm đầu vào cell khác:

```verilog
sky130_fd_sc_hd__nor2_1 _40_ (.A(uo_out[7]), .B(night_mode), .Y(uo_out[5]));
sky130_fd_sc_hd__a22o_1 _42_ (.A1(night_phase), .A2(night_mode),
                              .B1(uo_out[5]),  .B2(uo_out[6]),  .X(uo_out[1]));
```

`uo_out[5]` (hướng 2 đỏ) được tái dùng làm số hạng cho `uo_out[1]` (hướng 1 vàng). Lý do:
`uo_out[5] = ~s1 & ~night`, và `uo_out[1]` cần đúng `s0 & ~s1 & ~night` — chỉ việc AND
thêm `uo_out[6]`. Tương tự `uo_out[2]` được tái dùng cho `uo_out[4]`.

> 🎓 **Bài học:** đừng cho rằng mỗi bit ra có một cây logic riêng. `abc` chia sẻ số hạng
> chung rất tích cực. Hệ quả thực tế: **một lỗi ở `uo_out[5]` sẽ lan sang `uo_out[1]`** —
> hai đèn ở hai hướng khác nhau hỏng cùng lúc. Điều này quan trọng khi phân tích lỗi đơn
> (single-fault analysis) cho một hệ thống an toàn.

## 5. Khối con nào nằm trên đường tới hạn?

Đối chiếu `06_GDSII/sta/`:

| Hạng | Startpoint → Endpoint | Cell trên đường | Arrival | Slack | Khối con |
|---:|---|---|---:|---:|---|
| **1** | `night_mode` → `uo_out[1]` | **1**: `_42_` (`a22o_1`) | 1,18 ns | **7,82 ns** | **④ Giải mã đầu ra** |
| 1= | `night_mode` → `uo_out[4]` | 1: `_45_` (`a22o_1`) | 1,18 ns | 7,82 ns | ④ |
| 3 | `night_mode` → `uo_out[0]`,`[2]`,`[3]`,`[5]` | 1 cell | 1,06 ns | 7,94 ns | ④ |
| 7 | `ena` → `_47_` (FF `uo_out[7]`) | — | — | 8,43 ns | ① FSM |
| 8 | `ena` → `_46_` (FF `uo_out[6]`) | — | — | 8,48 ns | ① FSM |
| 9 | `ena` → `_48_` (FF `night_phase`) | — | — | 8,55 ns | ③ |
| 10 | `night_mode` → `_50_` (FF `pc[1]`) | — | — | 8,56 ns | ② |

**Kết luận, và nó trả lời trực tiếp Charter mục 2 câu 3:** đường tới hạn **không** đi qua
thanh ghi trạng thái. Nó là một đường **tổ hợp thuần** từ cổng vào `night_mode` tới cổng
ra `uo_out[1]`, dài đúng **một cell** (`a22o_1`, 0,18 ns).

Mười đường xấu nhất đều có slack ≥ 7,82 ns trên chu kỳ giả định 10 ns. Không có đường
reg→reg nào lọt vào top 10, nghĩa là logic next-state của FSM **nhanh hơn** cả đường giải
mã đầu ra. Với một FSM chỉ 4 trạng thái, đó là kết quả hợp lý.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
