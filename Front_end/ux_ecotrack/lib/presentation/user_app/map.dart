import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final LatLng _center = LatLng(16.0471, 108.2068); // Đà Nẵng
  double _currentZoom = 12.0;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final url = Uri.parse(
      'http://192.168.1.89:8080/api/reports',
    ); // đổi IP LAN khi chạy thật
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        _reports = json.decode(response.body);
      });
    } else {
      debugPrint('Lỗi tải dữ liệu: ${response.statusCode}');
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom++;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom--;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'confirmed':
        return Colors.purple;
      case 'cleaned':
        return Colors.green;
      default:
        return Colors.limeAccent;
    }
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                report['name'] ?? 'Không có tên',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "(${report['latitude']}, ${report['longitude']})",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    "Trạng thái: ${report['status']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      report['description'] ?? 'Không có mô tả',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (report['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    report['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text("Không tải được hình ảnh"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Map cộng đồng"), centerTitle: true),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(center: _center, zoom: _currentZoom),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mapapp',
              ),
              MarkerLayer(
                markers: _reports.map((report) {
                  final lat = report['latitude'];
                  final lng = report['longitude'];
                  final status = report['status'];
                  final name = report['name'];

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 50,
                    height: 50,
                    builder: (context) => GestureDetector(
                      onTap: () => _showReportDetails(report),
                      child: Tooltip(
                        message: "$name\nTrạng thái: $status",
                        child: Icon(
                          Icons.location_pin,
                          color: _getStatusColor(status),
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 📋 Chú thích
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Trạng thái",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  _LegendItem(color: Colors.red, label: "Chờ xử lý"),
                  _LegendItem(color: Colors.purple, label: "Đã xác nhận"),
                  _LegendItem(color: Colors.green, label: "Đã dọn"),
                ],
              ),
            ),
          ),

          // 🔍 Nút zoom
          Positioned(
            bottom: 10,
            right: 7,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 3),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🌈 Widget hiển thị từng dòng chú thích
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
