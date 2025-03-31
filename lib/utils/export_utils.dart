import 'dart:io';
import 'package:csv/csv.dart';
import 'package:expense_tracker/models/transaction_model.dart' as model;
// import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportUtils {
  static Future<String?> exportTransactionsToCSV(List<model.Transaction> transactions) async {
    try {
      // Check and request storage permission
      bool hasPermission = await _checkStoragePermission();
      if (!hasPermission) {
        return "Storage permission denied";
      }

      // Create CSV data
      List<List<dynamic>> csvData = [
        ['ID', 'Title', 'Amount', 'Date', 'Category', 'Type', 'Notes'] // Header
      ];

      // Add transaction data
      for (var transaction in transactions) {
        csvData.add([
          transaction.id,
          transaction.title,
          transaction.amount.toString(),
          DateFormat('yyyy-MM-dd').format(transaction.date),
          transaction.category,
          transaction.type == model.TransactionType.income ? 'Income' : 'Expense',
          transaction.note ?? '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get directory to save file
      String path = await _getExportDirectory();
      String filename = 'expense_tracker_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      String filePath = '$path/$filename';

      // Write to file
      final File file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      return "Error exporting data: $e";
    }
  }

  static Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS has a different permission model
      return true;
    }
    return false;
  }

  static Future<String> _getExportDirectory() async {
    try {
      // Try to use downloads directory first
      Directory? directory;
      
      if (Platform.isAndroid) {
        // For Android, use external storage directory
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        return directory.path;
      }
      
      // Fallback to documents directory
      directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      // Fallback to temporary directory
      final directory = await getTemporaryDirectory();
      return directory.path;
    }
  }
} 