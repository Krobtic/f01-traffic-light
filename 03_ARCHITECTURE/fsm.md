# F01 · Máy trạng thái (FSM)

---

## 1. Mã hoá trạng thái — đọc từ RTL

`f01_traffic_fsm.sv:14–19` (bản `_explicit` dùng tên viết tắt nhưng **cùng mã**):

```systemverilog
typedef enum logic [1:0] {
    NS_GREEN  = 2'd0,
    NS_YELLOW = 2'd1,
    EW_GREEN  = 2'd2,
    EW_YELLOW = 2'd3
} state_t;
```

| Trạng thái | Mã nhị phân | Hiện ra `uo_out[7:6]` | Ý nghĩa giao thông |
|---|:-:|:-:|---|
| `NS_GREEN` | `2'b00` | `00` | Hướng 1 xanh, hướng 2 đỏ |
| `NS_YELLOW` | `2'b01` | `01` | Hướng 1 vàng (chuẩn bị dừng), hướng 2 vẫn đỏ |
| `EW_GREEN` | `2'b10` | `10` | Hướng 2 xanh, hướng 1 đỏ |
| `EW_YELLOW` | `2'b11` | `11` | Hướng 2 vàng, hướng 1 vẫn đỏ |

**Kiểu mã hoá: nhị phân tuần tự (sequential binary), do người viết chỉ định tường minh.**

Đặc điểm quan trọng: **4 trạng thái trên 2 bit ⇒ dùng hết 4/4 mã, không còn mã thừa.**
Hệ quả trực tiếp là F01 **không thể** rơi vào trạng thái bất hợp lệ (§7).

Mã được chọn có một tính chất hữu ích: **bit cao `state[1]` chính là "hướng nào đang được
ưu tiên"** (`0` = hướng 1, `1` = hướng 2) và **bit thấp `state[0]` chính là "đang vàng hay
không"** (`0` = xanh, `1` = vàng). Chính nhờ tính chất này mà bảng giải mã đầu ra rút gọn
được xuống 6 cell (§6). Nếu gán mã ngẫu nhiên, logic sẽ phức tạp hơn.

## 2. Sơ đồ trạng thái ASCII đầy đủ

Ký hiệu: `T` = `tick` = `(pc == PHASE_TICKS-1)` · `N` = `night_mode` · `E` = `ena`

