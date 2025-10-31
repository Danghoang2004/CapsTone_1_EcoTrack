import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class BaoCao extends StatefulWidget {
  const BaoCao({super.key});

  @override
  State<BaoCao> createState() => _BaoCaoState();
}

class _BaoCaoState extends State<BaoCao> {
  File? selectedImage;
  String selectedTrashType = "";
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  bool isSending = false;

  // chọn ảnh từ camera hoặc thư viện
  Future<void> _pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // gửi dữ liệu lên backend
  Future<void> _submitReport() async {
    if (selectedImage == null ||
        selectedTrashType.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      var uri = Uri.parse("http://192.168.1.89:8080/api/reports/upload");

      var request = http.MultipartRequest("POST", uri)
        ..fields['title'] = 'Báo cáo rác thải'
        ..fields['description'] = descriptionController.text
        ..fields['latitude'] = '10.762622'
        ..fields['longitude'] = '106.660172'
        ..fields['status'] = selectedTrashType
        ..files.add(
          await http.MultipartFile.fromPath('image', selectedImage!.path),
        );

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gửi báo cáo thành công ✅")),
        );
        setState(() {
          selectedImage = null;
          descriptionController.clear();
          selectedTrashType = "";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gửi thất bại: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi gửi: $e")));
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo rác thải')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // --- Ô chọn ảnh ---
              Container(
                padding: const EdgeInsets.all(15),
                height: 200,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt_outlined),
                        SizedBox(width: 10),
                        Text(
                          "Chụp ảnh rác thải",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: DottedBorder(
                        color: Colors.grey,
                        strokeWidth: 1.2,
                        dashPattern: const [6, 4],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(8),
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.grey[100],
                          child: selectedImage == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Nhấn để chụp ảnh\nhoặc chọn từ thư viện',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : Image.file(selectedImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Loại rác ---
              Container(
                height: 120,
                width: 300,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 10),
                        Text(
                          "Loại rác thải",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      children: [
                        _buildTrashTypeButton("Vô cơ"),
                        _buildTrashTypeButton("Hữu cơ"),
                        _buildTrashTypeButton("tổng hợp"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Mô tả ---
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description),
                        SizedBox(width: 10),
                        Text(
                          "Mô tả chi tiết",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      "Mô tả tình trạng rác thải",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              "Ví dụ: Nhiều chai nhựa và túi nilon bị vứt bừa bãi ở góc đường...",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // --- Nút gửi ---
              ElevatedButton.icon(
                onPressed: isSending ? null : _submitReport,
                icon: const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.white,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: const Color.fromARGB(255, 94, 185, 103),
                  shadowColor: const Color.fromARGB(255, 111, 110, 109),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                label: Text(
                  isSending ? "Đang gửi..." : "Gửi báo cáo",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 243, 243, 243),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // --- Ghi chú ---
              Container(
                height: 80,
                width: 300,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 223, 236, 213),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    "💚 Mỗi báo cáo của bạn giúp cộng đồng có môi trường sạch hơn Bạn sẽ nhận được điểm thưởng sau khi báo cáo được xác nhận 💚",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color.fromARGB(255, 27, 134, 30),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget chọn loại rác
  Widget _buildTrashTypeButton(String label) {
    final isSelected = selectedTrashType == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green[200] : Colors.white,
          side: BorderSide(color: isSelected ? Colors.green : Colors.grey),
          minimumSize: Size(20, 30),
        ),
        onPressed: () {
          setState(() {
            selectedTrashType = label;
          });
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.black),
        ),
      ),
    );
  }
}
