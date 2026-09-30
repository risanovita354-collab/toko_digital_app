import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'toko_digital.db');
    return await openDatabase(
      path,
      version: 7, // Versi 7 untuk memperbarui harga produk (Rp 100rb - Rp 190rb)
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS master_products');
        await db.execute('DROP TABLE IF EXISTS local_cart');
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE master_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE local_cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        name TEXT,
        price REAL,
        quantity INTEGER,
        image_url TEXT
      )
    ''');

    // Menambahkan 6 Produk Tumbler dengan harga berkisar Rp 100rb-an (di bawah Rp 200rb)
    await db.insert('master_products', {'name': 'Tumbler Classic Cherry', 'price': 125000.0, 'image_url': 'assets/images/tumbler 1.png'});
    await db.insert('master_products', {'name': 'Tumbler Stainless Ribbon', 'price': 165000.0, 'image_url': 'assets/images/tumbler 2.png'});
    await db.insert('master_products', {'name': 'Tumbler Cute Yellow', 'price': 115000.0, 'image_url': 'assets/images/tumbler 3.png'});
    await db.insert('master_products', {'name': 'Tumbler Pink Handle', 'price': 185000.0, 'image_url': 'assets/images/tumbler 4.png'});
    await db.insert('master_products', {'name': 'Tumbler Minimalist White', 'price': 105000.0, 'image_url': 'assets/images/tumbler 5.png'});
    await db.insert('master_products', {'name': 'Tumbler Metallic Blue', 'price': 145000.0, 'image_url': 'assets/images/tumbler 6.png'});
  }

  static Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('master_products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  static Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('local_cart');
    return List.generate(maps.length, (i) => CartItem.fromMap(maps[i]));
  }

  static Future<void> insertOrUpdateCart(Product product) async {
    final db = await database;
    final existing = await db.query('local_cart', where: 'product_id = ?', whereArgs: [product.id]);

    if (existing.isNotEmpty) {
      int currentQty = existing.first['quantity'] as int;
      await db.update(
        'local_cart',
        {'quantity': currentQty + 1},
        where: 'product_id = ?',
        whereArgs: [product.id],
      );
    } else {
      await db.insert('local_cart', {
        'product_id': product.id,
        'name': product.name,
        'price': product.price,
        'quantity': 1,
        'image_url': product.imageUrl,
      });
    }
  }

  static Future<void> updateQuantity(int id, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await db.delete('local_cart', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update('local_cart', {'quantity': quantity}, where: 'id = ?', whereArgs: [id]);
    }
  }
}