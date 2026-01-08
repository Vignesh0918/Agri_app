import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  // Get all products
  static Future<List<Product>> getProducts({
    int skip = 0,
    int limit = 100,
    String? category,
    String? search,
  }) async {
    try {
      String endpoint = '/products/?skip=$skip&limit=$limit';
      if (category != null) endpoint += '&category=$category';
      if (search != null) endpoint += '&search=$search';

      final response = await ApiService.get(endpoint);
      final List<dynamic> productsData = response as List<dynamic>;

      return productsData.map((data) => Product(
        id: data['id'],
        name: data['name'] ?? '',
        description: data['description'],
        category: data['category'] ?? '',
        unitPrice: (data['unit_price'] ?? 0).toDouble(),
        stockQuantity: data['stock_quantity'] ?? 0,
        minStockLevel: data['min_stock_level'] ?? 0,
        supplierName: data['supplier_name'],
        supplierContact: data['supplier_contact'],
        isActive: data['is_active'] ?? true,
        createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
      )).toList();
    } catch (e) {
      print('Failed to fetch products: $e');
      return [];
    }
  }

  // Get product by ID
  static Future<Product?> getProductById(int productId) async {
    try {
      final response = await ApiService.get('/products/$productId');
      return Product(
        id: response['id'],
        name: response['name'] ?? '',
        description: response['description'],
        category: response['category'] ?? '',
        unitPrice: (response['unit_price'] ?? 0).toDouble(),
        stockQuantity: response['stock_quantity'] ?? 0,
        minStockLevel: response['min_stock_level'] ?? 0,
        supplierName: response['supplier_name'],
        supplierContact: response['supplier_contact'],
        isActive: response['is_active'] ?? true,
        createdAt: DateTime.parse(response['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: response['updated_at'] != null ? DateTime.parse(response['updated_at']) : null,
      );
    } catch (e) {
      print('Failed to fetch product: $e');
      return null;
    }
  }

  // Get categories
  static Future<List<String>> getCategories() async {
    try {
      final response = await ApiService.get('/products/categories');
      return List<String>.from(response['categories'] ?? []);
    } catch (e) {
      print('Failed to fetch categories: $e');
      return [];
    }
  }

  // Get low stock products
  static Future<List<ProductStock>> getLowStockProducts() async {
    try {
      final response = await ApiService.get('/products/low-stock');
      final List<dynamic> productsData = response as List<dynamic>;

      return productsData.map((data) => ProductStock(
        name: data['name'] ?? '',
        quantity: data['quantity'] ?? 0,
      )).toList();
    } catch (e) {
      print('Failed to fetch low stock products: $e');
      return [];
    }
  }

  // Create product
  static Future<Product?> createProduct(Product product) async {
    try {
      final productData = {
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'unit_price': product.unitPrice,
        'stock_quantity': product.stockQuantity,
        'min_stock_level': product.minStockLevel,
        'supplier_name': product.supplierName,
        'supplier_contact': product.supplierContact,
      };

      final response = await ApiService.post('/products/', productData);
      return Product(
        id: response['id'],
        name: response['name'] ?? '',
        description: response['description'],
        category: response['category'] ?? '',
        unitPrice: (response['unit_price'] ?? 0).toDouble(),
        stockQuantity: response['stock_quantity'] ?? 0,
        minStockLevel: response['min_stock_level'] ?? 0,
        supplierName: response['supplier_name'],
        supplierContact: response['supplier_contact'],
        isActive: response['is_active'] ?? true,
        createdAt: DateTime.parse(response['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: response['updated_at'] != null ? DateTime.parse(response['updated_at']) : null,
      );
    } catch (e) {
      print('Failed to create product: $e');
      return null;
    }
  }

  // Update product
  static Future<Product?> updateProduct(int productId, Product updatedProduct) async {
    try {
      final productData = {
        'name': updatedProduct.name,
        'description': updatedProduct.description,
        'category': updatedProduct.category,
        'unit_price': updatedProduct.unitPrice,
        'stock_quantity': updatedProduct.stockQuantity,
        'min_stock_level': updatedProduct.minStockLevel,
        'supplier_name': updatedProduct.supplierName,
        'supplier_contact': updatedProduct.supplierContact,
      };

      final response = await ApiService.put('/products/$productId', productData);
      return Product(
        id: response['id'],
        name: response['name'] ?? '',
        description: response['description'],
        category: response['category'] ?? '',
        unitPrice: (response['unit_price'] ?? 0).toDouble(),
        stockQuantity: response['stock_quantity'] ?? 0,
        minStockLevel: response['min_stock_level'] ?? 0,
        supplierName: response['supplier_name'],
        supplierContact: response['supplier_contact'],
        isActive: response['is_active'] ?? true,
        createdAt: DateTime.parse(response['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: response['updated_at'] != null ? DateTime.parse(response['updated_at']) : null,
      );
    } catch (e) {
      print('Failed to update product: $e');
      return null;
    }
  }

  // Delete product
  static Future<bool> deleteProduct(int productId) async {
    try {
      await ApiService.delete('/products/$productId');
      return true;
    } catch (e) {
      print('Failed to delete product: $e');
      return false;
    }
  }

  // Update stock
  static Future<Product?> updateStock(int productId, int quantityChange) async {
    try {
      final response = await ApiService.patch('/products/$productId/stock', {
        'quantity_change': quantityChange,
      });

      return Product(
        id: response['product']['id'],
        name: response['product']['name'] ?? '',
        description: response['product']['description'],
        category: response['product']['category'] ?? '',
        unitPrice: (response['product']['unit_price'] ?? 0).toDouble(),
        stockQuantity: response['product']['stock_quantity'] ?? 0,
        minStockLevel: response['product']['min_stock_level'] ?? 0,
        supplierName: response['product']['supplier_name'],
        supplierContact: response['product']['supplier_contact'],
        isActive: response['product']['is_active'] ?? true,
        createdAt: DateTime.parse(response['product']['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: response['product']['updated_at'] != null ? DateTime.parse(response['product']['updated_at']) : null,
      );
    } catch (e) {
      print('Failed to update stock: $e');
      return null;
    }
  }
}
