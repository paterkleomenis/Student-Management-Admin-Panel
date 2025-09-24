import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';
import '../services/language_service.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  @override
  Widget build(BuildContext context) => Consumer2<LanguageService, ReceiptProvider>(
      builder: (context, langService, receiptProvider, child) => Scaffold(
        appBar: AppBar(
          title: Text(langService.getString('receipts.title')),
        ),
        body: const Center(
          child: Text('Receipts Screen - Under Development'),
        ),
      ),
    );
}
