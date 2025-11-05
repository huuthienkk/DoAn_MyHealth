import os

local_appdata = os.getenv("LOCALAPPDATA")
gradle_path = os.path.join(
    local_appdata,
    "Pub", "Cache", "hosted", "pub.dev",
    "tflite_flutter-0.9.5", "android", "build.gradle"
)

if not os.path.exists(gradle_path):
    print(f"❌ Không tìm thấy file build.gradle tại {gradle_path}")
    exit(1)

print(f"✅ Đã tìm thấy file: {gradle_path}")

# Đọc nội dung
with open(gradle_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# Nếu chưa có namespace thì chèn thêm
has_namespace = any("namespace" in line for line in lines)
if not has_namespace:
    for i, line in enumerate(lines):
        if "group" in line and "com." in line:
            lines.insert(i + 1, 'namespace "com.tfliteflutter.tflite_flutter_plugin"\n')
            break

    with open(gradle_path, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print("✅ Đã thêm namespace vào build.gradle thành công!")
else:
    print("✅ File đã có namespace, không cần sửa.")