```
                              ┌──────────────────────────┐
                              │  rst_n = 0  (ĐỒNG BỘ)    │
                              │  từ MỌI trạng thái       │
                              └────────────┬─────────────┘
                                           │
                                           ▼
        ┌──────────────────────────────────────────────────────────────┐
        │                                                              │
        │   ╔══════════════════╗      E·¬N·T       ╔══════════════════╗│
        │   ║   NS_GREEN       ║ ─────────────────▶║   NS_YELLOW      ║│
        │   ║   mã = 2'b00     ║                   ║   mã = 2'b01     ║│
   ┌───▶│   ║                  ║                   ║                  ║│
   │    │   ║ H1: 🟢 (001)     ║                   ║ H1: 🟡 (010)     ║│
   │    │   ║ H2: 🔴 (100)     ║                   ║ H2: 🔴 (100)     ║│
   │    │   ║ uo_out = 0x21    ║                   ║ uo_out = 0x62    ║│
   │    │   ╚═════════╤════════╝                   ╚═════════╤════════╝│
   │    │         ▲   │                                  ▲   │         │
   │    │         └───┘ ¬E ∨ N ∨ ¬T                      └───┘ ¬E ∨ N ∨ ¬T
   │    │        (tự lặp: giữ pha)                      (tự lặp)       │
   │    │                                                     │        │
   │    │                                                     │E·¬N·T  │
   │    │                                                     ▼        │
   │    │   ╔══════════════════╗      E·¬N·T       ╔══════════════════╗│
   │    │   ║   EW_YELLOW      ║ ◀─────────────────║   EW_GREEN       ║│
   │    │   ║   mã = 2'b11     ║                   ║   mã = 2'b10     ║│
   │    │   ║                  ║                   ║                  ║│
   │    │   ║ H1: 🔴 (100)     ║                   ║ H1: 🔴 (100)     ║│
   │    │   ║ H2: 🟡 (010)     ║                   ║ H2: 🟢 (001)     ║│
   │    │   ║ uo_out = 0xD4    ║                   ║ uo_out = 0x8C    ║│
   │    │   ╚═════════╤════════╝                   ╚═════════╤════════╝│
   │    │         ▲   │                                  ▲   │         │
   │    │         └───┘ ¬E ∨ N ∨ ¬T                      └───┘ ¬E ∨ N ∨ ¬T
   │    │             │                                                │
   └────┼─────────────┘  E·¬N·T   (cạnh KHÉP VÒNG — hay viết sai nhất) │
        │                                                              │
        └──────────────────────────────────────────────────────────────┘

   ═══════════════ LỚP PHỦ CHẾ ĐỘ ĐÊM (KHÔNG phải trạng thái) ═══════════════

   Khi N = 1: state ĐÓNG BĂNG ở giá trị hiện tại (mọi cạnh chuyển bị chặn),
              nhưng đầu ra bị GHI ĐÈ bởi một bộ đếm riêng:

              ┌───────────────┐   nc == NIGHT_TICKS-1   ┌───────────────┐
              │ night_phase=0 │ ──────────────────────▶ │ night_phase=1 │
              │  H1: ⚫ (000) │                         │  H1: 🟡 (010) │
              │  H2: ⚫ (000) │ ◀────────────────────── │  H2: 🟡 (010) │
              └───────────────┘   nc == NIGHT_TICKS-1   └───────────────┘
                     ▲                                          ▲
                     └──── uo_out[7:6] VẪN hiện `state` cũ ─────┘
                           (không có bit nào báo "đang đêm")
```

## 3. Bảng chuyển trạng thái đầy đủ

`T = (pc == PHASE_TICKS-1)`. Bảng dưới đọc từ `f01_traffic_fsm.sv:26–76`.

### 3.1 Bảng chuyển `state`

| # | `rst_n` | `ena` | `night_mode` | `T` | Trạng thái hiện tại | Trạng thái kế | Dòng RTL |
|---:|:-:|:-:|:-:|:-:|---|---|---|
| 1 | **0** | X | X | X | bất kỳ | `NS_GREEN` | `:49–50` |
| 2 | 1 | **0** | X | X | bất kỳ | **giữ nguyên** | `:54` (không vào nhánh) |
| 3 | 1 | 1 | **1** | X | bất kỳ | **giữ nguyên** | `:29–31` `next_state = state` |
| 4 | 1 | 1 | 0 | **0** | bất kỳ | **giữ nguyên** | `:34–41` (điều kiện `if` sai) |
| 5 | 1 | 1 | 0 | **1** | `NS_GREEN` | `NS_YELLOW` | `:34–35` |
| 6 | 1 | 1 | 0 | **1** | `NS_YELLOW` | `EW_GREEN` | `:36–37` |
| 7 | 1 | 1 | 0 | **1** | `EW_GREEN` | `EW_YELLOW` | `:38–39` |
| 8 | 1 | 1 | 0 | **1** | `EW_YELLOW` | `NS_GREEN` | `:40–41` ← **cạnh khép vòng** |
| — | 1 | 1 | 0 | X | *(mã ngoài 0…3)* | `NS_GREEN` | `:42–43` `default` — **không tới được** |

**Tổng: 4 cạnh chuyển pha + 4 cạnh tự lặp = 8 cạnh.** Testbench phủ đủ **8/8**
(`corner_cases.md` §3).

### 3.2 Bảng chuyển các thanh ghi đồng hành

| `rst_n` | `ena` | `night_mode` | `pc` kế | `nc` kế | `night_phase` kế |
|:-:|:-:|:-:|---|---|---|
| 0 | X | X | `0` | `0` | `0` |
| 1 | 0 | X | giữ | giữ | giữ |
| 1 | 1 | 1 | **`0`** | `nc+1`, về `0` khi `nc = NIGHT_TICKS-1` | **lật** khi `nc = NIGHT_TICKS-1` |
| 1 | 1 | 0 | `0` nếu `T`, ngược lại `pc+1` | `0` | `0` |

