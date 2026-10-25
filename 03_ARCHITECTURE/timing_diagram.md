# F01 · Giản đồ thời gian (Timing Diagram)

---

## 1. Thông số của giản đồ — lấy từ testbench thật

`05_VERIFICATION/testbench/f01_tb.sv:10` — `always #5 clk=~clk;` ⇒ chu kỳ **10 đơn vị**,
cạnh lên tại `t = 5, 15, 25, …`. `$finish` tại `t = 256` (`simulation.log`).

> ⚠️ **Giản đồ này ứng với `PHASE_TICKS = 2`** (giá trị testbench truyền vào,
> `f01_tb.sv:5`). Cấu hình **được tổng hợp** là `PHASE_TICKS = 4` — mỗi pha dài gấp đôi,
> một vòng đủ là 16 chu kỳ thay vì 8. Xem `functional_spec.md` §0 (W-3).

Mô phỏng là **hành vi, zero-delay**: giản đồ đúng về **thứ tự và số chu kỳ**, không minh
hoạ độ trễ thật. Độ trễ thật ở §4.

## 2. Giản đồ dạng sóng — toàn bộ giao dịch đúng như testbench chạy

Ký hiệu đèn: `G`=xanh `Y`=vàng `R`=đỏ `-`=tắt

Giá trị các thanh ghi và `uo_out` ghi **sau** cạnh lên của chu kỳ đó; giá trị `ena` /
`night_mode` là giá trị **tại** cạnh đó.

```
 chu kỳ  │R1│R2│ 1│ 2│ 3│ 4│ 5│ 6│ 7│ 8│ 9│10│11│12│13│14│15│16│17│18│19│20│21│22│23│24│
 t (đv)  │ 5│15│25│35│45│55│65│75│85│95│105│115│125│135│145│155│165│175│185│195│205│215│225│235│245│255│
 ────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
 rst_n   │0 │0 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │
 ena     │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │1 │0 │0 │1 │1 │1 │1 │1 │1 │
 night_md│0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │1 │1 │1 │1 │1 │1 │0 │0 │0 │0 │0 │0 │
 ────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
 state   │NG│NG│NG│NY│NY│EG│EG│EY│EY│NG│NG│NY│NY│EG│EG│EG│EG│EG│EG│EG│EG│EY│EY│NG│NG│NY│
 pc      │0 │0 │1 │0 │1 │0 │1 │0 │1 │0 │1 │0 │1 │0 │0 │0 │0 │0 │0 │0 │1 │0 │1 │0 │1 │0 │
 nc      │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │1 │0 │1 │0 │0 │0 │0 │0 │0 │0 │0 │0 │
 nite_ph │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │0 │1 │1 │0 │0 │0 │0 │0 │0 │0 │0 │0 │
 ────────┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
 H1 đèn  │R │R │G │Y │Y │R │R │R │R │G │G │Y │Y │R │- │Y │Y │- │- │- │R │R │R │G │G │Y │
 H2 đèn  │R │R │R │R │R │G │G │Y │Y │R │R │R │R │G │- │Y │Y │- │- │- │G │Y │Y │R │R │R │
 uo_out  │21│21│21│62│62│8C│8C│D4│D4│21│21│62│62│8C│80│92│92│80│80│80│8C│D4│D4│21│21│62│
 ────────┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
          ◀reset▶◀──────── repeat(12): MỘT VÒNG RƯỠI ─────────▶◀ đêm ▶◀ena=0▶◀ trở lại ▶
                                                              (ck 13–16)(17–18) (19–24)
 both_green? ❌ KHÔNG BAO GIỜ — assert chạy sau MỖI cạnh (f01_tb.sv:24, 32, 40, 47)
```

*(`80` = `0b10_000_000`: state `EW_GREEN` ở `[7:6]`, cả 6 bit đèn tắt.
`92` = `0b10_010_010`: state `EW_GREEN`, cả hai hướng vàng.)*

Ba thời điểm đầu vào đổi **giữa** hai cạnh clock, và `uo_out` đổi **ngay lúc đó**:

| Thời điểm | Sự kiện | `uo_out` trước → sau |
|---|---|---|
| `t = 136` | `night_mode: 0 → 1` | `8C` → **`80`** (đèn tắt, state vẫn `EW_GREEN`) |
| `t = 176` | `ena: 1 → 0` | `80` → `80` (không đổi — `ena` không vào bảng giải mã) |
| `t = 196` | `night_mode: 1 → 0` | `80` → **`8C`** (trở lại đèn pha `EW_GREEN`) |

