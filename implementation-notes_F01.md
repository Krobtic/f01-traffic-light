# F01 — FSM đèn giao thông hai chiều có đèn vàng · Ghi chú thực hiện

---

## 1. Bài toán này thực chất là gì

Đèn giao thông là bài tập FSM kinh điển, và chính vì kinh điển mà nó dễ bị làm hời hợt:
vẽ bốn vòng tròn, nối bốn mũi tên, viết `case`, xong. Đề F01 được đặt ra để ép đi sâu hơn
ở ba điểm mà bài tập giáo khoa thường bỏ qua.

**Điểm thứ nhất — có một yêu cầu AN TOÀN trộn lẫn giữa các yêu cầu chức năng.** Charter
mục 2 câu 1 hỏi thẳng: *"Bằng chứng nào chứng minh KHÔNG BAO GIỜ có hai hướng cùng xanh —
đây là yêu cầu an toàn, không phải yêu cầu chức năng?"* Chữ "không bao giờ" đòi một loại
bằng chứng khác hẳn. Mô phỏng chỉ nói "trong 26 chu kỳ đã chạy thì không xảy ra". Yêu cầu
an toàn cần chứng minh **vét cạn**.

**Điểm thứ hai — chế độ đêm buộc phải chọn kiến trúc.** Nhấp nháy vàng có thể làm bằng hai
cách: thêm trạng thái, hoặc phủ lên đầu ra. Hai cách cho hai loại máy khác nhau (Moore và
Mealy), hai số flip-flop khác nhau, và hai hồ sơ rủi ro khác nhau. Đây là quyết định phải
ra **ở mức sơ đồ**, trước khi viết code — đúng điều Charter mục 10 cảnh báo.

**Điểm thứ ba — Charter mục 9 buộc đối chiếu ⌈log₂(số trạng thái)⌉ với số flip-flop thật
trong netlist**, và tìm hiểu vì sao công cụ chọn như vậy. Câu trả lời cho F01 hoá ra thú
vị hơn mong đợi (§8).

## 2. Bản chất kỹ thuật — cơ chế hoạt động

F01 là một **FSMD tối giản**: một FSM 4 trạng thái cộng một datapath đếm thời gian, nối
với nhau bằng đúng **một dây** — tín hiệu `tick`.

Cơ chế cốt lõi nằm ở chỗ **FSM không tự đếm thời gian**. Nó chỉ biết "đã tới lúc đổi pha
chưa?" qua một bit. Việc "bao lâu là đủ" hoàn toàn thuộc về bộ đếm `pc`. Sự tách bạch này
là lý do đồ thị trạng thái chỉ có 4 đỉnh và 8 cạnh — nếu trộn thời gian vào trạng thái,
đồ thị sẽ phình ra `4 × PHASE_TICKS` đỉnh.

Cơ chế thứ hai, tinh tế hơn: **chế độ đêm không làm FSM quên pha đang chạy**. RTL viết
`next_state = state;` khi `night_mode = 1`. Câu này trông tầm thường nhưng nó thay thế cả
một cơ chế "lưu pha rồi khôi phục" mà phương án thêm-trạng-thái sẽ cần. Thanh ghi `state`
tự nó **là** nơi lưu. Đo được: tổng 6 flip-flop, trong đó chỉ 2 cho trạng thái.

Cơ chế thứ ba, và là chỗ đắt giá nhất về dạy học: **lớp phủ đêm biến máy Moore thành máy
Mealy**. `night_mode` là một cổng vào, và nó xuất hiện **trực tiếp** trong bảng giải mã
đầu ra. Hệ quả đo được: STA báo đường tới hạn là `night_mode → uo_out[1]` — một đường tổ
hợp thuần từ chân vào tới chân ra, không qua flip-flop nào. Một máy Moore thuần **không
thể** có đường như vậy. Đây không phải lỗi — đó là cái giá đã biết trước của việc chọn lớp
phủ.

Cơ chế thứ tư liên quan tới an toàn: tính chất "không hai xanh" **không** được bảo đảm bởi
một mạch kiểm tra nào cả. Nó rơi ra từ **cách mã hoá trạng thái**. Bit `state[1]` chính là
"hướng nào đang ưu tiên". Đèn xanh hướng 1 cần `state[1] = 0`; đèn xanh hướng 2 cần
`state[1] = 1`. Cùng một dây, hai cực tính đối nhau — không cần mạch nào để bảo đảm tính
loại trừ, nó là hệ quả của đại số Boole. Netlist xác nhận điều này ở mức cell (§7).

