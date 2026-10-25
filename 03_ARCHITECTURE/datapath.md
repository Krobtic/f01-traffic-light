# F01 · Đường dữ liệu (Datapath)

---

## 1. F01 có datapath không?

**Có, nhưng datapath của F01 không mang dữ liệu người dùng — nó mang *thời gian*.**

Đây là điểm dễ nhầm. Trong một bộ cộng, datapath mang toán hạng. Trong F01, không có toán
hạng nào: chỉ có 2 bit vào (`ena`, `night_mode`) và không bit nào là dữ liệu. Thứ chảy
trong datapath của F01 là **hai bộ đếm** biến số chu kỳ clock thành thời lượng pha.

```
   ┌───────────────── DATAPATH (đếm thời gian) ─────────────────┐
   │                                                            │
   │   pc[1:0] ──▶ [+1] ──▶ [so sánh == PHASE_TICKS-1] ──▶ tick │
   │      ▲                                    │               │
   │      └────────── [về 0 khi tick] ◀────────┘               │
   │                                                            │
   │   nc ──▶ [+1] ──▶ [so sánh == NIGHT_TICKS-1] ──▶ lật       │
   │    ▲                              │              night_phase│
   │    └────── [về 0 khi lật] ◀───────┘                        │
   └────────────────────────┬───────────────────────────────────┘
                            │ tick (1 bit)
                            ▼
   ┌───────────────── ĐIỀU KHIỂN (FSM 4 pha) ──────────────────┐
   │   state[1:0] ──▶ [bảng chuyển] ──▶ next_state             │
   └────────────────────────┬──────────────────────────────────┘
                            │ state[1:0] + night_phase
                            ▼
   ┌───────────────── GIẢI MÃ ĐẦU RA ──────────────────────────┐
   │   6 cell tổ hợp ──▶ uo_out[5:0]                           │
   └───────────────────────────────────────────────────────────┘
```

Giao diện giữa datapath và điều khiển chỉ có **một bit**: `tick`. Đây là kiến trúc **FSMD
tối giản** — mẫu chuẩn của mọi bộ điều khiển có định thời.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `pc[1:0]` | 2 | 2 × `dfxtp_1` (`_49_`, `_50_`) | logic tăng + so sánh | **Đếm thời lượng pha** |
| `tick` (nội bộ `_10_`) | 1 | `_24_` `and4b_1` | logic next-state của FSM | **Điểm nối datapath → điều khiển** |
| `nc` | 1 | `dfxtp_1` `_51_` | logic lật `night_phase` | **Đếm nhịp nhấp nháy** |
| `night_phase` | 1 | `dfxtp_1` `_48_` | bảng giải mã đầu ra | Nửa sáng / nửa tối của đèn đêm |
| `state[1:0]` | 2 | `dfxtp_1` `_46_`,`_47_` — **chính là** `uo_out[7:6]` | bảng giải mã + logic next-state | **Trạng thái điều khiển** (không phải dữ liệu) |
| `night_mode` | 1 | cổng vào (fanout **9**) | cả ba khối | Điều khiển; **nằm trên đường tới hạn** |
| `ena` | 1 | cổng vào | enable của cả 6 flip-flop | Điều khiển toàn cục |
| `uo_out[5:0]` | 6 | 6 cell tổ hợp | cổng ra | Tín hiệu đèn |
| `uo_out[7:6]` | 2 | **trực tiếp** từ flip-flop trạng thái | cổng ra | Mã trạng thái, **0 cell phụ** |

## 3. Cơ chế bộ đếm pha — đọc kỹ vì có một chỗ dư thừa

`f01_traffic_fsm.sv:68–73`:

```systemverilog
if (state != next_state)
    phase_cnt <= '0;
else if (phase_cnt == PHASE_TICKS-1)
    phase_cnt <= '0;
else
    phase_cnt <= phase_cnt + 1'b1;
```

Ba nhánh, nhưng **hai nhánh đầu là cùng một điều kiện**. Lý do: trong nhánh `night_mode =
0`, `state != next_state` xảy ra **khi và chỉ khi** `phase_cnt == PHASE_TICKS-1` (đọc lại
`case` ở `:33–44`: mỗi trạng thái chỉ đổi khi đếm đủ). Vậy nhánh 1 và nhánh 2 luôn cùng
đúng hoặc cùng sai.

**Hệ quả:** mã dư thừa về mặt logic, nhưng **không** tốn thêm cell — Yosys hợp nhất chúng.
Bằng chứng: bản `_explicit` viết gọn thành một biểu thức

