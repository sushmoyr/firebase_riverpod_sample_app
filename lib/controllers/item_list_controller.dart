import 'package:firebase_riverpod_sample_app/models/item_model.dart';
import 'package:firebase_riverpod_sample_app/repositories/custom_exception.dart';
import 'package:firebase_riverpod_sample_app/repositories/item_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth_controler.dart';

final itemListExceptionProvider = StateProvider<CustomException?>((_) => null);

final itemListControllerProvider =
    StateNotifierProvider<ItemListController, AsyncValue<List<Item>>>((ref) {
  final user = ref.watch(authControllerProvider);
  return ItemListController(ref.read, user?.uid);
});

class ItemListController extends StateNotifier<AsyncValue<List<Item>>> {
  final Reader _read;
  final String? userId;

  ItemListController(this._read, this.userId)
      : super(const AsyncValue.loading()) {
    if (userId != null) {
      retrieveItems();
    }
  }

  Future<void> retrieveItems({bool isRefreshing = false}) async {
    if (isRefreshing) {
      state = const AsyncValue.loading();
    }

    try {
      final items =
          await _read(itemRepositoryProvider).retrieveItems(userId: userId!);
      if (mounted) {
        state = AsyncValue.data(items);
      }
    } on CustomException catch (e, s) {
      state = AsyncError(e, stackTrace: s);
    }
  }

  Future<void> addItem({required String name, bool obtained = false}) async {
    try {
      final item = Item(name: name, obtained: obtained);
      final itemId = await _read(itemRepositoryProvider).createItem(
        userId: userId!,
        item: item,
      );
      state.whenData(
        (items) => state = AsyncData(
          items
            ..add(
              item.copyWith(id: itemId),
            ),
        ),
      );
    } on CustomException catch (e, s) {
      _read(itemListExceptionProvider.notifier).state = e;
    }
  }

  Future<void> updateItem({required Item updatedItem}) async {
    try {
      await _read(itemRepositoryProvider)
          .updateItem(userId: userId!, item: updatedItem);
      state.whenData(
        (items) => state = AsyncData([
          for (final item in items)
            (item.id == updatedItem.id) ? updatedItem : item
        ]),
      );
    } on CustomException catch (e, s) {
      _read(itemListExceptionProvider.notifier).state = e;
    }
  }

  Future<void> deleteItem({required String itemId}) async {
    try {
      await _read(itemRepositoryProvider)
          .deleteItem(userId: userId!, itemId: itemId);
      state.whenData(
        (items) => state =
            AsyncData(items..removeWhere((element) => element.id == itemId)),
      );
    } on CustomException catch (e, s) {
      _read(itemListExceptionProvider.notifier).state = e;
    }
  }
}