## 3. Đọc mã nguồn: RTL làm gì, từng dòng quan trọng

**Hàm chuyển trạng thái** (`f01_traffic_fsm.sv:26–46`):

```systemverilog
always_comb begin
    next_state = state;
    if (night_mode) begin
        next_state = state;        // ← ĐÓNG BĂNG pha, không phải trạng thái thứ năm
    end else begin
        case (state)
            NS_GREEN: if (phase_cnt == PHASE_TICKS-1) next_state = NS_YELLOW;
```

Hai điều đọc được ngay: (a) gán mặc định `next_state = state` ở dòng đầu bảo đảm
`always_comb` **không** suy diễn latch, dù `case` không phủ hết; (b) nhánh `night_mode`
gán lại đúng giá trị cũ — dư thừa về logic, nhưng làm **ý định** hiện rõ trong mã. Yosys
xoá phần dư này (`yosys.log:30` *"Removed 1 dead cases"*) nên không tốn cell.

**Cập nhật bộ đếm pha** (`:68–73`) — chỗ có một điểm dư thừa đáng bàn:

```systemverilog
if (state != next_state)      phase_cnt <= '0;
else if (phase_cnt == PHASE_TICKS-1) phase_cnt <= '0;
else                          phase_cnt <= phase_cnt + 1'b1;
```

Trong nhánh không-đêm, `state != next_state` đúng **khi và chỉ khi** `phase_cnt ==
PHASE_TICKS-1`. Hai nhánh đầu trùng nhau. Bản `_explicit` gộp lại thành một biểu thức ba
ngôi (`:46`) và cho **cùng** kết quả tổng hợp. Vậy có nên gộp? Nên giữ ba nhánh: nếu sau
này thêm một đường chuyển pha sớm (nút ưu tiên xe cứu hoả), nhánh 1 vẫn đúng còn cách viết
gộp sẽ sai.

**Bảng giải mã đầu ra với lớp phủ** (`:78–115`):

```systemverilog
uo_out = '0;                     // mặc định TẮT HẾT — quan trọng cho an toàn
if (night_mode) begin
    if (night_phase) begin
        uo_out[2:0] = 3'b010;    // vàng
        uo_out[5:3] = 3'b010;
    end
end else begin ... end
uo_out[7:6] = state;             // mã trạng thái, LUÔN hiện, kể cả trong đêm
```

Dòng `uo_out = '0;` đầu tiên là một lựa chọn an toàn tốt: trạng thái mặc định là **tắt
hết**, không phải "xanh hết". Dòng cuối là nguồn gốc của một hạn chế: `uo_out[7:6]` hiện
pha **bị giữ**, không có bit nào báo "đang ở chế độ đêm" (§9, S-4).

**Netlist — chỗ đáng ngạc nhiên nhất:**

```verilog
sky130_fd_sc_hd__dfxtp_1 _46_ (.CLK(clk), .D(_00_), .Q(uo_out[6]));
sky130_fd_sc_hd__dfxtp_1 _47_ (.CLK(clk), .D(_01_), .Q(uo_out[7]));
```

Không có net nào tên `state`. Yosys **hợp nhất** thanh ghi trạng thái với cổng ra, vì
`uo_out[7:6] = state;` là phép nối dây thuần. Hệ quả kép: xuất mã trạng thái ra chân là
**0 cell**, nhưng cũng chính vì thế mà pass `fsm` của Yosys **không nhận ra** đây là FSM
(§8).

## 4. Vì sao chọn kiến trúc này

Bốn quyết định, mỗi quyết định có số liệu đối chứng (chi tiết ở `03_ARCHITECTURE/tradeoff.md`):

| Quyết định | Phương án đã chọn | Phương án thay thế | Chênh lệch đo được |
|---|---|---|---|
| Chế độ đêm | **Lớp phủ đầu ra** | Thêm 2 trạng thái | 6 FF so với ≥ 9 FF; 0 mã thừa so với 2 |
| Mã hoá | **Nhị phân tuần tự** | One-hot | 2 FF so với 4 FF (40,0384 so với 80,0768 µm²) |
| Đếm thời lượng | **Bộ đếm nhị phân** | Ring counter | 2 FF so với 4 FF, và mở rộng được |
| Chia tần | **Để ngoài khối** | Đưa vào trong | 32 cell so với ước tính gấp 5–6 lần |

