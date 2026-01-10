import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import 'stock_list_screen.dart';
import 'stock_form_screen.dart';
import 'customer_list_screen.dart';
import 'reports_screen.dart';
import 'transactions/transactions_home_screen.dart';
import 'invoices/invoice_history_screen.dart';
import 'auth/login_screen.dart';

import 'low_stock_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, this.userName = "Shop Owner"});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataService _dataService = DataService();
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _statsFuture = _dataService.getDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "AgriShop",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.logout_rounded, color: colorScheme.primary, size: 20),
              tooltip: 'Logout',
              onPressed: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data available"));
          }

          final stats = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await _statsFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "Hello, ${widget.userName}",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    "Here is what's happening today",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SUMMARY CARDS
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: "Stock",
                          value: stats.totalStock.toStringAsFixed(0),
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LowStockDetailsScreen()),
                          ).then((_) => _loadData()),
                          child: _buildStatCard(
                            title: "Low Stock",
                            value: stats.lowStockItems.toString(),
                            icon: Icons.warning_amber_rounded,
                            color: const Color(0xFFD32F2F),
                            isWarning: stats.lowStockItems > 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWideStatCard(
                    title: "Total Customers",
                    value: stats.totalCustomers.toString(),
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF006064),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    "Quick Navigation",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildNavigationRow(
                    context,
                    [
                      _NavOption(
                        title: "Daily Tx",
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.blue[700]!,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsHomeScreen())).then((_) => _loadData()),
                      ),
                      _NavOption(
                        title: "Invoices",
                        icon: Icons.receipt_rounded,
                        color: Colors.purple[700]!,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceHistoryScreen())).then((_) => _loadData()),
                      ),
                      _NavOption(
                        title: "Inventory",
                        icon: Icons.store_rounded,
                        color: Colors.orange[800]!,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockListScreen())).then((_) => _loadData()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildNavigationRow(
                    context,
                    [
                      _NavOption(
                        title: "Customers",
                        icon: Icons.contact_page_rounded,
                        color: Colors.teal[700]!,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen())).then((_) => _loadData()),
                      ),
                      _NavOption(
                        title: "Reports",
                        icon: Icons.analytics_rounded,
                        color: Colors.indigo[700]!,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())).then((_) => _loadData()),
                      ),
                      _NavOption(
                        title: "Settings",
                        icon: Icons.settings_rounded,
                        color: Colors.grey[700]!,
                        onTap: () {}, // Future implementation
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StockFormScreen()),
          );
          if (result == true) _loadData();
        },
        elevation: 4,
        highlightElevation: 8,
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("New Stock", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWarning ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isWarning ? color.withOpacity(0.2) : Colors.green.shade50,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(BuildContext context, List<_NavOption> options) {
    return Row(
      children: options.map((opt) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt == options.last ? 0 : 12,
            ),
            child: InkWell(
              onTap: opt.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade50),
                ),
                child: Column(
                  children: [
                    Icon(opt.icon, color: opt.color, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      opt.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NavOption {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _NavOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