```systemverilog
pc <= (state!=next || pc==PHASE_TICKS-1) ? '0 : pc+1'b1;   // :46
```

và cho **cùng** kết quả tổng hợp (32 cell, 279,0176 µm²).

**Vì sao vẫn nên viết ba nhánh?** Vì nó thể hiện **hai ý định khác nhau**: "xoá đếm khi
đổi pha" và "xoá đếm khi tràn". Nếu sau này có người thêm một đường chuyển pha sớm (ví dụ
nút ưu tiên xe cứu hoả), nhánh 1 vẫn đúng còn cách viết gộp sẽ sai. Đây là mã **phòng thủ
cho tương lai**, không phải mã thừa vô nghĩa.

## 4. Đồ thị phụ thuộc và độ sâu logic

Đọc từ netlist. `s1 = uo_out[7]`, `s0 = uo_out[6]`.

```
 mức 0   night_mode   ena   rst_n   pc[1]   pc[0]   nc   night_phase   s1   s0
            │          │      │       │       │      │        │        │    │
 ── ĐƯỜNG TỚI FLIP-FLOP (in→reg và reg→reg) ─────────────────────────────────
            │          │              │       │
 mức 1   _23_ nand2b   │           _20_inv  _22_and2
         (night&ena)   │              │       │
            │          │              └───┬───┘
 mức 2   _24_ and4b_1 ◀──────────────────┘   ← tick = ~night & pc[0] & pc[1] & ena
            │
 mức 3   _25_ o21ai_0 ──┐          _33_ mux2i ──▶ _34_ and2 ──▶ pc[0].D
         _27_ a21o_1    │          _35_ o22ai ──▶ _36_ o211a ──▶ pc[1].D
         _28_ nand3     │          _30_ nand2 ──▶ _31_ xnor2 ──▶ _32_ and3 ──▶ night_phase.D
            │           │          _37_ a21oi ──┬─▶ _39_ nor2 ──▶ nc.D
 mức 4   _26_ a21oi_1 ──┴──▶ s0.D  _38_ nand2 ──┘
         _29_ a21boi_0 ─────▶ s1.D

 ── ĐƯỜNG TỚI CỔNG RA (reg→out và in→out) ───────────────────────────────────
 mức 0'  s1  s0  night_mode  night_phase
            │
 mức 1'  _40_ nor2 ──▶ uo_out[5]      _41_ nor3 ──▶ uo_out[0]
         _43_ nor2 ──▶ uo_out[2]      _44_ nor3 ──▶ uo_out[3]
            │
 mức 2'  _42_ a22o_1 ──▶ uo_out[1]    _45_ a22o_1 ──▶ uo_out[4]
         (dùng lại uo_out[5])         (dùng lại uo_out[2])
```

| Đầu ra | Độ sâu tính từ nguồn gần nhất |
|---|---|
| `uo_out[7:6]` (mã trạng thái) | **0 cell** — nối thẳng từ flip-flop |
| `uo_out[0]`, `[2]`, `[3]`, `[5]` | **1 cell** |
| `uo_out[1]`, `[4]` | **2 cell** *(nhưng từ `night_mode` chỉ 1 cell — xem §5)* |
| `state[1:0]` next-state | **3–4 cell** kể từ `pc`/`ena` (STA đo đường `ena → _24_ → _27_ → _29_ → s1.D` là 3 cell) |
| `pc[1]` next-state | 3 cell |
| `nc` next-state | 3 cell |

## 5. Dự đoán đường tới hạn từ RTL — rồi đối chiếu STA thật

### Dự đoán trước khi xem STA

Từ đồ thị §4, đường **dài nhất về số cell** là đường reg→reg của FSM: `pc → _22_ → _24_ →
_27_/_28_ → _29_ → s1.D`, sâu **4 cell**. Dự đoán tự nhiên: đó là đường tới hạn.

### Kết quả STA thật

`06_GDSII/sta/summary.txt`:

```
Startpoint                           Endpoint                               Slack
night_mode (input)                   uo_out[1] (output)                      7.82
```

Đường tới hạn thật: **`night_mode` → `_42_` (`a22o_1`) → `uo_out[1]`** — chỉ **1 cell**,
arrival **1,18 ns**, slack **7,82 ns**.

### Vì sao dự đoán sai — ba nguyên nhân cộng lại