Cái giá của quyết định thứ nhất là tính Mealy và rủi ro glitch; cái giá của quyết định thứ
tư là số cell đo được (32) không so trực tiếp được với ước lượng Charter (180–260).

## 5. Cách thực hiện — lộ trình 8 bước từ đặc tả tới GDSII

1. **Vẽ sơ đồ trạng thái TRƯỚC** — đây là yêu cầu của Charter mục 10, không phải lời
   khuyên. Chốt: 4 đỉnh, 8 cạnh, chế độ đêm là lớp phủ.
2. **Phát biểu yêu cầu an toàn tách riêng** khỏi yêu cầu chức năng, và quyết định trước sẽ
   chứng minh nó bằng cách nào (ở đây: bằng cấu trúc mã hoá, không bằng mô phỏng).
3. **Chọn mã hoá trạng thái** sao cho bảng giải mã đầu ra đơn giản — ở đây, gán
   `state[1]` = "hướng ưu tiên" làm tính chất an toàn trở thành hiển nhiên.
4. **Viết mô hình chuẩn Python** kiểm tính an toàn trên mọi trạng thái, trước khi viết RTL
   (`reference_model.py` — PASS).
5. **Viết RTL** tách ba `always`: một `always_comb` cho next-state, một `always_ff` cho
   mọi thanh ghi, một `always_comb` cho giải mã đầu ra.
6. **Mô phỏng** với testbench kiểm **tính chất** (assertion chạy mỗi chu kỳ), không chỉ
   kiểm giá trị. Kết quả: `F01 TB PASS`, `$finish` tại `t = 256`.
7. **Tổng hợp + STA**, rồi **đọc netlist bằng tay** để xác nhận tính chất an toàn vẫn còn
   sau khi `abc` tối ưu lại logic. Đây là bước hay bị bỏ và là bước quan trọng nhất của
   một thiết kế an toàn.
8. **P&R, DRC, LVS, GDS** — ⬜ **chưa chạy** trong gói này.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Nguồn |
|---|---:|---|
| Số cell | 32 | `synth_stat.txt` |
| Flip-flop | 6 | `synth_stat.txt` |
| Diện tích | 279,0176 µm² | `synth_stat.txt` |
| ├ tuần tự | 120,1152 µm² (43,05 %) | tính từ liberty × số cell |
| └ tổ hợp | 158,9024 µm² (56,95 %) | như trên |
| Startpoint → Endpoint | `night_mode` → `uo_out[1]` | `sta/summary.txt` |
| Data arrival | 1,18 ns | `timing_report_max.txt` |
| Setup slack | 7,82 ns (MET) | như trên |
| Hold slack | 0,45 ns (MET) | `timing_report_min.txt` |
| `t_ckq` của `dfxtp_1` | 0,30 ns | `timing_report_min.txt` |
| WNS / TNS | 0,00 / 0,00 | `wns.txt`, `tns.txt` |
| Công suất | 2,76e-05 W (tuần tự 92,8 %, tổ hợp 7,2 %) | `power_report.txt` |

**Những gì các số này CHỨNG MINH:**
- RTL tổng hợp được ra standard cell sky130 thật.
- Số flip-thanh-ghi-trạng-thái đúng bằng ⌈log₂4⌉ = 2 — Yosys **không** đổi sang one-hot.
- Phân loại "Tuần tự" đúng: 6 ô nhớ đồng bộ.
- Với chu kỳ giả định 10 ns, không có vi phạm setup lẫn hold sau tổng hợp.
- Đường tới hạn **không** đi qua thanh ghi trạng thái — trả lời trực tiếp Charter mục 2
  câu 3.

**Những gì các số này KHÔNG chứng minh:**
- **Không** chứng minh netlist tương đương RTL đã mô phỏng — vì **module được tổng hợp
  (`_explicit`) chưa từng được mô phỏng**, và **tham số cũng khác** (`PHASE_TICKS` 4 so
  với 2). Đây là lỗ hổng chuỗi bằng chứng lớn nhất của gói này.