### 3.3 Bảng đầu ra

| Điều kiện | `uo_out[2:0]` (H1) | `uo_out[5:3]` (H2) | `uo_out[7:6]` |
|---|---|---|---|
| `night_mode=0`, `state=NS_GREEN` | `001` 🟢 | `100` 🔴 | `00` |
| `night_mode=0`, `state=NS_YELLOW` | `010` 🟡 | `100` 🔴 | `01` |
| `night_mode=0`, `state=EW_GREEN` | `100` 🔴 | `001` 🟢 | `10` |
| `night_mode=0`, `state=EW_YELLOW` | `100` 🔴 | `010` 🟡 | `11` |
| `night_mode=1`, `night_phase=1` | `010` 🟡 | `010` 🟡 | `state` (pha bị giữ) |
| `night_mode=1`, `night_phase=0` | `000` ⚫ | `000` ⚫ | `state` (pha bị giữ) |

## 4. Mealy hay Moore? — kèm bằng chứng

**Kết luận: F01 là máy lai — thân FSM là Moore, nhưng đầu ra là Mealy.**

Câu trả lời "Moore" (câu hay gặp nhất) là **sai**, và có bằng chứng đo được để bác bỏ.

### Bằng chứng 1 — đọc RTL

```systemverilog
always_comb begin
    uo_out = '0;
    if (night_mode) begin          // ← night_mode là TÍN HIỆU VÀO
        if (night_phase) begin
            uo_out[2:0] = 3'b010;  // ← đầu ra phụ thuộc trực tiếp vào INPUT
```

`uo_out` là hàm của `(state, night_phase, night_mode)`. Trong đó `state` và `night_phase`
là thanh ghi (thuộc trạng thái mở rộng), nhưng `night_mode` là **cổng vào**. Theo định
nghĩa, đầu ra phụ thuộc cả trạng thái **và** đầu vào ⇒ **Mealy**.

### Bằng chứng 2 — netlist

```verilog
sky130_fd_sc_hd__a22o_1 _42_ (.A1(night_phase), .A2(night_mode),
                              .B1(uo_out[5]),   .B2(uo_out[6]), .X(uo_out[1]));
```

`night_mode` (cổng vào) nối **trực tiếp** vào chân `A2` của cell lái cổng ra `uo_out[1]`.
Không có flip-flop nào trên đường đó.

### Bằng chứng 3 — STA (mạnh nhất, vì là số đo)

`06_GDSII/sta/summary.txt`:

```
night_mode (input)   →   uo_out[1] (output)   slack 7.82
```

OpenSTA phân loại đây là đường **input → output**, không phải `reg → out`. Một máy Moore
thuần **không thể** có đường tổ hợp từ cổng vào tới cổng ra. Sáu trong mười đường xấu nhất
đều thuộc loại này (`night_mode → uo_out[0],[1],[2],[3],[4],[5]`).

### Phân tích từng bit đầu ra

| Bit | Phụ thuộc | Loại |
|---|---|:-:|
| `uo_out[7:6]` (mã trạng thái) | chỉ `state` | **Moore thuần** |
| `uo_out[0]`, `[2]`, `[3]`, `[5]` | `state`, `night_mode` | **Mealy** |
| `uo_out[1]`, `[4]` | `state`, `night_mode`, `night_phase` | **Mealy** |

### Vì sao điều này lại xảy ra — và nó có phải lỗi không?

**Không phải lỗi.** Tính Mealy đến từ **một quyết định kiến trúc có chủ ý**: hiện thực chế
độ đêm bằng **lớp phủ đầu ra** thay vì bằng hai trạng thái mới (`system_diagram.md` §4).
Lớp phủ tiết kiệm được flip-flop và loại bỏ mã trạng thái thừa, nhưng đổi lại nó kéo một
tín hiệu vào thẳng ra đầu ra.

