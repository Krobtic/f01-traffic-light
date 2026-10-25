# F01 · Giao diện (Interface)

---

## 1. Ánh xạ chân theo Charter (mục 4)

> Theo danh mục đề: uio_in[0]=chế độ đêm · uo_out[2:0]=đèn hướng 1 {R,Y,G} · uo_out[5:3]=đèn hướng 2 · uo_out[7:6]=mã trạng thái
> Ngân sách chân: 1 bit vào + 8 bit ra = 9 trên 24 chân.
> Ánh xạ chân đã khả thi, không phải đổi gì.
> Một ô Tiny Tapeout có đúng 24 chân: ui_in 8 chỉ vào, uo_out 8 chỉ ra, uio 8 chọn chiều từng chân. uio_in và uio_out là cùng một bộ chân vật lý.

## 2. Bảng giao diện đã CHỐT — module `f01_traffic_fsm_explicit`

Bảng dưới đây **đọc trực tiếp từ RTL** (`04_IMPLEMENTATION/rtl/`), không phải chép tay,
nên luôn nhất quán với mã nguồn.

| Tín hiệu | Chiều | Độ rộng (bit) | Vai trò | Mức tích cực / giả định |
|---|---|---:|---|---|
| `clk` | input | 1 | clock | |
| `rst_n` | input | 1 | reset (đồng bộ hoá trạng thái) | |
| `ena` | input | 1 | điều khiển | |
| `night_mode` | input | 1 | dữ liệu vào | |
| `uo_out[7:0]` | output | 8 | kết quả ra | |

**Tổng hợp:** 4 cổng vào (4 bit) · 1 cổng ra (8 bit).

**Clock:** `clk`

**Reset:** `rst_n`

## 3. Ngân sách chân Tiny Tapeout

| Hạng mục | Số bit |
|---|---:|
| Tổng bit vào | **4** |
| Tổng bit ra | **8** |
| **Tổng cộng** | **12** |
| Ô Tiny Tapeout có | **24** |
| **Chênh lệch** | **12 chân còn dư** |

> Nhắc lại cấu trúc chân Tiny Tapeout: một ô có đúng 24 chân — `ui_in` 8 chỉ vào,
> `uo_out` 8 chỉ ra, `uio` 8 chọn chiều từng chân; **`uio_in` và `uio_out` là cùng một bộ
> chân vật lý**.

> ✅ Ngân sách chân **đủ**: tổng số bit logic nằm trong 24 chân vật lý, không cần
> nạp nhiều nhịp và không phải hy sinh tín hiệu nào.

## 4. Điều kiện hợp lệ của đầu vào

| Điều kiện | Ai bảo đảm |
|---|---|
| Các cổng vào không chứa `X`/`Z` khi lấy mẫu | Tầng ngoài |
| Tín hiệu vào đồng bộ với `clk` hoặc đã qua bộ đồng bộ | Tầng ngoài |
| Chuỗi reset được giữ đủ dài trước khi bắt đầu hoạt động | Tầng ngoài |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-F01-002, AC-1.*
