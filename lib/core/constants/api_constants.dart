class ApiConstants {
  // PENTING: Jika pakai Emulator Android, gunakan 10.0.2.2, bukan localhost
  // Jika pakai HP fisik (USB debugging), gunakan IP Laptop (misal 192.168.1.x)
  // http://192.168.100.140:5000
  // https://flutter.api.myperfume.my.id/
  static const String baseUrl = 'http://192.168.100.140:5000'; 
  static const String apiUrl = '$baseUrl/api';
  
  // Helper untuk menampilkan gambar dari server
  static String getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    // Asumsi path dari database adalah "uploads/ktp.jpg"
    return '$baseUrl/$path';
  }
}