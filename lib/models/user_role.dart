enum UserRole {
  blindUser,
  caretaker,
  unselected;

  static UserRole fromString(String? value) {
    if (value == 'blind_user') return UserRole.blindUser;
    if (value == 'caretaker') return UserRole.caretaker;
    return UserRole.unselected;
  }

  String toStorageString() {
    switch (this) {
      case UserRole.blindUser:
        return 'blind_user';
      case UserRole.caretaker:
        return 'caretaker';
      case UserRole.unselected:
        return 'unselected';
    }
  }

  bool get isConfigured => this != UserRole.unselected;
}
