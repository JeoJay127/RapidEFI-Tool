import 'dart:typed_data';

class MiscSecurity {
  bool allowSetDefault;
  int apECID;
  bool authRestart;
  bool blacklistAppleUpdate;
  String dmgLoading;
  bool enablePassword;
  int exposeSensitiveData;
  int haltLevel;
  Uint8List? passwordHash;
  Uint8List? passwordSalt;
  int scanPolicy;
  String secureBootModel;
  String vault;

  MiscSecurity({
    this.allowSetDefault = false,
    this.apECID = 0,
    this.authRestart = false,
    this.blacklistAppleUpdate = true,
    this.dmgLoading = 'Signed',
    this.enablePassword = false,
    this.exposeSensitiveData = 6,
    this.haltLevel = 2147483648,
    this.passwordHash,
    this.passwordSalt,
    this.scanPolicy = 17760515,
    this.secureBootModel = 'Default',
    this.vault = 'Secure',
  });
  MiscSecurity copyWith({
    bool? allowSetDefault,
    int? apECID,
    bool? authRestart,
    bool? blacklistAppleUpdate,
    String? dmgLoading,
    bool? enablePassword,
    int? exposeSensitiveData,
    int? haltLevel,
    Uint8List? passwordHash,
    Uint8List? passwordSalt,
    int? scanPolicy,
    String? secureBootModel,
    String? vault,
  }) {
    return MiscSecurity(
      allowSetDefault: allowSetDefault ?? this.allowSetDefault,
      apECID: apECID ?? this.apECID,
      authRestart: authRestart ?? this.authRestart,
      blacklistAppleUpdate: blacklistAppleUpdate ?? this.blacklistAppleUpdate,
      dmgLoading: dmgLoading ?? this.dmgLoading,
      enablePassword: enablePassword ?? this.enablePassword,
      exposeSensitiveData: exposeSensitiveData ?? this.exposeSensitiveData,
      haltLevel: haltLevel ?? this.haltLevel,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      scanPolicy: scanPolicy ?? this.scanPolicy,
      secureBootModel: secureBootModel ?? this.secureBootModel,
      vault: vault ?? this.vault,
    );
  }

  factory MiscSecurity.fromJson(Map<String, dynamic> json) {
    return MiscSecurity(
      allowSetDefault: json['AllowSetDefault'] ?? false,
      apECID: json['ApECID'] ?? 0,
      authRestart: json['AuthRestart'] ?? false,
      blacklistAppleUpdate: json['BlacklistAppleUpdate'] ?? true,
      dmgLoading: json['DmgLoading'] ?? 'Signed',
      enablePassword: json['EnablePassword'] ?? false,
      exposeSensitiveData: json['ExposeSensitiveData'] ?? 6,
      haltLevel: json['HaltLevel'] ?? 2147483648,
      passwordHash: json['PasswordHash'] != null
          ? Uint8List.fromList(List<int>.from(json['PasswordHash']))
          : null,
      passwordSalt: json['PasswordSalt'] != null
          ? Uint8List.fromList(List<int>.from(json['PasswordSalt']))
          : null,
      scanPolicy: json['ScanPolicy'] ?? 17760515,
      secureBootModel: json['SecureBootModel'] ?? 'Default',
      vault: json['Vault'] ?? 'Secure',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'AllowSetDefault': allowSetDefault,
      'ApECID': apECID,
      'AuthRestart': authRestart,
      'BlacklistAppleUpdate': blacklistAppleUpdate,
      'DmgLoading': dmgLoading,
      'EnablePassword': enablePassword,
      'ExposeSensitiveData': exposeSensitiveData,
      'HaltLevel': haltLevel,
      'PasswordHash': passwordHash,
      'PasswordSalt': passwordSalt,
      'ScanPolicy': scanPolicy,
      'SecureBootModel': secureBootModel,
      'Vault': vault,
    };
  }
}
