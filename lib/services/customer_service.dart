import '../models/customer.dart';
import 'api_service.dart';

class CustomerService {
  // Get all customers
  static Future<List<Customer>> getCustomers({
    int skip = 0,
    int limit = 100,
    String? search,
  }) async {
    try {
      String endpoint = '/customers/?skip=$skip&limit=$limit';
      if (search != null) endpoint += '&search=$search';

      final response = await ApiService.get(endpoint);
      final List<dynamic> customersData = response as List<dynamic>;

      return customersData.map((data) => Customer.fromJson(data)).toList();
    } catch (e) {
      print('Failed to fetch customers: $e');
      return [];
    }
  }

  // Get customer by ID
  static Future<Customer?> getCustomerById(int customerId) async {
    try {
      final response = await ApiService.get('/customers/$customerId');
      return Customer.fromJson(response);
    } catch (e) {
      print('Failed to fetch customer: $e');
      return null;
    }
  }

  // Get customer by phone
  static Future<Customer?> getCustomerByPhone(String phone) async {
    try {
      final response = await ApiService.get('/customers/phone/$phone');
      return Customer.fromJson(response);
    } catch (e) {
      print('Failed to fetch customer by phone: $e');
      return null;
    }
  }

  // Create customer
  static Future<Customer?> createCustomer(Customer customer) async {
    try {
      final customerData = {
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'gst_number': customer.gstNumber,
      };

      final response = await ApiService.post('/customers/', customerData);
      return Customer.fromJson(response);
    } catch (e) {
      print('Failed to create customer: $e');
      return null;
    }
  }

  // Update customer
  static Future<Customer?> updateCustomer(int customerId, Customer updatedCustomer) async {
    try {
      final customerData = {
        'name': updatedCustomer.name,
        'phone': updatedCustomer.phone,
        'email': updatedCustomer.email,
        'address': updatedCustomer.address,
        'gst_number': updatedCustomer.gstNumber,
      };

      final response = await ApiService.put('/customers/$customerId', customerData);
      return Customer.fromJson(response);
    } catch (e) {
      print('Failed to update customer: $e');
      return null;
    }
  }

  // Delete customer
  static Future<bool> deleteCustomer(int customerId) async {
    try {
      await ApiService.delete('/customers/$customerId');
      return true;
    } catch (e) {
      print('Failed to delete customer: $e');
      return false;
    }
  }
}
