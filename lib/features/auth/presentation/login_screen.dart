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
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  // 비밀번호 보이기/숨기기 상태
  bool _isPasswordVisible = false;

  // 로그인/회원가입 모드 전환
  bool _isLoginMode = true;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 에러 메시지가 있으면 스낵바로 표시
    ref.listen(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.danger,
          ),
        );
      }

      // 회원가입 성공 시 로그인 모드로 전환
      if (previous?.status == AuthStatus.registering &&
          next.status == AuthStatus.unauthenticated &&
          next.errorMessage == null) {
        setState(() {
          _isLoginMode = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
            backgroundColor: AppTheme.success,
          ),
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
              const Icon(Icons.construction, size: 80, color: AppTheme.primary),
              const SizedBox(height: 24),
              const Text(
                "InnoSafe",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Smart Construction Management System",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 48),

              // 로그인/회원가입 모드 표시
              Text(
                _isLoginMode ? "로그인" : "회원가입",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 회원가입 모드일 때만 이름 필드 표시
              if (!_isLoginMode) ...[
                _buildTextField(
                  controller: _nameController,
                  label: "Name",
                  icon: Icons.badge,
                ),
                const SizedBox(height: 16),
              ],

              // 아이디 입력 필드
              _buildTextField(
                controller: _idController,
                label: "User ID",
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력 필드
              _buildTextField(
                controller: _pwController,
                label: "Password",
                icon: Icons.lock,
                isObscure: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 회원가입 모드일 때만 이메일 필드 표시
              if (!_isLoginMode) ...[
                _buildTextField(
                  controller: _emailController,
                  label: "Email (Optional)",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // 로그인/회원가입 버튼
              if (authState.status == AuthStatus.loading ||
                  authState.status == AuthStatus.registering)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_isLoginMode) {
                      // 로그인
                      final id = _idController.text.trim();
                      final pw = _pwController.text.trim();
                      if (id.isNotEmpty && pw.isNotEmpty) {
                        ref.read(authProvider.notifier).login(id, pw);
                      }
                    } else {
                      // 회원가입
                      final id = _idController.text.trim();
                      final pw = _pwController.text.trim();
                      final name = _nameController.text.trim();
                      final email = _emailController.text.trim();

                      if (id.isNotEmpty && pw.isNotEmpty && name.isNotEmpty) {
                        ref.read(authProvider.notifier).register(
                          userId: id,
                          password: pw,
                          name: name,
                          email: email.isNotEmpty ? email : null,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('아이디, 비밀번호, 이름은 필수입니다.'),
                            backgroundColor: AppTheme.danger,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    _isLoginMode ? "LOGIN" : "SIGN UP",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 로그인/회원가입 모드 전환 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLoginMode ? "계정이 없으신가요?" : "이미 계정이 있으신가요?",
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        // 필드 초기화
                        _idController.clear();
                        _pwController.clear();
                        _emailController.clear();
                        _nameController.clear();
                      });
                    },
                    child: Text(
                      _isLoginMode ? "회원가입" : "로그인",
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // 비밀번호 찾기 (로그인 모드에서만 표시)
              if (_isLoginMode)
                TextButton(
                  onPressed: () {
                    // 비밀번호 찾기 로직 (추후 구현)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('비밀번호 찾기 기능은 준비 중입니다.'),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
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
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}