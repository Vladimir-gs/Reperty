/// Constantes globales de la app.
abstract final class AppConstants {
  static const appName = 'Reperty';
  static const groupCodeLength = 5;
  static const groupCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static const adminRoleOwner = 'owner';
  static const adminRoleAdmin = 'admin';
  static const adminRoleMember = 'member';

  static const List<String> adminRoles = [
    adminRoleOwner,
    adminRoleAdmin,
    adminRoleMember,
  ];
}
