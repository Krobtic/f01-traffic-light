# F01 · Phần điều khiển (Control)

---

## 1. F01 gần như **toàn bộ** là phần điều khiển

Khác E07 (gần như toàn bộ là datapath), F01 là khối điều khiển thuần: không có dữ liệu
người dùng nào đi qua. 2 bit vào đều là lệnh, 8 bit ra đều là tín hiệu điều khiển đèn.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │            BA TẦNG ĐIỀU KHIỂN LỒNG NHAU trong F01                   │
  ├─────────────────────────────────────────────────────────────────────┤
  │                                                                     │
  │  TẦNG 1 — rst_n  : ép toàn bộ về trạng thái gốc     (ưu tiên CAO NHẤT)│
  │      │                                                              │
  │      └─▶ TẦNG 2 — ena : đóng băng MỌI thanh ghi                     │
  │              │                                                      │
  │              └─▶ TẦNG 3 — night_mode : đóng băng RIÊNG `state`,     │
  │                       chuyển bộ đếm sang nhịp nhấp nháy,            │
  │                       và ghi đè bảng giải mã đầu ra                 │
  │                          │                                          │
  │                          └─▶ TẦNG 4 — tick (pc == PHASE_TICKS-1):   │
  │                                  cho phép FSM tiến một pha          │
  └─────────────────────────────────────────────────────────────────────┘
```

Thứ tự lồng nhau này đọc trực tiếp từ cấu trúc `if/else if` của `always_ff`
(`f01_traffic_fsm.sv:48–76`) — không phải suy diễn.

## 2. Bảng tín hiệu điều khiển và tác dụng

| Tín hiệu | Mức tích cực | Đóng băng cái gì | Ảnh hưởng đầu ra? | Cell thực hiện | Độ trễ tới hiệu lực |
|---|:-:|---|:-:|---|---|
| `rst_n` | **thấp** | Ép `state=NS_GREEN`, `pc=0`, `nc=0`, `night_phase=0` | Gián tiếp (qua trạng thái) | Vào chân của `_25_`, `_29_`, `_32_`, `_34_`, `_36_`, `_38_` | **1 chu kỳ** (đồng bộ) |
| `ena` | cao | **Tất cả 6 flip-flop** | Gián tiếp | `_23_`, `_24_`, `_30_`, `_33_`, `_35_`, `_37_` | 1 chu kỳ |
| `night_mode` | cao | **Chỉ `state`** (`pc` bị ép về 0, `nc` chuyển sang đếm nhịp nháy) | ✅ **TRỰC TIẾP, 0 chu kỳ** | `_23_`, `_24_`, `_32_`, `_40_`…`_45_` | **0 chu kỳ** cho đầu ra; 1 chu kỳ cho trạng thái |
| `tick` (nội bộ) | cao | — (cho phép tiến pha) | Gián tiếp | `_24_` `and4b_1` | 1 chu kỳ |

### Bảng ưu tiên đầy đủ (đọc từ `:48–76`)

| `rst_n` | `ena` | `night_mode` | `state` | `pc` | `nc` | `night_phase` |
|:-:|:-:|:-:|---|---|---|---|
| 0 | X | X | ← `NS_GREEN` | ← 0 | ← 0 | ← 0 |
| 1 | 0 | X | **giữ** | **giữ** | **giữ** | **giữ** |
| 1 | 1 | 1 | **giữ** | ← 0 | đếm, về 0 khi đủ | **lật** khi `nc` đủ |
| 1 | 1 | 0 | tiến khi `tick` | đếm | ← 0 | ← 0 |

> 🔎 Hàng thứ ba là chỗ tinh tế nhất: `night_mode` đóng băng `state` nhưng **không** đóng
> băng `nc` và `night_phase`. Hai cơ chế đóng băng (`ena` và `night_mode`) có **phạm vi
> khác nhau** — ca C-4 trong testbench (`f01_tb.sv:37–41`) tồn tại chính để kiểm điều này.

## 3. `ena` được hiện thực thế nào trong netlist

`dfxtp_1` **không có chân enable**. Vậy `ena` phải được đưa vào **logic next-state** của
từng thanh ghi. Trích netlist, thanh ghi `nc`:

```verilog
sky130_fd_sc_hd__nand2_1 _30_ (.A(nc),   .B(ena), .Y(_14_));
sky130_fd_sc_hd__a21oi_1 _37_ (.A1(ena), .A2(night_mode), .B1(nc), .Y(_18_));
sky130_fd_sc_hd__nand2_1 _38_ (.A(rst_n),.B(_14_), .Y(_19_));
sky130_fd_sc_hd__nor2_1  _39_ (.A(_18_), .B(_19_), .Y(_05_));   // _05_ → nc.D
```

Giải mã từng bước:
- `_14_ = ~(nc & ena)`
- `_18_ = ~((ena & night_mode) | nc)` — theo hàm `a21oi`: `Y = !((A1&A2) | B1)`
- `_19_ = ~(rst_n & _14_) = ~rst_n | (nc & ena)`
- `_05_ = ~_18_ & ~_19_ = ((ena & night_mode) | nc) & rst_n & ~(nc & ena)`

Kiểm lại với RTL: khi `ena = 0` thì `_05_ = nc & rst_n & 1 = nc` — **giữ nguyên** ✅.
Khi `rst_n = 0` thì `_05_ = 0` — **xoá** ✅. Khi `ena=1, night_mode=1, nc=0` thì
`_05_ = 1 & 1 & 1 = 1` — **đếm lên** ✅. Khi `ena=1, night_mode=1, nc=1` thì
`_05_ = 1 & 1 & ~1 = 0` — **về 0** ✅. Khi `ena=1, night_mode=0` thì `_05_ = nc & ~nc = 0`
— **xoá `nc`** ✅.

> 🎓 **Bài học:** enable của một thanh ghi **không** miễn phí, dù RTL chỉ viết một dòng
> `else if (ena)`. Nó nhân số số hạng của mọi hàm next-state lên. Ở F01, chi phí đó nằm
> rải rác trong 26 cell tổ hợp, không tách riêng ra được — khác E07 nơi enable gom gọn
> vào đúng 8 `mux2i_1`.

## 4. Vì sao `night_mode` vừa là điều khiển vừa là đường tới hạn

`night_mode` có **fanout 9** — cao nhất thiết kế — vì nó phải vào cả bốn khối con:

| Đích | Tác dụng |
|---|---|
| `_23_` `nand2b_1` | Kết hợp với `ena` để tạo tín hiệu "đang bình thường và bật" |
| `_24_` `and4b_1` | Chặn `tick`: `tick = ~night & pc[0] & pc[1] & ena` |
| `_32_` `and3_1` | Cho phép `night_phase` lật |
| `_40_`…`_45_` | **Ghi đè bảng giải mã đầu ra** — đây là đường tới hạn |

Đường cuối cùng là đường tổ hợp **thuần** từ cổng vào tới cổng ra, không qua thanh ghi
nào. STA đo: `night_mode → _42_ (a22o_1) → uo_out[1]`, arrival 1,18 ns, slack 7,82 ns.

**Hệ quả kiến trúc:** chính vì `night_mode` đi thẳng ra đầu ra mà F01 mang hành vi
**Mealy** chứ không thuần Moore — phân tích đầy đủ ở `fsm.md` §4.

## 5. Quan hệ điều khiển ↔ datapath

```
   ĐIỀU KHIỂN                          DATAPATH (đếm thời gian)
   ──────────                          ────────────────────────
   state[1:0] ◀──────── tick ───────── pc[1:0] + bộ so sánh
       │                                    ▲
       │  (không có đường ngược)            │
       └──────── state != next ─────────────┘
                 xoá pc khi đổi pha

   night_mode ────────────────────────▶ ép pc ← 0
                                       ▶ cho nc đếm
   ena        ────────────────────────▶ đóng băng cả hai
