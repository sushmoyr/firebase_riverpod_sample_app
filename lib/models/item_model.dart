import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

@freezed
class Item with _$Item {
  const factory Item({
    String? id,
    required String name,
    @Default(false) bool obtained,
  }) = _Item;

  const Item._();

  factory Item.empty() => Item(name: '');

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  factory Item.fromDocument(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    return Item.fromJson(data).copyWith(id: doc.id);
  }

  Map<String, dynamic> toDocument() => toJson()..remove('id');
}