| | Phương án Moore thuần (6 trạng thái) | Phương án lớp phủ (F01) |
|---|---|---|
| Số trạng thái | 6 | 4 |
| Bit mã hoá | 3 | 2 |
| Mã thừa | 2 (cần xử lý) | **0** |
| Nhớ pha khi vào đêm | cần thêm logic | **miễn phí** |
| Đường in→out tổ hợp | không có | **có** ⇒ Mealy |
| Rủi ro glitch trên đèn khi `night_mode` lật | thấp | **có** (xem `corner_cases.md` §7) |

**Hệ quả thực tế phải nói rõ:** vì là Mealy, một glitch trên `night_mode` sẽ **đi thẳng
ra đèn** mà không được chu kỳ clock lọc. Với một hệ thống an toàn, đây là điểm cần bảo vệ
ở tầng ngoài (`control.md` §6, N-3: phải đồng bộ `night_mode`).

## 5. Trả lời Charter mục 9 — số flip-flop so với ⌈log₂(số trạng thái)⌉

> *"Vẽ sơ đồ trạng thái và đối chiếu số flip-flop trong báo cáo với số bit tối thiểu cần
> để mã hoá số trạng thái của mình. Nếu công cụ dùng nhiều hơn, tìm hiểu về mã hoá one-hot
> và nêu vì sao công cụ chọn cách đó."*

### Tính toán

- Số trạng thái pha: **4**
- Số bit tối thiểu: **⌈log₂ 4⌉ = 2**

### Đối chiếu netlist thật

`06_GDSII/synthesis/synth_stat.txt`: **6 × `sky130_fd_sc_hd__dfxtp_1`**. Truy vết từng
flip-flop trong `netlist.v`:

| Cell | Chân `Q` | Thuộc về | Số bit |
|---|---|---|---:|
| `_46_` | `uo_out[6]` | **`state[0]`** | 1 |
| `_47_` | `uo_out[7]` | **`state[1]`** | 1 |
| `_49_` | `pc[0]` | bộ đếm pha | 1 |
| `_50_` | `pc[1]` | bộ đếm pha | 1 |
| `_51_` | `nc` | bộ đếm nhấp nháy | 1 |
| `_48_` | `night_phase` | bit pha nhấp nháy | 1 |
| | | **Tổng** | **6** |

### Kết luận

| Câu hỏi | Trả lời |
|---|---|
| Số bit tối thiểu cho 4 trạng thái | **2** |
| Số FF công cụ dùng cho trạng thái | **2** — ✅ **khớp chính xác** |
| Công cụ có đổi sang one-hot không? | ❌ **Không.** Vẫn là mã nhị phân người viết chỉ định |
| Tổng FF của cả khối | **6** = 2 (trạng thái) + 2 (`pc`) + 1 (`nc`) + 1 (`night_phase`) |

### Vì sao Yosys **không** chuyển sang one-hot — bằng chứng từ log

`06_GDSII/synthesis/synth.ys` có chạy pass `fsm`. `yosys.log:187–205` cho thấy đủ chuỗi:

```
6.1. Executing FSM_DETECT pass (finding FSMs in design).
6.2. Executing FSM_EXTRACT pass (extracting FSM from design).
...
6.6. Executing FSM_RECODE pass (re-assigning FSM state encoding).
```

Nhưng **không một dòng nào báo tìm thấy FSM** — `FSM_DETECT` in ra rỗng, và `FSM_RECODE`
không có gì để mã hoá lại.

**Nguyên nhân, đọc được từ netlist:** thanh ghi trạng thái được **nối thẳng ra cổng ra**
(`uo_out[7:6] = state;`). `fsm_detect` của Yosys chỉ nhận một thanh ghi là "trạng thái
FSM" khi thanh ghi đó chỉ được dùng trong các phép **so sánh bằng**. Ở đây `state` còn
được dùng làm **giá trị** đi ra chân, nên nó bị loại khỏi danh sách ứng viên FSM.

