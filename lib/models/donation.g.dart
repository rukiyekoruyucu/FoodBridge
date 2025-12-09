// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Donation _$DonationFromJson(Map<String, dynamic> json) => Donation(
  donationId: json['donation_id'] as String,
  itemId: json['item_id'] as String,
  donorUserId: json['donor_user_id'] as String,
  recipientUserId: json['recipient_user_id'] as String,
  status: json['status'] as String,
  createdAt: json['created_at'] as String,
  claimedAt: json['claimed_at'] as String?,
  completedAt: json['completed_at'] as String?,
);

Map<String, dynamic> _$DonationToJson(Donation instance) => <String, dynamic>{
  'donation_id': instance.donationId,
  'item_id': instance.itemId,
  'donor_user_id': instance.donorUserId,
  'recipient_user_id': instance.recipientUserId,
  'status': instance.status,
  'created_at': instance.createdAt,
  'claimed_at': instance.claimedAt,
  'completed_at': instance.completedAt,
};
