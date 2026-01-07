import 'dart:convert';

class UserProfileModel {
  String? uid;
  String userName;
  String companyName;
  String companyAddress;
  String mobileNumber;
  String email;
  String gstNo;
  String panNo;
  String? cstNo;
  String? vatNo;
  String? iecNo;
  String bankName;
  String branch;
  String accountNo;
  String ifscCode;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserProfileModel({
    this.uid,
    required this.userName,
    required this.companyName,
    required this.companyAddress,
    required this.mobileNumber,
    required this.email,
    required this.gstNo,
    required this.panNo,
    this.cstNo,
    this.vatNo,
    this.iecNo,
    required this.bankName,
    required this.branch,
    required this.accountNo,
    required this.ifscCode,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userName': userName,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'mobileNumber': mobileNumber,
      'email': email,
      'gstNo': gstNo,
      'panNo': panNo,
      'cstNo': cstNo ?? '',
      'vatNo': vatNo ?? '',
      'iecNo': iecNo ?? '',
      'bankName': bankName,
      'branch': branch,
      'accountNo': accountNo,
      'ifscCode': ifscCode,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      uid: json['uid'],
      userName: json['userName'] ?? '',
      companyName: json['companyName'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
      gstNo: json['gstNo'] ?? '',
      panNo: json['panNo'] ?? '',
      cstNo: json['cstNo'],
      vatNo: json['vatNo'],
      iecNo: json['iecNo'],
      bankName: json['bankName'] ?? '',
      branch: json['branch'] ?? '',
      accountNo: json['accountNo'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  UserProfileModel copyWith({
    String? uid,
    String? userName,
    String? companyName,
    String? companyAddress,
    String? mobileNumber,
    String? email,
    String? gstNo,
    String? panNo,
    String? cstNo,
    String? vatNo,
    String? iecNo,
    String? bankName,
    String? branch,
    String? accountNo,
    String? ifscCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      userName: userName ?? this.userName,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      gstNo: gstNo ?? this.gstNo,
      panNo: panNo ?? this.panNo,
      cstNo: cstNo ?? this.cstNo,
      vatNo: vatNo ?? this.vatNo,
      iecNo: iecNo ?? this.iecNo,
      bankName: bankName ?? this.bankName,
      branch: branch ?? this.branch,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