> 🎓 **Bài học rất đáng dạy:** *một quyết định ở tầng đặc tả (Charter mục 4 yêu cầu xuất
> mã trạng thái ra `uo_out[7:6]`) đã vô hiệu hoá một pass tối ưu của công cụ tổng hợp.*
> Ở đây kết quả là tốt (giữ 2 bit thay vì nhảy lên 4 bit one-hot), nhưng nguyên nhân
> **không** phải do Yosys "quyết định thông minh" — mà do Yosys **không nhận ra** đây là
> FSM. Trả lời Charter mục 9 mà nói "công cụ chọn nhị phân vì nhị phân tốt hơn" là **sai
> bản chất**.

Ngoài ra, ngay cả khi `fsm_detect` nhận ra, ngưỡng mặc định của Yosys là chuyển one-hot
với FSM **lớn**; với 4 trạng thái thì nhị phân vẫn thường thắng.

### Nếu công cụ đã chọn one-hot thì sao?

| | Nhị phân (thực tế) | One-hot (giả định) |
|---|---:|---:|
| FF cho trạng thái | 2 | 4 |
| Tổng FF | 6 | 8 |
| Diện tích FF | 40,0384 µm² | 80,0768 µm² |
| Logic next-state | phức hợp hơn | đơn giản hơn (mỗi bit là một OR nhỏ) |
| Mã thừa cần xử lý | 0 | **12** trong 16 mã 4 bit |

One-hot đánh đổi flip-flop lấy logic đơn giản và đường tới hạn ngắn. Với FSM 4 trạng thái
và đường tới hạn **vốn đã chỉ 1 cell**, one-hot ở đây sẽ **chỉ tốn thêm**, không lợi gì.

## 6. Chứng minh cấu trúc cho tính chất an toàn INV-1

> *Charter mục 2 câu 1: "Bằng chứng nào chứng minh KHÔNG BAO GIỜ có hai hướng cùng xanh —
> đây là yêu cầu an toàn, không phải yêu cầu chức năng?"*

Mô phỏng **không đủ** để trả lời câu này: nó chỉ phủ các chu kỳ đã chạy. Cần chứng minh
**cấu trúc**. Netlist cho phép làm điều đó trong hai dòng:

```verilog
sky130_fd_sc_hd__clkinv_1 _21_ (.A(uo_out[7]), .Y(_07_));           // _07_ = ~s1
sky130_fd_sc_hd__nor3_1 _41_ (.A(uo_out[7]), .B(uo_out[6]), .C(night_mode), .Y(uo_out[0]));
sky130_fd_sc_hd__nor3_1 _44_ (.A(_07_),      .B(uo_out[6]), .C(night_mode), .Y(uo_out[3]));
```

Hàm `nor3`: `Y = !A & !B & !C`. Vậy:

```
   uo_out[0]  =  ¬s1 · ¬s0 · ¬night      ← hướng 1 XANH
   uo_out[3]  =   s1 · ¬s0 · ¬night      ← hướng 2 XANH
   ────────────────────────────────────────────────────────
   uo_out[0] · uo_out[3]  =  ¬s1 · s1 · (…)  =  0      ∀ giá trị
```

**Hai cell được lái bởi CÙNG một dây `uo_out[7]`, một cell qua bộ đảo `_21_`, cell kia
không.** Không có gán giá trị nào cho `s1` khiến cả hai cùng bằng 1. Đây là chứng minh
**tổ hợp, vét cạn, độc lập với mô phỏng** — đúng mức độ chặt chẽ mà một yêu cầu an toàn
đòi hỏi.

Ba nhận xét bổ sung:

1. Tính chất này **không** phụ thuộc `night_mode`, `night_phase`, `pc`, `nc`, `ena` hay
   `rst_n`. Nó đúng kể cả khi các thanh ghi đó đang là `X`.
2. Nó **vẫn đúng** khi `s1` là `X`: `nor3` với đầu vào `X` cho `X` ở **cả hai** đầu ra,
   nên không bao giờ có "cả hai = 1" xác định.
3. Nó phụ thuộc vào việc **Yosys không sinh cell nào khác lái `uo_out[0]`/`uo_out[3]`** —
   điều này đúng với netlist hiện tại, nhưng **phải kiểm lại sau P&R** vì bước chèn buffer
   có thể thay đổi cấu trúc. Đây là lý do ca L4/L5 trong `corner_cases.md` §7 tồn tại.