- **Không** chứng minh mạch chạy ở 100 MHz. 10 ns là giả định SDC; chưa có RC; một góc PVT.
- **Không** chứng minh không có glitch "hai xanh" thoáng qua khi `night_mode` lật — mô
  phỏng zero-delay không sinh glitch.
- **Không** chứng minh đèn sáng **đúng màu**: testbench chỉ kiểm `both_green`, không kiểm
  giá trị `uo_out` đầy đủ. Một RTL đổi chỗ vàng và đỏ vẫn PASS toàn bộ testbench hiện tại.
- Biên hold 0,45 ns **chưa** trừ clock skew thật (CTS ⬜ chưa chạy).

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

**Câu 1 — "Bằng chứng nào chứng minh KHÔNG BAO GIỜ có hai hướng cùng xanh?"**

Bằng chứng là **cấu trúc netlist**, không phải mô phỏng. Ba dòng trong
`06_GDSII/synthesis/netlist.v`:

```verilog
sky130_fd_sc_hd__clkinv_1 _21_ (.A(uo_out[7]), .Y(_07_));
sky130_fd_sc_hd__nor3_1 _41_ (.A(uo_out[7]), .B(uo_out[6]), .C(night_mode), .Y(uo_out[0]));
sky130_fd_sc_hd__nor3_1 _44_ (.A(_07_),      .B(uo_out[6]), .C(night_mode), .Y(uo_out[3]));
```

`nor3` cho `Y = !A & !B & !C`. Vậy `uo_out[0] = ¬s1·¬s0·¬night` và
`uo_out[3] = s1·¬s0·¬night`. Tích của chúng chứa `¬s1·s1 = 0` với **mọi** giá trị của mọi
tín hiệu. Hai cell được lái bởi **cùng một dây** `uo_out[7]`, một cell qua bộ đảo `_21_`,
cell kia không. Đây là chứng minh đại số, vét cạn, độc lập với số ca mô phỏng — đúng mức
chặt chẽ mà một yêu cầu an toàn đòi hỏi. Kết quả mô phỏng (`f01_tb.sv:24, 32, 40, 47`) là
bằng chứng **bổ trợ**, không phải bằng chứng chính.

**Câu 2 — "Số ô nhớ dự đoán theo ⌈log₂(số trạng thái)⌉ là bao nhiêu, và netlist có khớp?"**

Xem §8.

**Câu 3 — "Đường tới hạn của FSM đi từ đâu tới đâu — qua thanh ghi trạng thái hay qua
logic đầu ra?"**

**Qua logic đầu ra, và thậm chí không chạm thanh ghi nào.** `sta/summary.txt`:
`night_mode (input) → uo_out[1] (output)`, slack 7,82 ns, đúng **một** cell trên đường
(`_42_`, `a22o_1`, 0,18 ns). Sáu trong mười đường xấu nhất đều là in→out. Đường qua logic
next-state của FSM (`ena → _24_ → _27_ → _29_ → _47_/D`, 3 cell, arrival 1,49 ns) chỉ xếp
hạng 7 với slack 8,43 ns.

Nhưng phải nói thêm một tầng: **kết quả này do ràng buộc SDC quyết định, không do mạch.**
`design.sdc` đặt `input_delay = output_delay = 1,0 ns`. Đường ra vì thế có `required time`
9,00 ns, còn đường tới flip-flop được tới 9,92 ns — chênh 0,92 ns. Đổi hai con số giả định
đó thì thứ hạng đường tới hạn sẽ đổi, mà không sửa một dòng RTL nào.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *"Vẽ sơ đồ trạng thái và đối chiếu số flip-flop trong báo cáo với số bit tối thiểu cần
> để mã hoá số trạng thái của mình. Nếu công cụ dùng nhiều hơn, tìm hiểu về mã hoá one-hot
> và nêu vì sao công cụ chọn cách đó."*

**Số học trước:** 4 trạng thái ⇒ ⌈log₂4⌉ = **2 bit tối thiểu**.

**Netlist thật:** 6 × `dfxtp_1`. Truy vết từng cell trong `netlist.v` theo chân `Q`:

| Cell | `Q` nối tới | Thuộc về |
|---|---|---|
| `_46_` | `uo_out[6]` | **`state[0]`** |
| `_47_` | `uo_out[7]` | **`state[1]`** |
| `_49_`, `_50_` | `pc[0]`, `pc[1]` | bộ đếm pha |
| `_51_` | `nc` | bộ đếm nhấp nháy |
| `_48_` | `night_phase` | bit pha nhấp nháy |

