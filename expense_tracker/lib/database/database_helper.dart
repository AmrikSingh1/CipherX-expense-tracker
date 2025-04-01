import 'package:expense_tracker/models/transaction_model.dart' as model;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        category TEXT NOT NULL,
        type INTEGER NOT NULL,
        note TEXT
      )
    ''');
  }

  Future<String> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return transaction.id;
  }

  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  Future<List<model.Transaction>> getTransactionsByMonth(int year, int month) async {
    final db = await database;
    
    final startDate = DateTime(year, month, 1);
    final endDate = month < 12 
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);
    
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  Future<Map<String, double>> getCategoryTotals(model.TransactionType type, int year, int month) async {
    final transactions = await getTransactionsByMonth(year, month);
    final filteredTransactions = transactions.where((t) => t.type == type).toList();
    
    final Map<String, double> categoryTotals = {};
    
    for (var transaction in filteredTransactions) {
      if (categoryTotals.containsKey(transaction.category)) {
        categoryTotals[transaction.category] = 
            categoryTotals[transaction.category]! + transaction.amount;
      } else {
        categoryTotals[transaction.category] = transaction.amount;
      }
    }
    
    return categoryTotals;
  }

  Future<double> getTotalAmount(model.TransactionType type, int year, int month) async {
    final transactions = await getTransactionsByMonth(year, month);
    final filteredTransactions = transactions.where((t) => t.type == type).toList();
    
    double total = 0;
    for (var transaction in filteredTransactions) {
      total += transaction.amount;
    }
    
    return total;
  }

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 