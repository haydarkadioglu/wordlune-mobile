import 'package:flutter/material.dart';

class SearchListsDialog extends StatefulWidget {
  final Function(String query) onSearchChanged;
  final String currentQuery;

  const SearchListsDialog({
    super.key,
    required this.onSearchChanged,
    this.currentQuery = '',
  });

  @override
  State<SearchListsDialog> createState() => _SearchListsDialogState();
}

class _SearchListsDialogState extends State<SearchListsDialog> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.currentQuery);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Lists'),
      content: TextField(
        controller: _searchController,
        onChanged: widget.onSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Enter list name...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
        ),
        autofocus: true,
        onSubmitted: (_) => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSearchChanged('');
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