**Kết luận: đúng 2 flip-thanh-ghi cho trạng thái — khớp chính xác ⌈log₂4⌉. Công cụ KHÔNG
dùng nhiều hơn, KHÔNG đổi sang one-hot.** Bốn flip-flop còn lại không phải trạng thái FSM
mà là datapath đếm thời gian và bit pha nhấp nháy.

**Nhưng lý do Yosys giữ nhị phân không phải lý do người ta hay đoán.** `synth.ys` có chạy
pass `fsm`, và `yosys.log:187–205` cho thấy đủ chuỗi `FSM_DETECT → FSM_EXTRACT →
FSM_RECODE → FSM_MAP`. Tuy nhiên **không một dòng nào báo tìm thấy FSM** — `FSM_DETECT` in
ra rỗng.

Nguyên nhân đọc được từ netlist: thanh ghi `state` được **nối thẳng ra cổng ra**
(`uo_out[7:6] = state;`). `fsm_detect` của Yosys chỉ nhận một thanh ghi là ứng viên FSM
khi thanh ghi đó chỉ tham gia các phép **so sánh bằng**. Ở đây `state` còn được dùng làm
**giá trị** đi ra chân, nên nó bị loại.

> 🎓 **Đây là bài học đáng giá nhất của Charter mục 9 cho đề này:** *một yêu cầu ở tầng
> đặc tả (Charter mục 4 bắt xuất mã trạng thái ra `uo_out[7:6]`) đã vô hiệu hoá một pass
> tối ưu của công cụ tổng hợp.* Kết quả tình cờ là tốt — nhị phân vẫn là lựa chọn đúng cho
> 4 trạng thái. Nhưng trả lời Charter mục 9 bằng câu *"công cụ chọn nhị phân vì nhị phân
> tốt hơn"* là **sai bản chất**: công cụ không chọn gì cả, nó không nhìn thấy FSM.

