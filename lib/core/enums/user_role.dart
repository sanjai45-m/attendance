enum UserRole {
  admin,
  employee;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.employee,
    );
  }
}