```

Giao diện hai chiều chỉ gồm **hai dây**: `tick` (datapath → điều khiển) và tín hiệu xoá
`pc` khi đổi pha (điều khiển → datapath). Đây là đặc trưng của một FSMD được tách tốt:
giao diện hẹp, mỗi bên kiểm tra được độc lập.

## 6. Nghĩa vụ hợp đồng của tầng ngoài

| # | Nghĩa vụ | Vì sao F01 không tự làm được |
|---|---|---|
| N-1 | Phát `rst_n = 0` ≥ 1 chu kỳ sau bật nguồn | Reset **đồng bộ** cần ít nhất một cạnh `clk` hợp lệ |
| N-2 | Cấp `clk` đã chia tần đúng nhịp tick | F01 chỉ đếm chu kỳ, không biết một giây dài bao nhiêu |
| N-3 | Đồng bộ `night_mode` từ cảm biến ánh sáng | Không có synchronizer 2-flop trong khối |
| N-4 | Giữ `ena = 1` khi vận hành | Không có watchdog phát hiện đóng băng |
| N-5 | **Không suy ra "đang ở chế độ đêm" từ `uo_out[7:6]`** | Mã trạng thái hiện **pha bị giữ**, không có bit riêng báo chế độ đêm |
| N-6 | Mạch lái công suất phải có khoá cứng chống hai xanh | Phòng thủ lớp hai — F01 hỏng thì không ai chặn |
| N-7 | Quyết định thời lượng pha bằng cách đặt `PHASE_TICKS` **trước khi tổng hợp** | Tham số là `localparam` lúc biên dịch, **không** đổi được lúc chạy |

## 7. Những tín hiệu điều khiển F01 **không** có — và vì sao

| Tín hiệu thường gặp | Vì sao không có |
|---|---|
| `start` / `done` | F01 chạy vòng vô hạn, không có "giao dịch" bắt đầu và kết thúc |
| `busy` / `ready` | Không có bên nào phải đợi F01 |
| `error` / `fault` | Không có đường phản hồi từ đèn về; phát hiện đèn cháy nằm ngoài phạm vi |
| `night_active` (báo đang ở chế độ đêm) | **Thiếu thật.** Tầng ngoài phải tự nhớ giá trị `night_mode` mình phát ra (N-5). Đây là một đề xuất cải tiến rẻ: 0 flip-flop, chỉ cần nối `night_mode` ra một chân dư |
| Tín hiệu chọn thời lượng pha lúc chạy | `PHASE_TICKS` là tham số biên dịch. Muốn đổi lúc chạy phải thêm thanh ghi cấu hình — nằm ngoài phạm vi |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
