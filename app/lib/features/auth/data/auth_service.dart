import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/token_manager.dart';

/// Model ringkas Pengguna SIGAP
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String phone;
  final String photoUrl;
  final String primaryArea;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone = '',
    this.photoUrl = '',
    this.primaryArea = 'Kota Padang',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Warga Padang',
      role: json['role']?.toString() ?? 'citizen',
      phone: profile['phone']?.toString() ?? '',
      photoUrl: profile['photo_url']?.toString() ?? '',
      primaryArea: profile['primary_area']?.toString() ?? 'Kota Padang',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'phone': phone,
    'photo_url': photoUrl,
    'primary_area': primaryArea,
  };
}

/// Service untuk menangani operasi autentikasi ke backend Django
class AuthService {
  final ApiClient _api = ApiClient();

  /// Registrasi akun baru
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _api.post(
      ApiConfig.register,
      requiresAuth: false,
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      final tokens = response['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        await TokenManager.saveTokens(
          access: tokens['access'].toString(),
          refresh: tokens['refresh'].toString(),
        );
      }
      await TokenManager.saveUserData(user.toJson());
      return user;
    }
    throw ApiException(
      statusCode: 500,
      code: 'PARSING_ERROR',
      message: 'Format respon server tidak dikenali.',
    );
  }

  /// Login dengan email dan kata sandi
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.login,
      requiresAuth: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      final tokens = response['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        await TokenManager.saveTokens(
          access: tokens['access'].toString(),
          refresh: tokens['refresh'].toString(),
        );
      }
      await TokenManager.saveUserData(user.toJson());
      return user;
    }
    throw ApiException(
      statusCode: 500,
      code: 'PARSING_ERROR',
      message: 'Format respon login tidak dikenali.',
    );
  }

  /// Mengambil profil terkini pengguna yang sedang login
  Future<UserModel> getProfile() async {
    final response = await _api.get(ApiConfig.me, requiresAuth: true);
    if (response is Map<String, dynamic>) {
      final user = UserModel.fromJson(response);
      await TokenManager.saveUserData(user.toJson());
      return user;
    }
    throw ApiException(
      statusCode: 500,
      code: 'PARSING_ERROR',
      message: 'Gagal memuat profil pengguna.',
    );
  }

  /// Logout akun dan masukkan refresh token ke blacklist backend
  Future<void> logout() async {
    try {
      final refresh = await TokenManager.getRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        await _api.post(
          ApiConfig.logout,
          requiresAuth: true,
          body: {'refresh': refresh},
        );
      }
    } catch (_) {
      // Abaikan error saat logout agar user tetap bisa keluar dari aplikasi lokal
    } finally {
      await TokenManager.clear();
    }
  }
}