### Ba đoạn đáng đọc kỹ

**① Chu kỳ 1–12 — một vòng rưỡi, phủ đủ 4 trạng thái và 4 cạnh chuyển**

```
   NS_GREEN ──▶ NS_YELLOW ──▶ EW_GREEN ──▶ EW_YELLOW ──▶ NS_GREEN ──▶ NS_YELLOW ──▶ EW_GREEN
     (2ck)        (2ck)        (2ck)         (2ck)         (2ck)        (2ck)
```
Mỗi pha đúng `PHASE_TICKS = 2` chu kỳ. Cạnh **khép vòng** `EW_YELLOW → NS_GREEN` xảy ra ở
chu kỳ 9 — nếu testbench chỉ chạy 8 chu kỳ thì cạnh này **không** được thử.

**② Chu kỳ 13–16 — vào chế độ đêm giữa chừng**

`night_mode` lên 1 tại `t = 136`, đúng lúc FSM vừa vào `EW_GREEN` ở chu kỳ 12. Quan sát:

- `state` **đóng băng** ở `EW_GREEN` suốt cả đoạn đêm ⇒ INV-6 ✅
- `pc` bị ép về 0 ngay chu kỳ đầu của đêm
- `night_phase` lật theo nhịp `NIGHT_TICKS = 2`: chu kỳ tối → sáng → sáng → tối
- `uo_out[7:6]` **vẫn hiện `10`** (`EW_GREEN`) dù đèn đang nhấp nháy vàng — **không có bit
  nào báo "đang ở chế độ đêm"**. Đây là hạn chế thiết kế đã ghi ở `control.md` §7.

**③ Chu kỳ 17–18 — `ena = 0` giữa chế độ đêm**

Mọi thanh ghi đóng băng, kể cả `nc` và `night_phase`. Đèn **đứng yên** ở trạng thái tối
(`night_phase = 0`) thay vì tiếp tục nhấp nháy. Ca này (`f01_tb.sv:37–41`) tồn tại để
kiểm rằng hai cơ chế đóng băng có phạm vi khác nhau.

**④ Chu kỳ 19 trở đi — thoát chế độ đêm**

FSM tiếp tục **từ `EW_GREEN`**, không bị reset về `NS_GREEN`. Đây là bằng chứng mô phỏng
cho INV-6.

## 3. Đặc trưng Mealy hiện ra trong giản đồ ở đâu?

Ở **biên** giữa chu kỳ 12 và 13. `night_mode` lên 1 tại `t = 136` — **giữa** hai cạnh
clock (cạnh tại 135 và 145). Trong mô phỏng zero-delay, `uo_out` đổi từ `8C` sang `80`
**ngay tại t = 136**, không đợi cạnh clock.

```
   t = 135 ↑clk        t = 136             t = 145 ↑clk
      │                   │                    │
      │  night_mode: 0 ───█──▶ 1               │
      │                   │                    │
   uo_out = 8C ───────────█──▶ 80              │  (state vẫn EW_GREEN)
                          ▲
                          └── ĐỔI KHÔNG CẦN CLOCK = đặc trưng Mealy
```

Một máy Moore thuần sẽ giữ `8C` cho tới cạnh `t = 145`. Đây là minh hoạ trực quan cho
phân tích ở `fsm.md` §4.

## 4. Giản đồ lan truyền thật — từ STA, không phải từ mô phỏng

Số lấy từ `06_GDSII/sta/timing_report_max.txt` và `timing_report_min.txt` (cấu hình
tổng hợp: `PHASE_TICKS = 4`).

### 4.1 Đường tới hạn — `night_mode` → `uo_out[1]`

```
  t (ns)   0                  1,00         1,18                       9,00
           │                   │            │                          │
  clk ▲────┤                   │            │                          │
  night_md ┼───────────────────█ đổi tại 1,00 ns (input_delay GIẢ ĐỊNH)
           │                   │╲ fanout = 9
           │                   │ ╲ _42_ (a22o_1) 0,18 ns
  uo_out[1]┼───────────────────┼──█ ổn định tại 1,18 ns
           │                   │  │◀──────── slack 7,82 ns ──────────▶│
           │                              required 9,00 (= 10,00 − out_delay 1,00)
           ◀── VÙNG GLITCH 1,00 → 1,18 ns ──▶
```