**Nếu one-hot được dùng thì sao?** 4 FF thay vì 2 (80,0768 thay vì 40,0384 µm²), 12/16 mã
thừa phải xử lý, và cần thêm bộ mã hoá 4→2 để xuất `uo_out[7:6]`. Đổi lại, logic
next-state đơn giản hơn và đường tới hạn ngắn hơn. Nhưng đường tới hạn của F01 **vốn đã
chỉ 1 cell**, nên one-hot ở đây chỉ tốn thêm, không lợi gì.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| S-1 | **Khẳng định F01 là máy Moore** | Sai phân loại; bỏ sót rủi ro glitch trên đèn | `sta/summary.txt` ghi đường `night_mode (input) → uo_out[1] (output)` — đường tổ hợp in→out. Máy Moore thuần không thể có đường này. Bắt sinh viên chỉ ra flip-flop nằm trên đường đó — không có |
| S-2 | **Chứng minh an toàn bằng mô phỏng** ("chạy 26 chu kỳ, không lần nào hai xanh") | Chứng minh yếu; không phải chứng minh "không bao giờ" | Hỏi: *"nếu chạy 27 chu kỳ thì sao? 10⁶ chu kỳ?"* Bằng chứng đúng là cấu trúc `_41_`/`_44_` chia nhau `uo_out[7]` (§7) |
| S-3 | **Vẽ sơ đồ 6 trạng thái** (thêm 2 trạng thái đêm) rồi báo cáo như thể đó là thiết kế | Sơ đồ không khớp mã và không khớp netlist | Netlist có **2** FF trạng thái, không phải 3. 6 trạng thái cần ⌈log₂6⌉ = 3 bit |
| S-4 | **Tin `uo_out[7:6]` báo chế độ đêm** | Đọc sai trạng thái hệ thống ngoài hiện trường | Đọc RTL `:114`: `uo_out[7:6] = state;` nằm **ngoài** mọi nhánh `if (night_mode)`. Giản đồ `timing_diagram.md` §2 chu kỳ 13–18 cho thấy mã vẫn là `10` (`EW_GREEN`) khi đèn đang nháy vàng |
| S-5 | **Báo cáo "32 cell, nhỏ hơn Charter ước lượng 180–260, vậy thiết kế tối ưu"** | Kết luận sai. Chênh lệch đến từ **dịch chuyển ranh giới khối**, không từ tối ưu | `PHASE_TICKS = 4` ⇒ `pc` chỉ 2 bit. Charter dự đoán bộ đếm ~8 bit. Bộ chia tần nằm **ngoài** khối (`system_diagram.md` §1) |
| S-6 | **Mô phỏng một module, tổng hợp module khác** rồi coi như đã kiểm chứng xong | Chuỗi bằng chứng đứt | `f01_tb.sv:5` khởi tạo `f01_traffic_fsm`; `synth_stat.txt` ghi top là `f01_traffic_fsm_explicit`; `yosys.log:21` ghi *"Removing unused module `\f01_traffic_fsm`"*. Hai module, hai tham số khác nhau |
| S-7 | **Kiểm chỉ tính an toàn, quên kiểm đúng màu đèn** | Một RTL bật sai màu vẫn PASS | Đọc `f01_tb.sv`: không có dòng nào so `uo_out` với hằng số. Yêu cầu sinh viên cố tình đổi `3'b001` thành `3'b100` ở `:91` và chạy lại — testbench vẫn PASS |
| S-8 | **Xoá nhánh `default`** vì "Yosys báo nó chết" | `always_comb` có thể suy diễn latch | `yosys.log:70–71` ghi *"No latch inferred"* — đó là **nhờ** có `default`. Xoá đi thì rủi ro quay lại |
| S-9 | **Kết luận "FSM chạy được ở 100 MHz"** từ slack 7,82 ns | Phát biểu vượt mức | `design.sdc`: 10 ns là **giả định**; `timing.md` giả định G-4 ghi chưa có RC. Và với đèn giao thông, tần số thật thấp hơn hàng nghìn lần — timing không phải vấn đề của đề này |
| S-10 | **Quên rằng chuyển `01 → 10` làm hai bit đổi cùng lúc** trên chân ra | Tầng ngoài lấy mẫu bất đồng bộ có thể đọc `00` hoặc `11` thoáng qua | `fsm.md` §1: mã nhị phân tuần tự; cạnh `NS_YELLOW → EW_GREEN` đổi cả hai bit. Mã Gray sẽ tránh được, chi phí 0 FF |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| Q1 | FSM của em là Mealy hay Moore? Chứng minh bằng một con số trong báo cáo. | **Mealy.** `sta/summary.txt`: đường `night_mode (input) → uo_out[1] (output)`, tổ hợp thuần, 0 flip-flop. Riêng `uo_out[7:6]` là Moore. |
| Q2 | Chứng minh "không bao giờ hai hướng cùng xanh" **mà không dùng kết quả mô phỏng**. | Netlist: `_41_` lấy `uo_out[7]`, `_44_` lấy `~uo_out[7]` (qua `_21_`). Tích hai đầu ra chứa `s1·¬s1 = 0`. Vét cạn. |
| Q3 | Netlist có 6 flip-flop. Chỉ đúng cái nào là trạng thái FSM. | `_46_` (`Q = uo_out[6]` = `state[0]`) và `_47_` (`Q = uo_out[7]` = `state[1]`). Bốn cái còn lại là `pc[1:0]`, `nc`, `night_phase` — datapath, không phải trạng thái. |
| Q4 | Yosys có đổi mã hoá trạng thái không? Vì sao? | **Không.** `yosys.log:187–205`: `FSM_DETECT` in ra rỗng. Vì `state` được nối thẳng ra `uo_out[7:6]` nên không được nhận là ứng viên FSM. Không phải vì Yosys "chọn" nhị phân. |
| Q5 | Chế độ đêm là trạng thái hay lớp phủ? Nếu làm cách kia thì tốn thêm bao nhiêu? | **Lớp phủ.** Cách kia (6 trạng thái) cần ≥ 9 FF thay vì 6, sinh 2 mã thừa, và phải thêm logic lưu/khôi phục pha. |
| Q6 | Khi `night_mode = 1`, `uo_out[7:6]` hiện gì? | Hiện **pha bị giữ** (ví dụ `10` = `EW_GREEN`), **không** hiện "đang đêm". Không có bit nào báo chế độ đêm — đây là hạn chế đã ghi nhận. |
| Q7 | Testbench của em đã kiểm đèn sáng **đúng màu** chưa? | **Chưa.** Chỉ kiểm `both_green`. Cần bổ sung so `uo_out` với hằng số `0x21 / 0x62 / 0x8C / 0xD4`. |
| Q8 | Module nào được mô phỏng, module nào được tổng hợp? | Mô phỏng `f01_traffic_fsm` với `PHASE_TICKS=2`; tổng hợp `f01_traffic_fsm_explicit` với `PHASE_TICKS=4`. **Chuỗi bằng chứng bị đứt**, cần chạy lại testbench trên đúng cấu hình được tổng hợp. |
| Q9 | Vì sao đường tới hạn không đi qua thanh ghi trạng thái? | Vì SDC đặt `output_delay = 1,0 ns` ⇒ `required time` của cổng ra chỉ 9,00 ns, trong khi endpoint flip-flop được 9,92 ns. Chênh 0,92 ns đủ để đường ra thắng, dù nó chỉ qua 1 cell còn đường FSM qua 3 cell. |
| Q10 | Nếu một flip-flop trạng thái bị lật do nhiễu, mạch có an toàn không? | INV-1 **vẫn** thoả (chứng minh ở Q2 đúng với mọi giá trị `state`). Nhưng INV-5 **có thể vi phạm**: lật `state[1]` đưa `NS_GREEN → EW_GREEN` trực tiếp, không qua vàng. Đây là rủi ro an toàn chưa được xử lý. |
| Q11 | Ngã tư thật có pha all-red giữa các pha. F01 thì không. Có sao không? | Có. F01 chuyển thẳng `NS_YELLOW → EW_GREEN`. Thêm all-red cần +2 trạng thái ⇒ 3 bit mã hoá ⇒ +1 FF và xuất hiện mã thừa. Nằm ngoài yêu cầu đề nhưng đáng nêu ở phần giới hạn. |
| Q12 | Diện tích tuần tự 43,05 % nhưng công suất tuần tự 92,8 %. Mâu thuẫn? | Không. Flip-flop tiêu công suất nội tại ở **mọi** cạnh clock, còn logic tổ hợp của F01 chuyển trạng thái rất thưa (mỗi `PHASE_TICKS` chu kỳ mới đổi pha một lần). |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

