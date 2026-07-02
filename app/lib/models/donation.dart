import 'package:json_annotation/json_annotation.dart';

part 'donation.g.dart';

@JsonSerializable()
class Donation {
  final int id;

  @JsonKey(name: 'item_id')
  final int itemId;

  @JsonKey(name: 'donor_id')
  final int donorId;

  @JsonKey(name: 'recipient_id')
  final int recipientId;

  final String type; // DONATION | TRADE
  final String status; // PENDING | ACCEPTED | COMPLETED | CANCELLED ...

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'accepted_at')
  final String? acceptedAt;

  @JsonKey(name: 'completed_at')
  final String? completedAt;

  @JsonKey(name: 'donor_confirmed_at')
  final String? donorConfirmedAt;

  @JsonKey(name: 'recipient_confirmed_at')
  final String? recipientConfirmedAt;

  // --------- Extra fields returned by some endpoints (joins) ---------
  // /donations/me -> LEFT JOIN items
  @JsonKey(name: 'item_name')
  final String? itemName;

  @JsonKey(name: 'item_description')
  final String? itemDescription;

  @JsonKey(name: 'item_image_url')
  final String? itemImageUrl;

  @JsonKey(name: 'item_status')
  final String? itemStatus;

  @JsonKey(name: 'item_lat')
  final double? itemLat;

  @JsonKey(name: 'item_lng')
  final double? itemLng;

  @JsonKey(name: 'item_address')
  final String? itemAddress;

  // /donations/items/:itemId/requests -> JOIN users (recipient)
  @JsonKey(name: 'full_name')
  final String? requesterFullName;

  @JsonKey(name: 'avatar_url')
  final String? requesterAvatarUrl;

  Donation({
    required this.id,
    required this.itemId,
    required this.donorId,
    required this.recipientId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.donorConfirmedAt,
    this.recipientConfirmedAt,
    this.itemName,
    this.itemDescription,
    this.itemImageUrl,
    this.itemStatus,
    this.itemLat,
    this.itemLng,
    this.itemAddress,
    this.requesterFullName,
    this.requesterAvatarUrl,
  });

  factory Donation.fromJson(Map<String, dynamic> json) =>
      _$DonationFromJson(json);

  Map<String, dynamic> toJson() => _$DonationToJson(this);
}
