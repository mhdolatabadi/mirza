import 'package:bank_sms_parser/bank_sms_parser.dart';
import 'package:flutter/material.dart';

import '../services/categories.dart';

class TransactionEdit {
  final String category;

  /// Null when the transaction has no account to name.
  final String? accountName;

  const TransactionEdit(this.category, this.accountName);
}

/// Bottom sheet to pick a transaction's category and name its account.
class TransactionSheet extends StatefulWidget {
  final Transaction transaction;
  final String category;
  final String? accountName;

  const TransactionSheet({super.key, required this.transaction, required this.category, this.accountName});

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  late String _category = widget.category;
  late final _accountName = TextEditingController(text: widget.accountName);

  @override
  void dispose() {
    _accountName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.transaction.account;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('دسته‌بندی', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in categories)
                ChoiceChip(label: Text(c), selected: c == _category, onSelected: (_) => setState(() => _category = c)),
            ],
          ),
          if (account != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _accountName,
              decoration: InputDecoration(labelText: 'نام حساب $account', hintText: 'مثلاً اسم بانک'),
            ),
          ],
          const SizedBox(height: 12),
          Text(widget.transaction.raw, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              TransactionEdit(_category, account == null ? null : _accountName.text),
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }
}
