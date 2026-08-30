import 'package:local_auth/local_auth.dart';

/// Biometric unlock seam. Tests use [AlwaysAllowAuthService].
abstract class AuthService {
  Future<bool> isBiometricAvailable();
  Future<bool> authenticate();
}

class LocalAuthServiceImpl implements AuthService {
  LocalAuthServiceImpl() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isBiometricAvailable() async {
    final supported = await _auth.isDeviceSupported();
    if (!supported) return false;
    final enrolled = await _auth.canCheckBiometrics;
    return enrolled;
  }

  @override
  Future<bool> authenticate() {
    return _auth.authenticate(
      localizedReason: 'Unlock Nurture',
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }
}

class AlwaysAllowAuthService implements AuthService {
  AlwaysAllowAuthService({this.available = true, this.result = true});

  final bool available;
  final bool result;

  @override
  Future<bool> isBiometricAvailable() async => available;

  @override
  Future<bool> authenticate() async => result;
}
