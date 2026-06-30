import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:krm_admin/models/vendor_model.dart';
import 'package:krm_admin/screens/add_vendor_screen.dart';
import 'package:krm_admin/services/auth_service.dart';
import 'package:krm_admin/services/vendor_service.dart';
import 'package:flutter/foundation.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  final VendorService _vendorService = VendorService();
  final AuthService _authService = AuthService();
  
  List<VendorModel> _vendors = [];
  List<VendorModel> _filteredVendors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _selectedCategoryFilter = 'All';
  String _selectedTraderFilter = 'All';
  String _selectedVendorFilter = 'All';
  String _selectedMobileFilter = 'All';
  bool _showFilters = false;

  List<String> get uniqueCategories {
    final categories = _vendors.map((v) => v.vendorCategory).toSet().where((c) => c.isNotEmpty).toList();
    categories.sort();
    return ['All', ...categories];
  }

  List<String> get uniqueTraders {
    final traders = _vendors.map((v) => v.vendorTrader).toSet().where((t) => t.isNotEmpty).toList();
    traders.sort();
    return ['All', ...traders];
  }

  List<String> get uniqueVendors {
    final vendorsList = _vendors.map((v) => v.vendorName).toSet().where((v) => v.isNotEmpty).toList();
    vendorsList.sort();
    return ['All', ...vendorsList];
  }

  List<String> get uniqueMobiles {
    final mobiles = _vendors.map((v) => v.vendorMobile).toSet().where((m) => m.isNotEmpty).toList();
    mobiles.sort();
    return ['All', ...mobiles];
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filterStatus = 'All';
      _selectedCategoryFilter = 'All';
      _selectedTraderFilter = 'All';
      _selectedVendorFilter = 'All';
      _selectedMobileFilter = 'All';
      _applyFilter();
    });
  }

  // Pagination parameters
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final vendors = await _vendorService.fetchVendors();
    
    if (mounted) {
      setState(() {
        _vendors = vendors;
        _isLoading = false;
        // Keep active search/filter chips on refresh
        _filteredVendors = vendors.where((vendor) {
          bool matchesSearch = _searchQuery.isEmpty ||
              vendor.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              vendor.vendorMobile.contains(_searchQuery) ||
              vendor.vendorCategory.toLowerCase().contains(_searchQuery.toLowerCase());
          
          bool matchesStatus = _filterStatus == 'All' ||
              vendor.vendorStatus.toLowerCase() == _filterStatus.toLowerCase();
          
          bool matchesCategory = _selectedCategoryFilter == 'All' ||
              vendor.vendorCategory == _selectedCategoryFilter;

          bool matchesTrader = _selectedTraderFilter == 'All' ||
              vendor.vendorTrader == _selectedTraderFilter;

          bool matchesVendor = _selectedVendorFilter == 'All' ||
              vendor.vendorName == _selectedVendorFilter;

          bool matchesMobile = _selectedMobileFilter == 'All' ||
              vendor.vendorMobile == _selectedMobileFilter;

          return matchesSearch && matchesStatus && matchesCategory && matchesTrader && matchesVendor && matchesMobile;
        }).toList();
        _currentPage = 1;
        if (vendors.isEmpty) {
          _errorMessage = 'No vendors found';
        }
      });
    }
  }

  Future<void> _refreshVendors() async {
    await _fetchVendors();
  }

  void _applyFilter() {
    setState(() {
      _currentPage = 1; // Reset to page 1 on filter/search change
      _filteredVendors = _vendors.where((vendor) {
        bool matchesSearch = _searchQuery.isEmpty ||
            vendor.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            vendor.vendorMobile.contains(_searchQuery) ||
            vendor.vendorCategory.toLowerCase().contains(_searchQuery.toLowerCase());
        
        bool matchesStatus = _filterStatus == 'All' ||
            vendor.vendorStatus.toLowerCase() == _filterStatus.toLowerCase();
        
        bool matchesCategory = _selectedCategoryFilter == 'All' ||
            vendor.vendorCategory == _selectedCategoryFilter;

        bool matchesTrader = _selectedTraderFilter == 'All' ||
            vendor.vendorTrader == _selectedTraderFilter;

        bool matchesVendor = _selectedVendorFilter == 'All' ||
            vendor.vendorName == _selectedVendorFilter;

        bool matchesMobile = _selectedMobileFilter == 'All' ||
            vendor.vendorMobile == _selectedMobileFilter;

        return matchesSearch && matchesStatus && matchesCategory && matchesTrader && matchesVendor && matchesMobile;
      }).toList();
    });
  }

  // Fetch subcategories for a given category name
  Future<List<String>> _fetchSubCategories(String categoryName) async {
    try {
      final token = await _authService.getToken();
      final encoded = Uri.encodeComponent(categoryName);
      final res = await http.get(
        Uri.parse('https://kmrlive.in/public/api/panel-fetch-sub-category/$encoded'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List categorySub = data['categorySub'] ?? [];
        return categorySub
            .map((s) => s['category_sub_name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      return [];
    }
  }

  // Fetch full details of a single vendor (including sub-products)
  Future<Map<String, dynamic>?> _fetchVendorDetail(int id) async {
    return await _vendorService.fetchVendorById(id);
  }

  // Pagination helpers
  int get totalPages => (_filteredVendors.length / _itemsPerPage).ceil();

  List<VendorModel> get currentPagedVendors {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredVendors.length) return [];
    if (endIndex > _filteredVendors.length) endIndex = _filteredVendors.length;
    return _filteredVendors.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refreshVendors,
        color: const Color(0xFF6C3CE1),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C3CE1)),
                ),
              )
            : Column(
                children: [
                  // Top Summary Stats Cards
                  _buildSummaryCards(),

                  // Search and Filters Bar
                  _buildSearchAndFilterBar(),

                  // List Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildContentHeader(context),
                          const SizedBox(height: 14),
                          if (_errorMessage != null && _filteredVendors.isEmpty)
                            _buildEmptyState()
                          else if (screenWidth < 700)
                            _buildMobileListView()
                          else
                            _buildDesktopTableView(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Pagination Footer
                  if (totalPages > 1) _buildPaginationFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalCount = _vendors.length;
    final activeCount = _vendors.where((v) => v.vendorStatus.toLowerCase() == 'active').length;
    final totalProducts = _vendors.fold<int>(0, (sum, v) => sum + v.vendorNoOfProducts);

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    Widget card1 = _buildStatCard('Total Vendors', totalCount.toString(), const Color(0xFF6C3CE1), Icons.storefront_rounded);
    Widget card2 = _buildStatCard('Active Vendors', activeCount.toString(), const Color(0xFF10B981), Icons.check_circle_outline_rounded);
    Widget card3 = _buildStatCard('Total Products', totalProducts.toString(), const Color(0xFFEF4444), Icons.inventory_2_outlined);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          isDesktop ? SizedBox(width: 250, child: card1) : Expanded(child: card1),
          const SizedBox(width: 10),
          isDesktop ? SizedBox(width: 250, child: card2) : Expanded(child: card2),
          const SizedBox(width: 10),
          isDesktop ? SizedBox(width: 250, child: card3) : Expanded(child: card3),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.08), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded, color: Colors.grey),
                ),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by vendor name, category, or mobile...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilter();
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedVendorFilter != 'All' || _selectedMobileFilter != 'All' || _selectedCategoryFilter != 'All' || _selectedTraderFilter != 'All')
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20, color: Colors.grey),
                    onPressed: _clearFilters,
                  ),
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                    color: _showFilters ? const Color(0xFF6C3CE1) : Colors.grey,
                  ),
                  tooltip: 'Filter options',
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_showFilters) ...[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedVendorFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Vendor',
                                  labelStyle: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedVendorFilter = val;
                                      _applyFilter();
                                    });
                                  }
                                },
                                items: uniqueVendors.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedMobileFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile',
                                  labelStyle: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedMobileFilter = val;
                                      _applyFilter();
                                    });
                                  }
                                },
                                items: uniqueMobiles.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategoryFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  labelStyle: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCategoryFilter = val;
                                      _applyFilter();
                                    });
                                  }
                                },
                                items: uniqueCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedTraderFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Trader',
                                  labelStyle: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedTraderFilter = val;
                                      _applyFilter();
                                    });
                                  }
                                },
                                items: uniqueTraders.map((t) => DropdownMenuItem(value: t, child: Text(t == 'All' ? 'All' : 'Trader $t'))).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          // Filter Chips
          Row(
            children: [
              _buildFilterChip('All', 'All'),
              const SizedBox(width: 8),
              _buildFilterChip('Active', 'Active'),
              const SizedBox(width: 8),
              _buildFilterChip('Inactive', 'Inactive'),
              const Spacer(),
              Text(
                '${_filteredVendors.length} vendors',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterStatus == value;
    Color chipColor = isSelected ? const Color(0xFFF5F0FF) : Colors.white;
    Color borderAndTextColor = isSelected ? const Color(0xFF6C3CE1) : Colors.grey.shade300;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFilter();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: chipColor,
      checkmarkColor: const Color(0xFF6C3CE1),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6C3CE1) : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderAndTextColor,
          width: 1.2,
        ),
      ),
    );
  }

  Widget _buildContentHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Vendor Rates Master',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        Row(
          children: [
        
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddVendorScreen(title: 'Create Vendor Rate'),
                  ),
                );
                if (result == true) {
                  _fetchVendors();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C3CE1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Add Rate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'No vendors found',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          if (_searchQuery.isNotEmpty || _filterStatus != 'All')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterStatus = 'All';
                  _applyFilter();
                });
              },
              child: const Text('Clear filters', style: TextStyle(color: Color(0xFF6C3CE1), fontWeight: FontWeight.bold)),
            )
          else if (_vendors.isEmpty)
            TextButton(
              onPressed: _fetchVendors,
              child: const Text('Retry Fetching', style: TextStyle(color: Color(0xFF6C3CE1), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // Tablet/Desktop Table View
  Widget _buildDesktopTableView() {
    final paged = currentPagedVendors;
    final startIndex = (_currentPage - 1) * _itemsPerPage;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(60),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.5),
          6: FixedColumnWidth(100),
          7: FixedColumnWidth(120),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            children: [
              _buildTableHeaderCell('SL No'),
              _buildTableHeaderCell('Vendor'),
              _buildTableHeaderCell('Mobile'),
              _buildTableHeaderCell('Category'),
              _buildTableHeaderCell('Trader'),
              _buildTableHeaderCell('No of Products'),
              _buildTableHeaderCell('Status'),
              _buildTableHeaderCell('Actions'),
            ],
          ),
          ...List.generate(paged.length, (index) {
            final vendor = paged[index];
            final traderName = vendor.vendorTrader == '1'
                ? 'Live Rate'
                : (vendor.vendorTrader == '2'
                    ? 'Spot Rate'
                    : (vendor.vendorTrader == '3' ? 'Rates' : 'Trader ${vendor.vendorTrader}'));
            
            return TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('${startIndex + index + 1}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      vendor.vendorName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(vendor.vendorMobile, style: const TextStyle(fontSize: 13)),
                  ),
                ),
               

TableCell(
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: defaultTargetPlatform == TargetPlatform.android
            ? const Color(0xFFF5F0FF)
            : Colors.transparent,
        border: Border.all(
          color: defaultTargetPlatform == TargetPlatform.android
              ? const Color(0xFFE9DEFF)
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        vendor.vendorCategory,
        style: const TextStyle(
          color: Color(0xFF6C3CE1),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(traderName, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${vendor.vendorNoOfProducts} items', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildStatusBadge(vendor),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildActionBtn(context, vendor),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Mobile List
  Widget _buildMobileListView() {
    final paged = currentPagedVendors;
    final startIndex = (_currentPage - 1) * _itemsPerPage;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: paged.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final vendor = paged[index];
        final traderName = vendor.vendorTrader == '1'
            ? 'Live Rate'
            : (vendor.vendorTrader == '2'
                ? 'Spot Rate'
                : (vendor.vendorTrader == '3' ? 'Rates' : 'Trader ${vendor.vendorTrader}'));
        final isActive = vendor.vendorStatus.toLowerCase() == 'active';
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${startIndex + index + 1}. ${vendor.vendorName}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(vendor),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F0FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  vendor.vendorCategory,
                                  style: const TextStyle(
                                    color: Color(0xFF6C3CE1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  traderName,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${vendor.vendorNoOfProducts} items',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.phone_iphone_rounded, size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 6),
                                  Text(
                                    vendor.vendorMobile,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              _buildActionBtn(context, vendor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VendorModel vendor) {
    final status = vendor.vendorStatus;
    final isActive = status.toLowerCase() == 'active';
    return InkWell(
      onTap: () => _toggleVendorStatus(vendor),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3), width: 0.5),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? const Color(0xFF047857) : const Color(0xFFBE123C),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _toggleVendorStatus(VendorModel vendor) async {
    final originalStatus = vendor.vendorStatus;
    final newStatus = originalStatus == 'Active' ? 'Inactive' : 'Active';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C3CE1))),
    );

    try {
      final vendorDetails = await _vendorService.fetchVendorById(vendor.id);
      
      if (vendorDetails == null || vendorDetails['vendor'] == null) {
        throw Exception('Failed to retrieve vendor details');
      }

      final vendorMap = vendorDetails['vendor'] as Map<String, dynamic>;
      final List<dynamic> rawSubs = vendorDetails['vendorSub'] ?? [];

      final productsPayload = rawSubs.map((sub) {
        return <String, dynamic>{
          'id': sub['id'],
          'vendor_product_category_sub': sub['vendor_product_category_sub'] ?? '',
          'vendor_product': sub['vendor_product'] ?? '',
          'vendor_product_size': sub['vendor_product_size'] ?? '',
          'vendor_product_rate': sub['vendor_product_rate'] ?? '',
          'vendor_product_status': sub['vendor_product_status'] ?? 'Active',
          'vendor_trader': sub['vendor_trader'] ?? '1',
        };
      }).toList();

      final payload = <String, dynamic>{
        'vendor_name': vendorMap['vendor_name'] ?? vendor.vendorName,
        'vendor_mobile': vendorMap['vendor_mobile'] ?? vendor.vendorMobile,
        'vendor_email': vendorMap['vendor_email'] ?? '',
        'vendor_address': vendorMap['vendor_address'] ?? '',
        'vendor_city': vendorMap['vendor_city'] ?? '',
        'vendor_category': vendorMap['vendor_category'] ?? vendor.vendorCategory,
        'vendor_trader': vendorMap['vendor_trader']?.toString() ?? vendor.vendorTrader,
        'vendor_no_of_products': productsPayload.length,
        'vendor_status': newStatus,
        'vendorProduct_sub_data': productsPayload,
      };

      final result = await _vendorService.updateVendor(vendor.id, payload);

      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        setState(() {
          vendor.vendorStatus = newStatus;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${vendor.vendorName} status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }



Widget _buildActionBtn(BuildContext context, VendorModel vendor) {
  final bool isDesktop =
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  return InkWell(
    onTap: () => _showEditRatesDialog(context, vendor),
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
  color: defaultTargetPlatform == TargetPlatform.android
      ? const Color(0xFFF5F0FF)
      : Colors.transparent,
  border: Border.all(
    color: defaultTargetPlatform == TargetPlatform.android
        ? const Color(0xFFE9DEFF)
        : Colors.transparent,
  ),
  borderRadius: BorderRadius.circular(8),
),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.edit_outlined,
            size: 14,
            color: Color(0xFF6C3CE1),
          ),
          if (!isDesktop) ...[
            const SizedBox(width: 4),
            const Text(
              'Edit Rates',
              style: TextStyle(
                color: Color(0xFF6C3CE1),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildPaginationFooter() {
    final total = _filteredVendors.length;
    if (total == 0) return const SizedBox.shrink();

    final startIndex = (_currentPage - 1) * _itemsPerPage + 1;
    var endIndex = startIndex + _itemsPerPage - 1;
    if (endIndex > total) endIndex = total;

    final isMobile = MediaQuery.of(context).size.width < 500;

    final infoText = Text(
      'Showing $startIndex-$endIndex of $total vendors',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w600,
      ),
    );

    final navControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageNavButton(
          Icons.arrow_back_ios_new_rounded,
          _currentPage > 1,
          () {
            setState(() {
              _currentPage--;
            });
          },
        ),
        const SizedBox(width: 12),
        Text(
          'Page $_currentPage of $totalPages',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 12),
        _buildPageNavButton(
          Icons.arrow_forward_ios_rounded,
          _currentPage < totalPages,
          () {
            setState(() {
              _currentPage++;
            });
          },
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: isMobile
          ? Column(
              children: [
                infoText,
                const SizedBox(height: 10),
                navControls,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                infoText,
                navControls,
              ],
            ),
    );
  }

  Widget _buildPageNavButton(IconData icon, bool enabled, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: enabled ? Colors.grey.shade200 : Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 14,
            color: enabled ? const Color(0xFF6C3CE1) : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  // "+ Add Rate" Dialog Flow
  void _showAddRateDialog(BuildContext context) {
    VendorModel? selectedVendor;
    List<String> subcategories = [];
    String? selectedSubcategory;
    final formKey = GlobalKey<FormState>();
    
    final productCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    
    bool isCategoryLoading = false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_chart_rounded, color: Color(0xFF6C3CE1), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Product Rate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Define new vendor rate details',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Searchable Vendor Selector Trigger
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Select Vendor *',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            _showVendorSelector(context, (vendor) async {
                              setDialogState(() {
                                selectedVendor = vendor;
                                isCategoryLoading = true;
                                subcategories = [];
                                selectedSubcategory = null;
                              });

                              final list = await _fetchSubCategories(vendor.vendorCategory);
                              
                              setDialogState(() {
                                subcategories = list;
                                isCategoryLoading = false;
                              });
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedVendor != null
                                        ? '${selectedVendor!.vendorName} (${selectedVendor!.vendorCategory})'
                                        : 'Click to select a vendor...',
                                    style: TextStyle(
                                      color: selectedVendor != null ? Colors.black87 : Colors.grey.shade500,
                                      fontSize: 14,
                                      fontWeight: selectedVendor != null ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 28),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (selectedVendor != null) ...[
                          // Subcategory Selection
                          const Row(
                            children: [
                              SizedBox(width: 4),
                              Text(
                                'Sub Category *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          isCategoryLoading
                              ? const LinearProgressIndicator(color: Color(0xFF6C3CE1))
                              : subcategories.isEmpty
                                  ? TextFormField(
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      decoration: InputDecoration(
                                        hintText: 'Enter sub category name...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      onChanged: (val) => selectedSubcategory = val.trim(),
                                      validator: (value) => value == null || value.trim().isEmpty ? 'Subcategory is required' : null,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: selectedSubcategory,
                                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                                        iconSize: 28,
                                        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                                        style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                                        items: subcategories.map((sub) {
                                          return DropdownMenuItem(
                                            value: sub,
                                            child: Text(
                                              sub,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setDialogState(() {
                                            selectedSubcategory = val;
                                          });
                                        },
                                        validator: (value) => value == null ? 'Please select a sub category' : null,
                                      ),
                                    ),
                          const SizedBox(height: 18),

                          // Product Name
                          const Row(
                            children: [
                              SizedBox(width: 4),
                              Text(
                                'Product Name *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: productCtrl,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Enter Product Name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Product name is required' : null,
                          ),
                          const SizedBox(height: 18),

                          // Size
                          const Row(
                            children: [
                              SizedBox(width: 4),
                              Text(
                                'Size *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: sizeCtrl,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Enter Size',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.straighten_outlined, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Size is required' : null,
                          ),
                          const SizedBox(height: 18),

                          // Rate
                          const Row(
                            children: [
                              SizedBox(width: 4),
                              Text(
                                'Rate (₹) *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Enter Rate',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Rate is required';
                              if (double.tryParse(value) == null) return 'Enter a valid rate';
                              return null;
                            },
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: (selectedVendor == null || isSaving)
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSaving = true);

                            final fullDetails = await _fetchVendorDetail(selectedVendor!.id);
                            if (fullDetails == null) {
                              if (context.mounted) {
                                setDialogState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to fetch existing vendor details'), backgroundColor: Colors.red),
                                );
                              }
                              return;
                            }

                            final vendor = fullDetails['vendor'] ?? {};
                            final List subs = fullDetails['vendorSub'] ?? [];

                            final List<Map<String, dynamic>> productsPayload = subs.map((sub) {
                              return {
                                'id': sub['id'],
                                'vendor_product_category_sub': sub['vendor_product_category_sub'] ?? '',
                                'vendor_product': sub['vendor_product'] ?? '',
                                'vendor_product_size': sub['vendor_product_size'] ?? '',
                                'vendor_product_rate': sub['vendor_product_rate']?.toString() ?? '0',
                                'vendor_product_status': sub['vendor_product_status'] ?? 'Active',
                                'vendor_trader': sub['vendor_trader']?.toString() ?? '1',
                              };
                            }).toList();

                            productsPayload.add({
                              'id': null,
                              'vendor_product_category_sub': selectedSubcategory,
                              'vendor_product': productCtrl.text.trim(),
                              'vendor_product_size': sizeCtrl.text.trim(),
                              'vendor_product_rate': rateCtrl.text.trim(),
                              'vendor_product_status': 'Active',
                              'vendor_trader': vendor['vendor_trader']?.toString() ?? '1',
                            });

                            final updatePayload = {
                              'vendor_name': vendor['vendor_name'] ?? '',
                              'vendor_mobile': vendor['vendor_mobile'] ?? '',
                              'vendor_email': vendor['vendor_email'] ?? '',
                              'vendor_address': vendor['vendor_address'] ?? '',
                              'vendor_city': vendor['vendor_city'] ?? '',
                              'vendor_category': vendor['vendor_category'] ?? '',
                              'vendor_trader': vendor['vendor_trader']?.toString() ?? '1',
                              'vendor_no_of_products': productsPayload.length,
                              'vendor_status': vendor['vendor_status'] ?? 'Active',
                              'vendorProduct_sub_data': productsPayload,
                            };

                            final response = await _vendorService.updateVendor(selectedVendor!.id, updatePayload);

                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                              Navigator.pop(context); // Close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ?? 'Rate added successfully', style: const TextStyle(color: Colors.white)),
                                  backgroundColor: response['success'] ? Colors.green : Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (response['success']) {
                                _fetchVendors();
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3CE1),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF6C3CE1).withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Search selector to select a vendor
  void _showVendorSelector(BuildContext context, Function(VendorModel) onSelect) {
    String searchVal = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _vendors.where((v) {
              return v.vendorName.toLowerCase().contains(searchVal.toLowerCase()) ||
                  v.vendorCategory.toLowerCase().contains(searchVal.toLowerCase());
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose Vendor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) {
                      setSheetState(() => searchVal = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search vendor name or category...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: filtered.isEmpty
                        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No vendors match search query', style: TextStyle(color: Colors.grey))))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final vendor = filtered[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFF5F0FF),
                                    child: Text(
                                      vendor.vendorName.isNotEmpty ? vendor.vendorName[0].toUpperCase() : 'V',
                                      style: const TextStyle(color: Color(0xFF6C3CE1), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(vendor.vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(
                                    'Category: ${vendor.vendorCategory} • Trader: ${vendor.vendorTrader == '1' ? 'Live' : (vendor.vendorTrader == '2' ? 'Spot' : (vendor.vendorTrader == '3' ? 'Rates' : 'Trader ${vendor.vendorTrader}'))}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onTap: () {
                                    onSelect(vendor);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6C3CE1)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const Text(':  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Edit rates list dialog
  void _showEditRatesDialog(BuildContext context, VendorModel vendorShort) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C3CE1))),
    );

    final details = await _fetchVendorDetail(vendorShort.id);
    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load vendor details'), backgroundColor: Colors.red),
      );
      return;
    }

    final vendor = details['vendor'] ?? {};
    final List subs = details['vendorSub'] ?? [];
    String vendorStatus = vendor['vendor_status']?.toString() ?? 'Active';

    final List<Map<String, dynamic>> productRows = [];
    for (var sub in subs) {
      productRows.add({
        'id': sub['id'],
        'category_sub': sub['vendor_product_category_sub']?.toString() ?? '',
        'product': sub['vendor_product']?.toString() ?? '',
        'size': sub['vendor_product_size']?.toString() ?? '',
        'rate': TextEditingController(text: sub['vendor_product_rate']?.toString() ?? '0'),
        'status': sub['vendor_product_status']?.toString() ?? 'Active',
      });
    }

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6C3CE1), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendorShort.vendorName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Edit Vendor Rates Master',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 650,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vendor Status Master Card
                        _buildSectionHeader('Vendor Status', Icons.toggle_on_outlined),
                        Card(
                          elevation: 0,
                          color: vendorStatus == 'Active' ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: vendorStatus == 'Active' ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  vendorStatus == 'Active' ? 'Vendor Status: Active' : 'Vendor Status: Inactive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: vendorStatus == 'Active' ? const Color(0xFF047857) : const Color(0xFFBE123C),
                                  ),
                                ),
                                Switch(
                                  value: vendorStatus == 'Active',
                                  activeColor: const Color(0xFF10B981),
                                  activeTrackColor: const Color(0xFFD1FAE5),
                                  inactiveThumbColor: const Color(0xFFEF4444),
                                  inactiveTrackColor: const Color(0xFFFEE2E2),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      vendorStatus = val ? 'Active' : 'Inactive';
                                      for (var row in productRows) {
                                        row['status'] = val ? 'Active' : 'Inactive';
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Personal Info
                        _buildSectionHeader('Personal Information', Icons.person_outline_rounded),
                        Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow('Vendor Name', vendor['vendor_name'] ?? 'N/A'),
                                _buildInfoRow('Mobile', vendor['vendor_mobile'] ?? 'N/A'),
                                _buildInfoRow('Email', vendor['vendor_email'] ?? 'N/A'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location Details
                        _buildSectionHeader('Location Details', Icons.location_on_outlined),
                        Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow('City', vendor['vendor_city'] ?? 'N/A'),
                                _buildInfoRow('Address', vendor['vendor_address'] ?? 'N/A'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Business Details
                        _buildSectionHeader('Business Information', Icons.business_center_outlined),
                        Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow('Category', vendor['vendor_category'] ?? 'N/A'),
                                _buildInfoRow(
                                  'Trader',
                                  vendor['vendor_trader'] == '1'
                                      ? 'Live Rate'
                                      : (vendor['vendor_trader'] == '2'
                                          ? 'Spot Rate'
                                          : (vendor['vendor_trader'] == '3'
                                              ? 'Rates'
                                              : 'Trader ${vendor['vendor_trader']}')),
                                ),
                                _buildInfoRow('Status', vendor['vendor_status'] ?? 'N/A'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Products Details
                        _buildSectionHeader('Vendor Products', Icons.rate_review_outlined),
                        const SizedBox(height: 8),
                        
                        productRows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text('No products listed under this vendor', style: TextStyle(color: Colors.grey))),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: productRows.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final row = productRows[index];
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F0FF),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                row['category_sub'].toString(),
                                                style: const TextStyle(
                                                  color: Color(0xFF6C3CE1),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Product Name', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    row['product'].toString(),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Size', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    row['size'].toString(),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: row['rate'],
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                decoration: InputDecoration(
                                                  labelText: 'Rate (₹) *',
                                                  filled: true,
                                                  fillColor: Colors.grey.shade50,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                ),
                                                validator: (value) {
                                                  if (value == null || value.trim().isEmpty) return 'Required';
                                                  if (double.tryParse(value) == null) return 'Invalid';
                                                  return null;
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSaving = true);

                            final List<Map<String, dynamic>> productsPayload = productRows.map((row) {
                              return {
                                if (row['id'] != null) 'id': row['id'],
                                'vendor_product_category_sub': row['category_sub'],
                                'vendor_product': row['product'],
                                'vendor_product_size': row['size'],
                                'vendor_product_rate': (row['rate'] as TextEditingController).text.trim(),
                                'vendor_product_status': row['status'],
                                'vendor_trader': vendor['vendor_trader']?.toString() ?? '1',
                              };
                            }).toList();

                            final updatePayload = {
                              'vendor_name': vendor['vendor_name'] ?? '',
                              'vendor_mobile': vendor['vendor_mobile'] ?? '',
                              'vendor_email': vendor['vendor_email'] ?? '',
                              'vendor_address': vendor['vendor_address'] ?? '',
                              'vendor_city': vendor['vendor_city'] ?? '',
                              'vendor_category': vendor['vendor_category'] ?? '',
                              'vendor_trader': vendor['vendor_trader']?.toString() ?? '1',
                              'vendor_no_of_products': productsPayload.length,
                              'vendor_status': vendorStatus,
                              'vendorProduct_sub_data': productsPayload,
                            };

                            final response = await _vendorService.updateVendor(vendorShort.id, updatePayload);

                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                              Navigator.pop(context); // Close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ?? 'Rates updated successfully', style: const TextStyle(color: Colors.white)),
                                  backgroundColor: response['success'] ? Colors.green : Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (response['success']) {
                                _fetchVendors();
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3CE1),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF6C3CE1).withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}