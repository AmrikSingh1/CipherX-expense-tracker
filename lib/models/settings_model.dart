import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettings {
  final bool enabled;
  final bool budgetAlerts;
  final bool recurringExpenseReminders;

  NotificationSettings({
    this.enabled = true,
    this.budgetAlerts = true,
    this.recurringExpenseReminders = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'budgetAlerts': budgetAlerts,
      'recurringExpenseReminders': recurringExpenseReminders,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return NotificationSettings();
    
    return NotificationSettings(
      enabled: map['enabled'] ?? true,
      budgetAlerts: map['budgetAlerts'] ?? true,
      recurringExpenseReminders: map['recurringExpenseReminders'] ?? true,
    );
  }
}

class PrivacySettings {
  final bool requireAuthentication;
  final bool hideAmounts;

  PrivacySettings({
    this.requireAuthentication = true,
    this.hideAmounts = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'requireAuthentication': requireAuthentication,
      'hideAmounts': hideAmounts,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PrivacySettings();
    
    return PrivacySettings(
      requireAuthentication: map['requireAuthentication'] ?? true,
      hideAmounts: map['hideAmounts'] ?? false,
    );
  }
}

class SettingsModel {
  final String userId; // Document ID
  final String defaultCurrency;
  final String dateFormat;
  final String theme;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final DateTime updatedAt;

  SettingsModel({
    required this.userId,
    this.defaultCurrency = 'USD',
    this.dateFormat = 'MM/DD/YYYY',
    this.theme = 'light',
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    DateTime? updatedAt,
  }) : 
    notificationSettings = notificationSettings ?? NotificationSettings(),
    privacySettings = privacySettings ?? PrivacySettings(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'defaultCurrency': defaultCurrency,
      'dateFormat': dateFormat,
      'theme': theme,
      'notificationSettings': notificationSettings.toMap(),
      'privacySettings': privacySettings.toMap(),
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'defaultCurrency': defaultCurrency,
      'dateFormat': dateFormat,
      'theme': theme,
      'notificationSettings': notificationSettings.toMap(),
      'privacySettings': privacySettings.toMap(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map, String userId) {
    return SettingsModel(
      userId: userId,
      defaultCurrency: map['defaultCurrency'] ?? 'USD',
      dateFormat: map['dateFormat'] ?? 'MM/DD/YYYY',
      theme: map['theme'] ?? 'light',
      notificationSettings: NotificationSettings.fromMap(
        map['notificationSettings'] as Map<String, dynamic>?
      ),
      privacySettings: PrivacySettings.fromMap(
        map['privacySettings'] as Map<String, dynamic>?
      ),
      updatedAt: map['updatedAt'] != null 
                ? (map['updatedAt'] is DateTime 
                  ? map['updatedAt'] 
                  : (map['updatedAt'] is Timestamp 
                    ? map['updatedAt'].toDate() 
                    : DateTime.now())) 
                : DateTime.now(),
    );
  }

  factory SettingsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SettingsModel(
      userId: doc.id,
      defaultCurrency: data['defaultCurrency'] ?? 'USD',
      dateFormat: data['dateFormat'] ?? 'MM/DD/YYYY',
      theme: data['theme'] ?? 'light',
      notificationSettings: NotificationSettings.fromMap(
        data['notificationSettings'] as Map<String, dynamic>?
      ),
      privacySettings: PrivacySettings.fromMap(
        data['privacySettings'] as Map<String, dynamic>?
      ),
      updatedAt: data['updatedAt'] != null 
                ? (data['updatedAt'] is Timestamp 
                  ? data['updatedAt'].toDate() 
                  : DateTime.now()) 
                : DateTime.now(),
    );
  }

  // Create a default settings object for new users
  factory SettingsModel.defaultSettings(String userId) {
    return SettingsModel(
      userId: userId,
      defaultCurrency: 'USD',
      dateFormat: 'MM/DD/YYYY',
      theme: 'light',
      notificationSettings: NotificationSettings(),
      privacySettings: PrivacySettings(),
    );
  }
} 