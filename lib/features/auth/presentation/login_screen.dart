import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  // 비밀번호 보이기/숨기기 상태 관리 변수
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 에러 메시지가 있으면 스낵바로 표시
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppTheme.danger),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_moon, size: 80, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text(
                "Safety Monitor",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Industrial Safety Management System",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 48),

              // 1. 아이디 입력 필드
              _buildTextField(
                controller: _idController,
                label: "User ID",
                icon: Icons.person,
              ),

              const SizedBox(height: 16),

              // 2. 비밀번호 입력 필드
              _buildTextField(
                controller: _pwController,
                label: "Password",
                icon: Icons.lock,
                isObscure: !_isPasswordVisible, // 상태에 따라 숨김/보임 처리
                suffixIcon: IconButton(
                  icon: Icon(
                    // 상태에 따라 아이콘 변경 (눈 뜸 / 눈 감음)
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    // 클릭 시 상태 토글
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),

              // 로그인 버튼
              if (authState.status == AuthStatus.loading)
                const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final id = _idController.text.trim();
                    final pw = _pwController.text.trim();
                    if (id.isNotEmpty && pw.isNotEmpty) {
                      ref.read(authProvider.notifier).login(id, pw);
                    }
                  },
                  child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 24),
              TextButton(
                  onPressed: () {
                    // 비밀번호 찾기 로직 (추후 구현)
                  },
                  child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.textSecondary))
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon, // 우측 아이콘 파라미터
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        suffixIcon: suffixIcon, // 우측 아이콘 배치
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primary)),
      ),
    );
  }
}