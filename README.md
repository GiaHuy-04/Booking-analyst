# Booking-analyst
# 🏨 Hệ Thống Quản Lý Khách Sạn - Tổng Quan Dữ Liệu & Mối Quan Hệ Giữa Các Bảng

Tài liệu này cung cấp cái nhìn tổng quan về cấu trúc cơ sở dữ liệu của hệ thống quản lý khách sạn, bao gồm chi tiết về các bảng dữ liệu, cột dữ liệu, và mối quan hệ giữa các bảng.

---

## 1️⃣ Bảng `Customers` (Khách hàng)

- **Mô tả:** Chứa thông tin của khách hàng từng đặt phòng.
- **Khóa chính:** `customer_id`
- **Quan hệ:** 1 khách hàng ↔ nhiều đặt phòng (`Bookings`)

| Cột            | Kiểu dữ liệu     | Mô tả                            |
|----------------|------------------|----------------------------------|
| `customer_id`  | `INTEGER (PK)`   | Mã định danh khách hàng          |
| `full_name`    | `VARCHAR(255)`   | Họ và tên                        |
| `email`        | `VARCHAR(255)`   | Email (duy nhất)                 |
| `phone`        | `VARCHAR(20)`    | Số điện thoại                    |
| `created_at`   | `TIMESTAMP`      | Ngày đăng ký                     |

---

## 2️⃣ Bảng `Rooms` (Phòng khách sạn)

- **Mô tả:** Lưu thông tin phòng hiện có.
- **Khóa chính:** `room_id`
- **Quan hệ:** 1 phòng ↔ nhiều đặt phòng (`Bookings`)

| Cột               | Kiểu dữ liệu     | Mô tả                                  |
|-------------------|------------------|----------------------------------------|
| `room_id`         | `INTEGER (PK)`   | Mã phòng                                |
| `room_number`     | `VARCHAR(10)`    | Số phòng                                |
| `room_type`       | `VARCHAR(50)`    | Loại phòng (Standard, Deluxe, ...)     |
| `price_per_night` | `DECIMAL(10,2)`  | Giá mỗi đêm                             |
| `status`          | `VARCHAR(20)`    | Trạng thái (`Available`, `Booked`)     |

---

## 3️⃣ Bảng `Bookings` (Đặt phòng)

- **Mô tả:** Ghi nhận lịch sử đặt phòng.
- **Khóa chính:** `booking_id`
- **Quan hệ:**
  - `customer_id` ↔ `Customers`
  - `room_id` ↔ `Rooms`
  - `booking_id` ↔ `Payments`, `Service_Usage`

| Cột           | Kiểu dữ liệu     | Mô tả                                |
|---------------|------------------|--------------------------------------|
| `booking_id`  | `INTEGER (PK)`   | Mã đặt phòng                         |
| `customer_id` | `INTEGER (FK)`   | Khách hàng liên quan                 |
| `room_id`     | `INTEGER (FK)`   | Phòng được đặt                       |
| `check_in`    | `DATE`           | Ngày nhận phòng                      |
| `check_out`   | `DATE`           | Ngày trả phòng                       |
| `status`      | `VARCHAR(20)`    | Trạng thái đặt phòng                 |
| `created_at`  | `TIMESTAMP`      | Ngày tạo đặt phòng                   |

---

## 4️⃣ Bảng `Payments` (Thanh toán)

- **Mô tả:** Lưu thông tin các khoản thanh toán.
- **Khóa chính:** `payment_id`
- **Quan hệ:** `booking_id` ↔ `Bookings`

| Cột             | Kiểu dữ liệu     | Mô tả                                |
|------------------|------------------|--------------------------------------|
| `payment_id`     | `INTEGER (PK)`   | Mã thanh toán                        |
| `booking_id`     | `INTEGER (FK)`   | Liên kết đặt phòng                   |
| `amount`         | `DECIMAL(10,2)`  | Số tiền thanh toán                   |
| `payment_method` | `VARCHAR(50)`    | Hình thức thanh toán                 |
| `payment_date`   | `TIMESTAMP`      | Ngày thanh toán                      |

---

## 5️⃣ Bảng `Services` (Dịch vụ khách sạn)

- **Mô tả:** Danh sách dịch vụ bổ sung.
- **Khóa chính:** `service_id`
- **Quan hệ:** `service_id` ↔ `Service_Usage`

| Cột             | Kiểu dữ liệu     | Mô tả                                       |
|------------------|------------------|---------------------------------------------|
| `service_id`     | `INTEGER (PK)`   | Mã dịch vụ                                  |
| `service_name`   | `VARCHAR(255)`   | Tên dịch vụ (e.g. Spa, Gym, Mini Bar, ...) |
| `price`          | `DECIMAL(10,2)`  | Giá dịch vụ                                 |

---

## 6️⃣ Bảng `Service_Usage` (Lịch sử sử dụng dịch vụ)

- **Mô tả:** Ghi nhận dịch vụ đã sử dụng.
- **Khóa chính:** `usage_id`
- **Quan hệ:**
  - `booking_id` ↔ `Bookings`
  - `service_id` ↔ `Services`

| Cột             | Kiểu dữ liệu     | Mô tả                                      |
|------------------|------------------|--------------------------------------------|
| `usage_id`       | `INTEGER (PK)`   | Mã ghi nhận sử dụng                        |
| `booking_id`     | `INTEGER (FK)`   | Đặt phòng liên quan                        |
| `service_id`     | `INTEGER (FK)`   | Dịch vụ được sử dụng                       |
| `quantity`       | `INTEGER`        | Số lượng sử dụng                           |
| `total_price`    | `DECIMAL(10,2)`  | Tổng tiền (=`quantity` x `price`)         |

---

## 🔗 Sơ Đồ Mối Quan Hệ

1. **Customers (1) → (N) Bookings**
2. **Rooms (1) → (N) Bookings**
3. **Bookings (1) → (N) Payments**
4. **Bookings (1) → (N) Service_Usage**
5. **Services (1) → (N) Service_Usage**

---

## 💾 Dữ Liệu Mẫu
https://drive.google.com/drive/folders/17GWVrAOwuFlYfcnq4fJYhj2Jrv8ScY1D