| # | Nguyên nhân | Số chứng minh |
|---|---|---|
| 1 | **`input_delay` 1,0 ns trong SDC** áp lên mọi cổng vào. Đường bắt đầu từ `night_mode` đã "nợ" 1,00 ns trước khi chạm cell đầu tiên | `design.sdc`: `set_input_delay 1.0 -clock clk [all_inputs]` |
| 2 | **`output_delay` 1,0 ns** làm `required time` của cổng ra chỉ còn **9,00 ns**, trong khi endpoint là flip-flop được tới **9,92 ns** (10,00 − setup 0,08) ⇒ đường ra bị chấm khắt khe hơn 0,92 ns | `timing_report_max.txt`, so sánh khối "data required time" của hai loại đường |
| 3 | **Logic next-state của FSM vẫn rất nhanh.** Đường `ena → _24_ → _27_ → _29_ → _47_/D` đi qua **3 cell**, arrival chỉ **1,49 ns** (slack 8,43 ns) — nhanh hơn ngưỡng của đường ra | `timing_report_max.txt`, đường xếp hạng 7 |

> ❗ **Phát hiện cần nói thẳng:** đường tới hạn của F01 do **ràng buộc IO giả định** quyết
> định, không do độ sâu logic. Nếu `input_delay`/`output_delay` đổi, thứ hạng đường tới
> hạn sẽ đổi mà **không sửa một dòng RTL nào**. Mọi phát biểu kiểu "FSM này bị giới hạn
> bởi logic giải mã đầu ra" phải kèm câu "dưới giả định IO delay 1,0 ns".

### Chi tiết đường tới hạn (`timing_report_max.txt`)

```
 1,00 ns   input external delay                 ← GIẢ ĐỊNH SDC
 1,00 ns   night_mode (in), fanout = 9
 1,00 ns   _42_/A2  (sky130_fd_sc_hd__a22o_1)
 1,18 ns   _42_/X   ← trễ qua cell: 0,18 ns
 1,18 ns   uo_out[1] (out)                      data arrival
 9,00 ns   data required  (10,00 − output_delay 1,00)
 7,82 ns   SLACK (MET)
```

Cell tới hạn là `_42_` — chính là cell trộn lớp phủ đêm vào đèn vàng hướng 1:
`uo_out[1] = (night_phase & night_mode) | (uo_out[5] & uo_out[6])`.

## 6. Đường hold — nơi rủi ro thật sự nằm

`06_GDSII/sta/timing_report_min.txt`, đường ngắn nhất:

```
  cạnh clk tại t = 0
      ├── t_ckq của dfxtp_1 (_51_, thanh ghi nc) ──▶ 0,30 ns
      ├── _37_ (a21oi_1) ─────────────────────────▶ 0,34 ns
      ├── _39_ (nor2_1) ──────────────────────────▶ 0,41 ns
      └── _51_/D  (chính nó)                        0,41 ns  data arrival
          library hold time = −0,04 ns
          ⇒ hold slack = 0,45 ns  ✅ MET
```

Đây là vòng hồi tiếp **tự lặp** của bộ đếm `nc` — chỉ 2 cell. Biên 0,45 ns hiện đủ, nhưng
con số này **chưa trừ clock skew thật** (CTS ⬜ chưa chạy). Với một mạch an toàn như đèn
giao thông, vi phạm hold là lỗi **không sửa được bằng cách hạ tần số** — khác hẳn vi phạm
setup. Đây là rủi ro cần theo dõi sát nhất khi chạy tiếp physical design.

## 7. Fanout đáng chú ý

| Tín hiệu | Fanout | Nguồn | Ghi chú |
|---|---:|---|---|
| `night_mode` | **9** | `timing_report_max.txt` dòng đầu | Cao nhất thiết kế. Nó vào cả ① ② ③ ④ — đúng bản chất "lớp phủ toàn cục" |
| `ena` | — (xuất hiện ở 4 cell) | netlist | Enable của cả 6 flip-flop |
| `uo_out[6]` (= `state[0]`) | — | netlist | Vừa là cổng ra, vừa là đầu vào của `_25_`…`_28_`, `_41_`, `_42_`, `_44_`, `_45_` |

Fanout 9 trên `night_mode` là điểm cần chú ý sau P&R: sau routing, tải điện dung của net
này sẽ tăng nhiều nhất, và nó **đã** là startpoint của đường tới hạn. Nếu slack tụt sau
routing, đây là chỗ cần buffer đầu tiên.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
