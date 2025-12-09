import 'package:json_annotation/json_annotation.dart';

part 'donation.g.dart';

@JsonSerializable()
class Donation {
  @JsonKey(name: 'donation_id')
  final String donationId;

  @JsonKey(name: 'item_id')
  final String itemId;

  @JsonKey(name: 'donor_user_id')
  final String donorUserId;

  @JsonKey(name: 'recipient_user_id')
  final String recipientUserId;

  final String status;

  @JsonKey(name: 'created_at')
  final String createdAt;
  
  @JsonKey(name: 'claimed_at')
  final String? claimedAt;

  @JsonKey(name: 'completed_at')
  final String? completedAt;

  Donation({
    required this.donationId,
    required this.itemId,
    required this.donorUserId,
    required this.recipientUserId,
    required this.status,
    required this.createdAt,
    this.claimedAt,
    this.completedAt,
  });
  factory Donation.fromJson(Map<String, dynamic> json) => _$DonationFromJson(json);
  Map<String, dynamic> toJson() => _$DonationToJson(this);
}
