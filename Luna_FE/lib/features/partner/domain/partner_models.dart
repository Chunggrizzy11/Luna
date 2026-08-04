import 'package:equatable/equatable.dart';

class GenerateCodeResponse extends Equatable {
  const GenerateCodeResponse({
    required this.code,
    required this.expiresAt,
  });

  final String code;
  final String expiresAt;

  factory GenerateCodeResponse.fromJson(Map<String, dynamic> json) {
    return GenerateCodeResponse(
      code: json['code'] as String,
      expiresAt: json['expiresAt'] as String,
    );
  }

  @override
  List<Object?> get props => [code, expiresAt];
}

class PairingStatusResponse extends Equatable {
  const PairingStatusResponse({
    required this.isPaired,
    this.partnerName,
    this.pairedAt,
  });

  final bool isPaired;
  final String? partnerName;
  final String? pairedAt;

  factory PairingStatusResponse.fromJson(Map<String, dynamic> json) {
    return PairingStatusResponse(
      isPaired: json['isPaired'] as bool,
      partnerName: json['partnerName'] as String?,
      pairedAt: json['pairedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [isPaired, partnerName, pairedAt];
}

class JoinPairingResponse extends Equatable {
  const JoinPairingResponse({
    required this.paired,
    required this.ownerDeviceId,
  });

  final bool paired;
  final String ownerDeviceId;

  factory JoinPairingResponse.fromJson(Map<String, dynamic> json) {
    return JoinPairingResponse(
      paired: json['paired'] as bool,
      ownerDeviceId: json['ownerDeviceId'] as String,
    );
  }

  @override
  List<Object?> get props => [paired, ownerDeviceId];
}
