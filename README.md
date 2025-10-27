# DoAn_MyHealth

**DoAn_MyHealth** là một ứng dụng **giám sát sức khỏe và tâm trạng** được phát triển bằng **Flutter**, kết hợp với **Firebase** để lưu trữ dữ liệu người dùng. Mục tiêu của dự án là giúp người dùng theo dõi các chỉ số sức khỏe cơ bản và trạng thái tâm lý hàng ngày.

---

## 🔹 Mục tiêu dự án
- Theo dõi **số bước chân, cân nặng, giấc ngủ** và lượng nước uống.
- Theo dõi **tâm trạng và mức độ stress** hàng ngày.
- Hiển thị **biểu đồ sức khỏe 7 ngày gần nhất**.
- Lưu trữ dữ liệu an toàn với **Firebase Auth và Firestore**.
- Giao diện **thân thiện, dễ sử dụng**, phù hợp với di động.

---

## 🔹 Tính năng chính
1. **Health Screen**
   - Nhập số bước chân, cân nặng, giờ ngủ.
   - Hiển thị biểu đồ số bước chân theo tuần.
   - Lưu lịch sử dữ liệu và hiển thị danh sách chi tiết.
2. **Mood Screen**
   - Chọn tâm trạng (Vui / Bình thường / Buồn).
   - Chỉnh mức độ stress (1–10).
   - Thêm ghi chú về tâm trạng.
   - Lưu và hiển thị lịch sử tâm trạng.
3. **Firebase**
   - **Authentication**: Đăng nhập bằng email.
   - **Firestore**: Lưu trữ dữ liệu sức khỏe và tâm trạng.
   
---

## 🔹 Công nghệ sử dụng
- **Flutter & Dart**: Xây dựng ứng dụng đa nền tảng.
- **Firebase Auth**: Xác thực người dùng.
- **Cloud Firestore**: Lưu trữ dữ liệu thời gian thực.
- **Intl**: Định dạng ngày giờ.
- **Provider / Controller pattern**: Quản lý trạng thái và logic nghiệp vụ.

---

## 🔹 Cấu trúc dự án
