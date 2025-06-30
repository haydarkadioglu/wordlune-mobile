import 'package:flutter/material.dart';
import '../../models/word_list.dart';

class DeleteListDialog extends StatefulWidget {
  final WordList list;
  final Function() onDelete;

  const DeleteListDialog({
    super.key,
    required this.list,
    required this.onDelete,
  });

  @override
  State<DeleteListDialog> createState() => _DeleteListDialogState();
}

class _DeleteListDialogState extends State<DeleteListDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete List'),
      content: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            const TextSpan(text: 'Are you sure you want to delete "'),
            TextSpan(
              text: widget.list.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '"? This will also delete all '),
            TextSpan(
              text: '${widget.list.wordCount} words',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' in this list. This action cannot be undone.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isDeleting ? null : _deleteList,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _deleteList() async {
    setState(() => _isDeleting = true);

    try {
      await widget.onDelete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('List "${widget.list.name}" deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting list: $e')),
        );
      }
    }
  }
}
