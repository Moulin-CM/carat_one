import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsModel {
  // Tax Rates
  double cgstRate = 0.75;
  double sgstRate = 0.75;
  double igstRate = 1.5;

  // Invoice Numbering
  String invoiceNumberPrefix = '';
  int startingInvoiceNumber = 1;
  String invoiceNumberFormat = '{prefix}{number}'; // {prefix}{number} or {number} or custom

  // Default Invoice Terms
  String defaultTerms = '';

  // App Preferences
  bool enableNotifications = true;
  bool autoSaveDraft = true;

  AppSettingsModel();

  AppSettingsModel.fromJson(Map<String, dynamic> json)
      : cgstRate = (json['cgstRate'] ?? 0.75).toDouble(),
        sgstRate = (json['sgstRate'] ?? 0.75).toDouble(),
        igstRate = (json['igstRate'] ?? 1.5).toDouble(),
        invoiceNumberPrefix = json['invoiceNumberPrefix'] ?? '',
        startingInvoiceNumber = json['startingInvoiceNumber'] ?? 1,
        invoiceNumberFormat = json['invoiceNumberFormat'] ?? '{prefix}{number}',
        defaultTerms = json['defaultTerms'] ?? '',
        enableNotifications = json['enableNotifications'] ?? true,
        autoSaveDraft = json['autoSaveDraft'] ?? true;

  Map<String, dynamic> toJson() => {
        'cgstRate': cgstRate,
        'sgstRate': sgstRate,
        'igstRate': igstRate,
        'invoiceNumberPrefix': invoiceNumberPrefix,
        'startingInvoiceNumber': startingInvoiceNumber,
        'invoiceNumberFormat': invoiceNumberFormat,
        'defaultTerms': defaultTerms,
        'enableNotifications': enableNotifications,
        'autoSaveDraft': autoSaveDraft,
      };

  AppSettingsModel copyWith({
    double? cgstRate,
    double? sgstRate,
    double? igstRate,
    String? invoiceNumberPrefix,
    int? startingInvoiceNumber,
    String? invoiceNumberFormat,
    String? defaultTerms,
    bool? enableNotifications,
    bool? autoSaveDraft,
  }) {
    return AppSettingsModel()
      ..cgstRate = cgstRate ?? this.cgstRate
      ..sgstRate = sgstRate ?? this.sgstRate
      ..igstRate = igstRate ?? this.igstRate
      ..invoiceNumberPrefix = invoiceNumberPrefix ?? this.invoiceNumberPrefix
      ..startingInvoiceNumber = startingInvoiceNumber ?? this.startingInvoiceNumber
      ..invoiceNumberFormat = invoiceNumberFormat ?? this.invoiceNumberFormat
      ..defaultTerms = defaultTerms ?? this.defaultTerms
      ..enableNotifications = enableNotifications ?? this.enableNotifications
      ..autoSaveDraft = autoSaveDraft ?? this.autoSaveDraft;
  }
}

