import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_error_banner.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _googleBusy = false;
  String _passwordStrength = 'None';
  String? _error;
  String? _pendingEmail;

  static const _googleIcon = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _busy => _submitting || _googleBusy;

  String _strengthFor(String password) {
    if (password.isEmpty) return 'None';
    if (password.length < 6) return 'Weak';
    final hasLetters = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigits = password.contains(RegExp(r'\d'));
    final hasSymbols = password.contains(RegExp(r'[^a-zA-Z\d]'));
    if (password.length >= 8 && hasLetters && hasDigits && hasSymbols) {
      return 'Strong';
    }
    if (hasLetters && (hasDigits || hasSymbols)) return 'Fair';
    return 'Weak';
  }

  void _onPasswordChanged(String value) {
    setState(() => _passwordStrength = _strengthFor(value));
  }

  Future<void> _signUp() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    try {
      final response = await _auth.signUp(
        email: email,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      if (!mounted) return;
      // Supabase returns no session while email confirmation is pending, and
      // returns an unconfirmed user with empty identities when the email is
      // already registered.
      if (response.session == null) {
        final identities = response.user?.identities;
        if (identities != null && identities.isEmpty) {
          setState(() {
            _error =
                'An account with this email already exists. Try signing in instead.';
          });
        } else {
          setState(() => _pendingEmail = email);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.describeError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_busy) return;
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    try {
      final launched = await _auth.signInWithGoogle();
      if (!launched && mounted) {
        setState(() => _error = 'Could not open Google sign-in on this device.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.describeError(e));
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _pendingEmail != null
              ? _buildConfirmationPending(_pendingEmail!)
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildConfirmationPending(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Center(
          child: Image.asset('lib/assets/logo.png', height: 72),
        ),
        const SizedBox(height: 32),
        Container(
          height: 72,
          width: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFCCFBF1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 34,
            color: Color(0xFF0D9488),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Confirm your email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'We sent a confirmation link to '),
              TextSpan(
                text: email,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D9488),
                ),
              ),
              const TextSpan(
                text: '. Open it to activate your account, then sign in.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Didn't get it? Check your spam folder.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0D9488),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: const Text('Back to sign in'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _pendingEmail = null),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('Use a different email'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'lib/assets/logo.png',
              height: 72,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            AuthErrorBanner(
              message: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: _busy ? null : _continueWithGoogle,
            icon: _googleBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : SvgPicture.string(
                    _googleIcon,
                    height: 20,
                    width: 20,
                  ),
            label: Text(
              _googleBusy ? 'Opening Google…' : 'Continue with Google',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.black54),
              foregroundColor: Colors.black87,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or register with email',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          _buildField(
            label: 'First name',
            hint: 'First name',
            controller: _firstNameController,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your first name' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Last name',
            hint: 'Last name',
            controller: _lastNameController,
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.familyName],
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your last name' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Email address',
            hint: 'your@email.com',
            controller: _emailController,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Enter your Password',
            hint: 'Min 8 characters',
            controller: _passwordController,
            enabled: !_busy,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: _onPasswordChanged,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password strength: $_passwordStrength',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            label: 'Confirm password',
            hint: 'Re-enter your password',
            enabled: !_busy,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signUp(),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _busy ? null : _signUp,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              disabledBackgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign Up'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              GestureDetector(
                onTap: _busy
                    ? null
                    : () => Navigator.pushReplacementNamed(context, '/sign-in'),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Color(0xFF0D9488),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    TextEditingController? controller,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Iterable<String>? autofillHints,
    bool enabled = true,
    bool obscureText = false,
    Widget? suffix,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          enabled: enabled,
          obscureText: obscureText,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          cursorColor: const Color(0xFF0D9488),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
