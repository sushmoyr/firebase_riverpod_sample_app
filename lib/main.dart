import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_riverpod_sample_app/controllers/auth_controler.dart';
import 'package:firebase_riverpod_sample_app/controllers/item_list_controller.dart';
import 'package:firebase_riverpod_sample_app/firebase_options.dart';
import 'package:firebase_riverpod_sample_app/models/item_model.dart';
import 'package:firebase_riverpod_sample_app/repositories/custom_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authControllerState = ref.read(authControllerProvider.notifier);
    final authController = ref.watch(authControllerProvider);

    final itemListFilter = ref.watch(itemListFilterProvider);

    ref.listen(itemListExceptionProvider, (previous, next) {
      final snackBar = SnackBar(content: Text(previous!.message!));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });

    print(authController != null ? 'Signed in' : 'null signing');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          Checkbox(
            value: itemListFilter == ItemListFilter.all
                ? false
                : itemListFilter == ItemListFilter.obtained
                    ? true
                    : null,
            tristate: true,
            onChanged: (value) {
              ItemListFilter filter = ItemListFilter.all;
              switch (value) {
                case true:
                  filter = ItemListFilter.obtained;
                  break;
                case false:
                  filter = ItemListFilter.all;
                  break;
                case null:
                  filter = ItemListFilter.unObtained;
                  break;
              }
              ref.read(itemListFilterProvider.notifier).state = filter;
            },
          ),
        ],
        leading: authController != null
            ? IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  authControllerState.signOut();
                },
              )
            : null,
      ),
      body: const ItemList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddItemDialog.show(context, Item.empty()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

final currentItem = Provider<Item>((ref) => throw UnimplementedError());

class ItemList extends HookConsumerWidget {
  const ItemList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemListState = ref.watch(itemListControllerProvider);
    final filteredItemList = ref.watch(filteredItemListProvider);
    return itemListState.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.add,
                  size: 36,
                  color: Colors.grey,
                ),
                Text('Tap + to add an item')
              ],
            ),
          );
        } else {
          return ListView.builder(
            itemCount: filteredItemList.length,
            itemBuilder: (ctx, idx) {
              final item = filteredItemList[idx];
              return ProviderScope(
                overrides: [
                  currentItem.overrideWithValue(item),
                ],
                child: ItemTile(),
              );
            },
          );
        }
      },
      error: (e, s) => ItemListError(
          message: e is CustomException ? e.message! : 'Something went wrong'),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class ItemTile extends HookConsumerWidget {
  const ItemTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Item item = ref.watch(currentItem);

    return ListTile(
      key: ValueKey(item.id),
      title: Text(item.name),
      onLongPress: () {
        ref
            .read(itemListControllerProvider.notifier)
            .deleteItem(itemId: item.id!);
      },
      onTap: () => AddItemDialog.show(context, item),
      trailing: Checkbox(
        value: item.obtained,
        onChanged: (val) => ref
            .read(itemListControllerProvider.notifier)
            .updateItem(updatedItem: item.copyWith(obtained: val ?? false)),
      ),
    );
  }
}

class ItemListError extends HookConsumerWidget {
  final String message;

  const ItemListError({super.key, required this.message});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        const SizedBox(height: 20.0),
        ElevatedButton(
          onPressed: () {
            ref
                .read(itemListControllerProvider.notifier)
                .retrieveItems(isRefreshing: true);
          },
          child: Text("Retry"),
        ),
      ],
    );
  }
}

class AddItemDialog extends HookConsumerWidget {
  const AddItemDialog({
    Key? key,
    required this.item,
  }) : super(key: key);

  final Item item;

  static show(BuildContext context, Item item) => showDialog(
        context: context,
        builder: (_) => AddItemDialog(item: item),
      );

  bool get isUpdating => item.id != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController(text: item.name);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isUpdating ? Colors.orange : Theme.of(context).primaryColor,
              ),
              onPressed: () {
                isUpdating
                    ? ref.read(itemListControllerProvider.notifier).updateItem(
                        updatedItem:
                            item.copyWith(name: textController.text.trim()))
                    : ref
                        .read(itemListControllerProvider.notifier)
                        .addItem(name: textController.text.trim());
                Navigator.pop(context);
              },
              child: Text(isUpdating ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