> 🔴 **Chốt lại câu trả lời cho Charter mục 2 câu 1:** bằng chứng là **cấu trúc netlist**
> (`_41_` và `_44_` chia nhau `uo_out[7]` với hai cực tính đối nhau), **không phải** kết
> quả mô phỏng. Mô phỏng (`f01_tb.sv:24,32,40,47`) là bằng chứng bổ trợ, không phải bằng
> chứng chính.

## 7. Xử lý trạng thái bất hợp lệ

| Câu hỏi | Trả lời cho F01 |
|---|---|
| Có mã trạng thái bất hợp lệ không? | **Không.** 4 trạng thái trên 2 bit ⇒ dùng hết 4/4 mã |
| Nhánh `default` trong RTL có tác dụng gì? | **Không tới được.** Yosys xác nhận: `yosys.log:30, :33` — *"Removed 1 dead cases"* |
| Vậy có nên xoá `default` không? | **Không.** Giữ lại vì: (a) chặn suy diễn latch nếu sau này thêm trạng thái thứ 5; (b) `always_comb` không đủ điều kiện `full_case` sẽ sinh latch — `yosys.log:70–71` ghi *"No latch inferred"* chính là nhờ nhánh này |
| Nếu một flip-flop bị lật do nhiễu (SEU)? | FSM vẫn ở **một trong 4 trạng thái hợp lệ** — chỉ là sai pha. Đèn vẫn an toàn (INV-1 vẫn đúng theo §6), nhưng có thể nhảy từ `NS_GREEN` sang `EW_GREEN` **mà không qua vàng** ⇒ **vi phạm INV-5**. Đây là rủi ro an toàn thật, chưa được xử lý |
| Còn `pc` và `nc`? | `pc` rộng 2 bit, `PHASE_TICKS = 4` ⇒ dùng hết 4/4 giá trị, không có giá trị thừa. `nc` rộng 1 bit, `NIGHT_TICKS = 2` ⇒ dùng hết 2/2. **Không có trạng thái bất hợp lệ ở đâu trong thiết kế** |
| Nếu `PHASE_TICKS = 5`? | `PW = ⌈log₂5⌉ = 3`, `pc` có 8 giá trị nhưng chỉ 5 hợp lệ ⇒ **xuất hiện 3 giá trị thừa**. Mạch vẫn tự hồi phục: `pc <= pc+1` sẽ quấn `7 → 0` sau vài chu kỳ. Nhưng trong lúc đó, pha bị kéo dài bất thường |
| Trước cạnh clock đầu tiên? | Cả 6 FF là `X`. Reset **đồng bộ** cần ít nhất một cạnh `clk` để dọn. Đây là nghĩa vụ N-1 của tầng ngoài |

## 8. So sánh với hai FSM khác trong cùng gói

| | **F01** (đề này) | **F02** (máy bán hàng) | **E07** (thanh ghi đảo bit) |
|---|---|---|---|
| Có FSM không? | ✅ 4 trạng thái | ✅ 3 trạng thái | ❌ không có |
| Bit mã hoá | 2 (dùng hết 4/4) | 2 (dùng 3/4 ⇒ **có mã thừa**) | — |
| Mealy hay Moore? | **Mealy** (lớp phủ đêm) | **Moore** (đầu ra chỉ từ thanh ghi) | — |
| Trạng thái bất hợp lệ | **không có** | **có** — `2'd3` | — |
| Nhánh `default` | chết (bị Yosys xoá) | **sống** — là cơ chế tự hồi phục | — |
| Tổng FF | 6 | 10 | 8 (dữ liệu, không phải trạng thái) |

Ba đề đặt cạnh nhau cho thấy: *số trạng thái so với luỹ thừa của 2* quyết định việc có hay
không cần xử lý trạng thái bất hợp lệ, còn *cách hiện thực chế độ phụ* quyết định Mealy
hay Moore.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
