import 'package:flutter/material.dart';
import 'package:krm_admin/models/vendor_live_model.dart';
import 'package:krm_admin/services/vendor_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final VendorService _vendorService = VendorService();
  List<VendorLiveModel> _liveItems = [];
  List<VendorLiveModel> _filteredItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _selectedVendorFilter = 'All';
  String _selectedCategoryFilter = 'All';
  String _selectedTraderFilter = 'All';
  bool _showFilters = false;

  List<String> get uniqueVendors {
    final vendors = _liveItems.map((item) => item.vendorName).toSet().where((v) => v.isNotEmpty).toList();
    vendors.sort();
    return ['All', ...vendors];
  }

  List<String> get uniqueCategories {
    final categories = _liveItems.map((item) => item.vendorProductCategory).toSet().where((c) => c.isNotEmpty).toList();
    categories.sort();
    return ['All', ...categories];
  }

  List<String> get uniqueTraders {
    final traders = _liveItems.map((item) => item.vendorTrader).toSet().where((t) => t.isNotEmpty).toList();
    traders.sort();
    return ['All', ...traders];
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filterStatus = 'All';
      _selectedVendorFilter = 'All';
      _selectedCategoryFilter = 'All';
      _selectedTraderFilter = 'All';
      _applyFilter();
    });
  }

  // Pagination parameters
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchLiveItems();
  }

  Future<void> _fetchLiveItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final items = await _vendorService.fetchVendorLiveList();

    if (mounted) {
      setState(() {
        _liveItems = items;
        // Keep active filters and search terms active on refresh
        _filteredItems = items.where((item) {
          bool matchesSearch = _searchQuery.isEmpty ||
              item.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.vendorProductCategorySub.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.vendorProduct.toLowerCase().contains(_searchQuery.toLowerCase());
          
          bool matchesStatus = _filterStatus == 'All' ||
              item.vendorProductStatus.toLowerCase() == _filterStatus.toLowerCase();
          
          bool matchesVendor = _selectedVendorFilter == 'All' ||
              item.vendorName == _selectedVendorFilter;

          bool matchesCategory = _selectedCategoryFilter == 'All' ||
              item.vendorProductCategory == _selectedCategoryFilter;

          bool matchesTrader = _selectedTraderFilter == 'All' ||
              item.vendorTrader == _selectedTraderFilter;

          return matchesSearch && matchesStatus && matchesVendor && matchesCategory && matchesTrader;
        }).toList();
        _isLoading = false;
        _currentPage = 1;
        if (items.isEmpty) {
          _errorMessage = 'No live updates found';
        }
      });
    }
  }

  Future<void> _refreshLiveItems() async {
    await _fetchLiveItems();
  }

  void _applyFilter() {
    setState(() {
      _currentPage = 1; // Reset to page 1 on filter/search change
      _filteredItems = _liveItems.where((item) {
        bool matchesSearch = _searchQuery.isEmpty ||
            item.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.vendorProductCategorySub.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.vendorProduct.toLowerCase().contains(_searchQuery.toLowerCase());
        
        bool matchesStatus = _filterStatus == 'All' ||
            item.vendorProductStatus.toLowerCase() == _filterStatus.toLowerCase();
        
        bool matchesVendor = _selectedVendorFilter == 'All' ||
            item.vendorName == _selectedVendorFilter;

        bool matchesCategory = _selectedCategoryFilter == 'All' ||
            item.vendorProductCategory == _selectedCategoryFilter;

        bool matchesTrader = _selectedTraderFilter == 'All' ||
            item.vendorTrader == _selectedTraderFilter;

        return matchesSearch && matchesStatus && matchesVendor && matchesCategory && matchesTrader;
      }).toList();
    });
  }

  // Pagination helpers
  int get totalPages => (_filteredItems.length / _itemsPerPage).ceil();

  List<VendorLiveModel> get currentPagedItems {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredItems.length) return [];
    if (endIndex > _filteredItems.length) endIndex = _filteredItems.length;
    return _filteredItems.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refreshLiveItems,
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
                          if (_errorMessage != null && _filteredItems.isEmpty)
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
    final total = _liveItems.length;
    final active = _liveItems.where((v) => v.vendorProductStatus.toLowerCase() == 'active').length;
    final inactive = _liveItems.where((v) => v.vendorProductStatus.toLowerCase() == 'inactive').length;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total Products', total.toString(), const Color(0xFF6C3CE1), Icons.live_tv_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard('Active Rates', active.toString(), const Color(0xFF10B981), Icons.trending_up_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _buildStatCard('Inactive Rates', inactive.toString(), const Color(0xFFEF4444), Icons.trending_flat_rounded)),
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
          // Search input
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
                      hintText: 'Search by vendor, subcategory, or product...',
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
                '${_filteredItems.length} items',
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
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'No live updates found',
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
          else if (_liveItems.isEmpty)
            TextButton(
              onPressed: _fetchLiveItems,
              child: const Text('Retry Fetching', style: TextStyle(color: Color(0xFF6C3CE1), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // Tablet/Desktop Horizontal Table
  Widget _buildDesktopTableView() {
    final paged = currentPagedItems;
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
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(3),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(2),
          7: FixedColumnWidth(100),
          8: FixedColumnWidth(90),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Table Headers
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            children: [
              _buildTableHeaderCell('SL No'),
              _buildTableHeaderCell('Vendor'),
              _buildTableHeaderCell('Sub Category'),
              _buildTableHeaderCell('Product'),
              _buildTableHeaderCell('Size'),
              _buildTableHeaderCell('Rate'),
              _buildTableHeaderCell('DateTime'),
              _buildTableHeaderCell('Status'),
              _buildTableHeaderCell('Actions'),
            ],
          ),
          // Rows
          ...List.generate(paged.length, (index) {
            final item = paged[index];
            final dateTimeStr = '${item.vendorProductUpdatedDate} ${item.vendorProductUpdatedTime}';
            
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
                      item.vendorName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.vendorProductCategorySub, 
                        style: const TextStyle(color: Color(0xFF6C3CE1), fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(item.vendorProduct, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(item.vendorProductSize, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '₹${item.vendorProductRate}', 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6C3CE1))
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      dateTimeStr.trim().isEmpty ? 'N/A' : dateTimeStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildStatusBadge(item),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildActionBtn(context, item),
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
    final paged = currentPagedItems;
    final startIndex = (_currentPage - 1) * _itemsPerPage;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: paged.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = paged[index];
        final dateTimeStr = '${item.vendorProductUpdatedDate} ${item.vendorProductUpdatedTime}';
        final isActive = item.vendorProductStatus.toLowerCase() == 'active';
        
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
                                  '${startIndex + index + 1}. ${item.vendorName}',
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
                              _buildStatusBadge(item),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.vendorProduct,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F0FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.vendorProductCategorySub,
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
                                  'Size: ${item.vendorProductSize}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '₹${item.vendorProductRate}',
                                style: const TextStyle(
                                  color: Color(0xFF6C3CE1),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateTimeStr.trim().isEmpty ? 'N/A' : dateTimeStr,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              _buildActionBtn(context, item),
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

  Widget _buildStatusBadge(VendorLiveModel item) {
    final status = item.vendorProductStatus;
    final isActive = status.toLowerCase() == 'active';
    return InkWell(
      onTap: () => _toggleLiveStatus(item),
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

  Future<void> _toggleLiveStatus(VendorLiveModel item) async {
    final originalStatus = item.vendorProductStatus;
    final newStatus = originalStatus.toLowerCase() == 'active' ? 'Inactive' : 'Active';

    setState(() {
      item.vendorProductStatus = newStatus;
    });

    try {
      final result = await _vendorService.updateVendorLive(item.id, {
        'vendor_product': item.vendorProduct,
        'vendor_product_size': item.vendorProductSize,
        'vendor_product_rate': item.vendorProductRate.toString(),
        'vendor_product_status': newStatus,
      });

      if (!result['success']) {
        setState(() {
          item.vendorProductStatus = originalStatus;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: ${result['message']}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.vendorProduct} status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        item.vendorProductStatus = originalStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Widget _buildActionBtn(BuildContext context, VendorLiveModel item) {
    return InkWell(
      onTap: () => _showEditDialog(context, item),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          border: Border.all(color: const Color(0xFFE9DEFF)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, size: 14, color: Color(0xFF6C3CE1)),
            SizedBox(width: 4),
            Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFF6C3CE1),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final total = _filteredItems.length;
    if (total == 0) return const SizedBox.shrink();

    final startIndex = (_currentPage - 1) * _itemsPerPage + 1;
    var endIndex = startIndex + _itemsPerPage - 1;
    if (endIndex > total) endIndex = total;

    final isMobile = MediaQuery.of(context).size.width < 500;

    final infoText = Text(
      'Showing $startIndex-$endIndex of $total items',
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

  void _showEditDialog(BuildContext context, VendorLiveModel item) {
    final formKey = GlobalKey<FormState>();
    final productCtrl = TextEditingController(text: item.vendorProduct);
    final sizeCtrl = TextEditingController(text: item.vendorProductSize);
    final rateCtrl = TextEditingController(text: item.vendorProductRate.toString());
    String selectedStatus = item.vendorProductStatus;
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
                      child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6C3CE1), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.vendorName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update Rate Details',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'SubCat: ',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item.vendorProductCategorySub,
                                style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Product Name Field
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Product name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Size Field
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
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Size is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Rate Field
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Rate is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Status Field
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Status *',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: selectedStatus == 'Active' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(selectedStatus, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
                              Switch(
                                value: selectedStatus == 'Active',
                                activeColor: const Color(0xFF6C3CE1),
                                activeTrackColor: const Color(0xFFE9DEFF),
                                onChanged: (bool value) {
                                  setDialogState(() {
                                    selectedStatus = value ? 'Active' : 'Inactive';
                                  });
                                },
                              ),
                            ],
                          ),
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
                            setDialogState(() {
                              isSaving = true;
                            });

                            final result = await _vendorService.updateVendorLive(
                              item.id,
                              {
                                'vendor_product': productCtrl.text.trim(),
                                'vendor_product_size': sizeCtrl.text.trim(),
                                'vendor_product_rate': rateCtrl.text.trim(),
                                'vendor_product_status': selectedStatus,
                              },
                            );

                            if (context.mounted) {
                              setDialogState(() {
                                isSaving = false;
                              });
                              Navigator.pop(context); // Close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Status updated successfully', style: const TextStyle(color: Colors.white)),
                                  backgroundColor: result['success'] ? Colors.green : Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (result['success']) {
                                _fetchLiveItems(); // Refresh the list
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