| Khẳng định | Trạng thái | Bằng chứng / lý do thiếu |
|---|:-:|---|
| RTL tổng hợp được ra sky130 standard cell | ✅ | `yosys.log`, `synth_stat.txt` |
| Số FF trạng thái = ⌈log₂4⌉ = 2 | ✅ | `netlist.v`, truy vết chân `Q` |
| **Không bao giờ hai hướng cùng xanh (INV-1)** ở trạng thái ổn định | ✅ **chứng minh cấu trúc** | `netlist.v`, cell `_21_`/`_41_`/`_44_` |
| INV-1 đúng **trong vùng quá độ** khi `night_mode` lật | ❌ chưa | Cần mô phỏng L5 + SDF. Mô phỏng zero-delay không sinh glitch |
| Phủ đủ 4 trạng thái và 8 cạnh của đồ thị | ✅ | `f01_tb.sv:22–27`, truy vết chu kỳ ở `corner_cases.md` §3 |
| Đèn sáng **đúng màu** ở từng pha | ❌ chưa | Testbench chỉ kiểm `both_green`, không so giá trị `uo_out` |
| Thời lượng mỗi pha đúng `PHASE_TICKS` | ❌ chưa | Không có ca đếm chu kỳ trong testbench |
| INV-5 (luôn qua vàng trước khi đổi hướng) | ❌ chưa | Chưa có assertion thời gian |
| Netlist tương đương RTL đã mô phỏng | ❌ chưa | **Module và tham số khác nhau** (W-2, W-3). Chưa chạy L4-GATE, chưa chạy kiểm tương đương hình thức |
| Không vi phạm setup/hold sau tổng hợp, chu kỳ 10 ns | ✅ | WNS 0,00 / TNS 0,00; hold slack 0,45 ns |
| Không vi phạm timing **sau P&R** | ❌ chưa | Floorplan/CTS/Routing ⬜ chưa chạy. Net `night_mode` fanout 9 là chỗ rủi ro nhất |
| Tần số hoạt động tối đa | ❌ chưa | Cần STA post-route nhiều góc PVT |
| Mạch qua được DRC/LVS | ⬛ không áp dụng | Charter mục 3 |
| Chip đã chế tạo, đã đo | ⬛ không áp dụng | Charter mục 3 |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
