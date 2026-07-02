// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Donation _$DonationFromJson(Map<String, dynamic> json) => Donation(
  id: (json['id'] as num).toInt(),
  itemId: (json['item_id'] as num).toInt(),
  donorId: (json['donor_id'] as num).toInt(),
  recipientId: (json['recipient_id'] as num).toInt(),
  type: json['type'] as String,
  status: json['status'] as String,
  createdAt: json['created_at'] as String,
  acceptedAt: json['accepted_at'] as String?,
  completedAt: json['completed_at'] as String?,
  donorConfirmedAt: json['donor_confirmed_at'] as String?,
  recipientConfirmedAt: json['recipient_confirmed_at'] as String?,
  itemName: json['item_name'] as String?,
  itemDescription: json['item_description'] as String?,
  itemImageUrl: json['item_image_url'] as String?,
  itemStatus: json['item_status'] as String?,
  itemLat: (json['item_lat'] as num?)?.toDouble(),
  itemLng: (json['item_lng'] as num?)?.toDouble(),
  itemAddress: json['item_address'] as String?,
  requesterFullName: json['full_name'] as String?,
  requesterAvatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$DonationToJson(Donation instance) => <String, dynamic>{
  'id': instance.id,
  'item_id': instance.itemId,
  'donor_id': instance.donorId,
  'recipient_id': instance.recipientId,
  'type': instance.type,
  'status': instance.status,
  'created_at': instance.createdAt,
  'accepted_at': instance.acceptedAt,
  'completed_at': instance.completedAt,
  'donor_confirmed_at': instance.donorConfirmedAt,
  'recipient_confirmed_at': instance.recipientConfirmedAt,
  'item_name': instance.itemName,
  'item_description': instance.itemDescription,
  'item_image_url': instance.itemImageUrl,
  'item_status': instance.itemStatus,
  'item_lat': instance.itemLat,
  'item_lng': instance.itemLng,
  'item_address': instance.itemAddress,
  'full_name': instance.requesterFullName,
  'avatar_url': instance.requesterAvatarUrl,
};
