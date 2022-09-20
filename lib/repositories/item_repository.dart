import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_riverpod_sample_app/general_providers.dart';
import 'package:firebase_riverpod_sample_app/models/item_model.dart';
import 'package:firebase_riverpod_sample_app/repositories/custom_exception.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../extensions/firebase_firestore_extension.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) => ItemRepository(ref.read));

abstract class BaseItemRepository {
  Future<List<Item>> retrieveItems({required String userId});

  Future<String> createItem({required String userId, required Item item});

  Future<void> updateItem({required String userId, required Item item});

  Future<void> deleteItem({required String userId, required String itemId});
}

class ItemRepository implements BaseItemRepository {
  final Reader _read;

  const ItemRepository(this._read);

  @override
  Future<List<Item>> retrieveItems({required String userId}) async {
    try {
      final snap = await _read(firebaseFireStoreProvider)
          .userListRef(userId)
          .get();
      return snap.docs.map((e) => Item.fromDocument(e)).toList();
    } on FirebaseAuthException catch (e) {
      throw CustomException(e.message);
    }
  }

  @override
  Future<String> createItem({
    required String userId,
    required Item item,
  }) async {
    try {
      final docRef = await _read(firebaseFireStoreProvider)
          .userListRef(userId)
          .add(item.toDocument());
      return docRef.id;
    } on FirebaseAuthException catch (e) {
      throw CustomException(e.message);
    }
  }

  @override
  Future<void> updateItem({
    required String userId,
    required Item item,
  }) async {
    try {
      await _read(firebaseFireStoreProvider)
          .userListRef(userId)
          .doc(item.id)
          .update(item.toDocument());
    } on FirebaseAuthException catch (e) {
      throw CustomException(e.message);
    }
  }

  @override
  Future<void> deleteItem({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _read(firebaseFireStoreProvider)
          .userListRef(userId)
          .doc(itemId)
          .delete();
    } on FirebaseAuthException catch (e) {
      throw CustomException(e.message);
    }
  }
}