Trong vùng 1,00…1,18 ns, **sáu bit đèn chuyển không đồng thời** (bốn bit qua 1 cell, hai
bit qua 2 cell). Về lý thuyết, một tổ hợp bit không hợp lệ có thể xuất hiện thoáng qua.

> 🔴 **Đây là rủi ro an toàn duy nhất mà cả mô phỏng lẫn STA hiện tại đều KHÔNG loại trừ
> được.** Chứng minh cấu trúc ở `fsm.md` §6 bảo đảm `uo_out[0] · uo_out[3] = 0` **ở trạng
> thái ổn định**, nhưng trong vùng quá độ, nếu `uo_out[7]` tới hai cell `_41_`/`_44_` lệch
> nhau (skew đường dây sau routing), glitch "hai xanh" về nguyên tắc có thể xảy ra trong
> vài chục ps. Cần mô phỏng L5 + SDF để loại trừ. Ghi nhận ở `corner_cases.md` §7.

### 4.2 Đường vào → thanh ghi trạng thái

```
  t (ns)   0      1,00      1,21      1,38     1,49              9,92   10,00
           │       │         │         │        │                  │      │
  ena ─────┼───────█ 1,00 ns
           │       │╲ _24_ (and4b_1) 0,21 ns
           │       │ █─────┐
           │       │       │╲ _27_ (a21o_1) 0,17 ns
           │       │       │ █─────┐
           │       │       │       │╲ _29_ (a21boi_0) 0,12 ns
  _47_/D   ┼───────┼───────┼───────┼─█ 1,49 ns
           │                         │◀──── slack 8,43 ns ─────────▶│
           │                              required 9,92 = 10,00 − setup 0,08
```

Ba cell tổ hợp — đây là logic next-state của FSM. Nó **nhanh hơn** đường ra ở §4.1 xét
theo slack, mặc dù đi qua nhiều cell hơn. Nguyên nhân: `required time` của endpoint
flip-flop là 9,92 ns, còn của cổng ra chỉ 9,00 ns (`datapath.md` §5).

### 4.3 Đường hold — vòng hồi tiếp của `nc`

```
  cạnh clk tại t = 0
      ├── t_ckq của _51_ (dfxtp_1) ────▶ 0,30 ns
      ├── _37_ (a21oi_1) ──────────────▶ 0,34 ns
      ├── _39_ (nor2_1) ───────────────▶ 0,41 ns
      └── _51_/D (chính nó)              0,41 ns
          library hold = −0,04 ns
          ⇒ hold slack = 0,45 ns  ✅ MET
```

Đường ngắn nhất thiết kế, chỉ 2 cell. **Chưa trừ clock skew thật** — CTS ⬜ chưa chạy.

## 5. Bảng tổng hợp mười đường xấu nhất

| Hạng | Startpoint | Endpoint | Loại đường | Slack (ns) |
|---:|---|---|---|---:|
| 1 | `night_mode` | `uo_out[1]` | in → out | **7,82** |
| 2 | `night_mode` | `uo_out[4]` | in → out | 7,82 |
| 3–6 | `night_mode` | `uo_out[2]`, `[5]`, `[0]`, `[3]` | in → out | 7,94 |
| 7 | `ena` | `_47_` (`state[1]`) | in → reg | 8,43 |
| 8 | `ena` | `_46_` (`state[0]`) | in → reg | 8,48 |
| 9 | `ena` | `_48_` (`night_phase`) | in → reg | 8,55 |
| 10 | `night_mode` | `_50_` (`pc[1]`) | in → reg | 8,56 |

**Không một đường `reg → reg` nào lọt vào top 10.** Với FSM chỉ 4 trạng thái và bộ đếm
2 bit, logic hồi tiếp rất nông — đúng như mong đợi.

## 6. Ba giới hạn phải nói rõ

| # | Giới hạn | Hệ quả |
|---|---|---|
| L-1 | §2 là mô phỏng **zero-delay**, và với `PHASE_TICKS = 2` | Không có glitch; và **không phải** cấu hình được tổng hợp |
| L-2 | §4 là **sau tổng hợp**, chưa có ký sinh dây (RC) | Các số 0,18 / 0,21 / 0,12 ns sẽ **tăng** sau routing; net `night_mode` fanout 9 tăng nhiều nhất |
| L-3 | Chu kỳ 10 ns là **giả định SDC** | Không được suy ra "F01 chạy 100 MHz". Với ứng dụng đèn giao thông, tần số thật thấp hơn hàng nghìn lần — biên timing không phải vấn đề của đề này |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
