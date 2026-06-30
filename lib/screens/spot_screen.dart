import 'package:flutter/material.dart';
import 'package:krm_admin/models/vendor_spot_rate_model.dart';
import 'package:krm_admin/services/vendor_service.dart';
import 'package:flutter/foundation.dart';

class SpotScreen extends StatefulWidget {
  const SpotScreen({super.key});

  @override
  State<SpotScreen> createState() => _SpotScreenState();
}

class _SpotScreenState extends State<SpotScreen> {
  final VendorService _vendorService = VendorService();
  List<VendorSpotRateModel> _spotItems = [];
  List<VendorSpotRateModel> _filteredItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _selectedVendorFilter = 'All';
  String _selectedHeadingFilter = 'All';
  String _selectedDetailsFilter = 'All';
  String _selectedDateFilter = 'All';
  bool _showFilters = false;

  List<String> get uniqueVendors {
    final vendors = _spotItems.map((item) => item.vendorName).toSet().where((v) => v.isNotEmpty).toList();
    vendors.sort();
    return ['All', ...vendors];
  }

  List<String> get uniqueHeadings {
    final headings = _spotItems.map((item) => item.vendorSpotHeading).toSet().where((h) => h.isNotEmpty).toList();
    headings.sort();
    return ['All', ...headings];
  }

  List<String> get uniqueDetails {
    final details = _spotItems.map((item) => item.vendorSpotDetails).toSet().where((d) => d.isNotEmpty).toList();
    details.sort();
    return ['All', ...details];
  }

  List<String> get uniqueDates {
    final dates = _spotItems.map((item) => item.vendorSpotCreatedDate).toSet().where((d) => d.isNotEmpty).toList();
    dates.sort();
    return ['All', ...dates];
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _filterStatus = 'All';
      _selectedVendorFilter = 'All';
      _selectedHeadingFilter = 'All';
      _selectedDetailsFilter = 'All';
      _selectedDateFilter = 'All';
      _applyFilter();
    });
  }

  // Pagination parameters
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchSpotRates();
  }

  Future<void> _fetchSpotRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _vendorService.fetchVendorSpotRatesList();
      if (mounted) {
        setState(() {
          _spotItems = items;
          // Apply current filters on pull to refresh
          _filteredItems = items.where((item) {
            final matchesSearch = _searchQuery.isEmpty ||
                item.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.vendorSpotHeading.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.vendorSpotDetails.toLowerCase().contains(_searchQuery.toLowerCase());

            final matchesStatus = _filterStatus == 'All' ||
                item.vendorSpotStatus.toLowerCase() == _filterStatus.toLowerCase();

            final matchesVendor = _selectedVendorFilter == 'All' ||
                item.vendorName == _selectedVendorFilter;

            final matchesHeading = _selectedHeadingFilter == 'All' ||
                item.vendorSpotHeading == _selectedHeadingFilter;

            final matchesDetails = _selectedDetailsFilter == 'All' ||
                item.vendorSpotDetails == _selectedDetailsFilter;

            final matchesDate = _selectedDateFilter == 'All' ||
                item.vendorSpotCreatedDate == _selectedDateFilter;

            return matchesSearch && matchesStatus && matchesVendor && matchesHeading && matchesDetails && matchesDate;
          }).toList();
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load spot rates: $e';
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _currentPage = 1; // Reset to page 1 on filter/search change
      _filteredItems = _spotItems.where((item) {
        final matchesSearch = _searchQuery.isEmpty ||
            item.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.vendorSpotHeading.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.vendorSpotDetails.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatus = _filterStatus == 'All' ||
            item.vendorSpotStatus.toLowerCase() == _filterStatus.toLowerCase();

        final matchesVendor = _selectedVendorFilter == 'All' ||
            item.vendorName == _selectedVendorFilter;

        final matchesHeading = _selectedHeadingFilter == 'All' ||
            item.vendorSpotHeading == _selectedHeadingFilter;

        final matchesDetails = _selectedDetailsFilter == 'All' ||
            item.vendorSpotDetails == _selectedDetailsFilter;

        final matchesDate = _selectedDateFilter == 'All' ||
            item.vendorSpotCreatedDate == _selectedDateFilter;

        return matchesSearch && matchesStatus && matchesVendor && matchesHeading && matchesDetails && matchesDate;
      }).toList();
    });
  }

  Future<void> _refreshSpotRates() async {
    await _fetchSpotRates();
  }

  // Pagination helpers
  int get totalPages => (_filteredItems.length / _itemsPerPage).ceil();

  List<VendorSpotRateModel> get currentPagedItems {
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
        onRefresh: _refreshSpotRates,
        color: const Color(0xFF6C3CE1),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3CE1)))
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
                          if (_errorMessage != null && _filteredItems.isEmpty)
                            _buildEmptyState()
                          else if (_filteredItems.isEmpty)
                            _buildNoMatchState()
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
    final totalCount = _spotItems.length;
    final activeCount = _spotItems.where((v) => v.vendorSpotStatus.toLowerCase() == 'active').length;
    final inactiveCount = _spotItems.where((v) => v.vendorSpotStatus.toLowerCase() == 'inactive').length;

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    Widget card1 = _buildStatCard('Total Spot', totalCount.toString(), const Color(0xFF6C3CE1), Icons.bolt_rounded);
    Widget card2 = _buildStatCard('Active Spot', activeCount.toString(), const Color(0xFF10B981), Icons.check_circle_outline_rounded);
    Widget card3 = _buildStatCard('Inactive Spot', inactiveCount.toString(), const Color(0xFFEF4444), Icons.cancel_outlined);

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
                      hintText: 'Search by vendor name, heading, or details...',
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
                if (_searchQuery.isNotEmpty || _selectedVendorFilter != 'All' || _selectedHeadingFilter != 'All' || _selectedDetailsFilter != 'All' || _selectedDateFilter != 'All')
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
                                value: _selectedHeadingFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Heading',
                                  labelStyle: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedHeadingFilter = val;
                                      _applyFilter();
                                    });
                                  }
                                },
                                items: uniqueHeadings.map((h) => DropdownMenuItem(value: h, child: Text(h.length > 25 ? h.substring(0, 25) + '...' : h))).toList(),
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
                                value: _selectedDetailsFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Details',
                                  labelStyle: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDetailsFilter = val;
                                      _applyFilter();
                                    });
                                  }
                                },
                                items: uniqueDetails.map((d) => DropdownMenuItem(value: d, child: Text(d.length > 25 ? d.substring(0, 25) + '...' : d))).toList(),
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
                                value: _selectedDateFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Date/Time',
                                  labelStyle: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                  border: InputBorder.none,
                                ),
                                isExpanded: true,
                                style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDateFilter = val;
                                      _applyFilter();
                                    });
                                  }
                                },
                                items: uniqueDates.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
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

  Widget _buildContentHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Vendor Spot Rates',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        GestureDetector(
          onTap: () => _showAddDialog(context),
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
                  'Add Spot',
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
            _errorMessage ?? 'No spot rates found',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchSpotRates,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C3CE1), foregroundColor: Colors.white),
            child: const Text('Retry Fetching'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchState() {
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
            'No spot rates match your criteria',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filterStatus = 'All';
                _applyFilter();
              });
            },
            child: const Text('Clear filters', style: TextStyle(color: Color(0xFF6C3CE1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Desktop Table layout
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
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(3),
          3: FlexColumnWidth(5),
          4: FixedColumnWidth(100),
          5: FixedColumnWidth(100),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Table Header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            children: [
              _buildTableHeaderCell('SL No'),
              _buildTableHeaderCell('Vendor Name'),
              _buildTableHeaderCell('Heading'),
              _buildTableHeaderCell('Details'),
              _buildTableHeaderCell('Status'),
              _buildTableHeaderCell('Actions'),
            ],
          ),
          // Table Body
          ...List.generate(paged.length, (idx) {
            final item = paged[idx];
            return TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              children: [
                _buildTableCell(Text('${startIndex + idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                _buildTableCell(Text(item.vendorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                _buildTableCell(Text(item.vendorSpotHeading, style: const TextStyle(fontWeight: FontWeight.w600))),
                _buildTableCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.vendorSpotDetails,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      if (item.vendorSpotDetails.length > 80)
                        GestureDetector(
                          onTap: () => _showDetailsPopup(context, item.vendorName, item.vendorSpotDetails),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'View Full details',
                              style: TextStyle(color: Color(0xFF6C3CE1), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                 _buildTableCell(_buildStatusBadge(item)),
                _buildTableCell(
                  

ElevatedButton.icon(
  onPressed: () => _showEditDialog(context, item),
  icon: const Icon(Icons.edit_outlined, size: 14),
  label: defaultTargetPlatform == TargetPlatform.android
      ? const Text('Edit')
      : const SizedBox.shrink(),
  style: ElevatedButton.styleFrom(
    backgroundColor: defaultTargetPlatform == TargetPlatform.android
        ? const Color(0xFFF5F0FF)
        : Colors.transparent,
    foregroundColor: const Color(0xFF6C3CE1),
    elevation: 0,
    shadowColor: Colors.transparent,
    side: BorderSide(
      color: defaultTargetPlatform == TargetPlatform.android
          ? const Color(0xFFE9DEFF)
          : Colors.transparent,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),
                ),
              ],
            );
          }),
        ],
      ),
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

  Widget _buildTableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _buildStatusBadge(VendorSpotRateModel item) {
    final status = item.vendorSpotStatus;
    final isActive = status.toLowerCase() == 'active';
    return InkWell(
      onTap: () => _toggleSpotStatus(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
            width: 0.5,
          ),
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

  Future<void> _toggleSpotStatus(VendorSpotRateModel item) async {
    final originalStatus = item.vendorSpotStatus;
    final newStatus = originalStatus.toLowerCase() == 'active' ? 'Inactive' : 'Active';

    setState(() {
      item.vendorSpotStatus = newStatus;
    });

    try {
      final result = await _vendorService.updateVendorSpotRate(item.id, {
        'vendor_id': item.vendorId,
        'vendor_spot_heading': item.vendorSpotHeading,
        'vendor_spot_details': item.vendorSpotDetails,
        'vendor_spot_status': newStatus,
      });

      if (!result['success']) {
        setState(() {
          item.vendorSpotStatus = originalStatus;
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
              content: Text('${item.vendorSpotHeading} status updated to $newStatus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        item.vendorSpotStatus = originalStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  // Mobile list view layout
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
        final isActive = item.vendorSpotStatus.toLowerCase() == 'active';

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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                               _buildStatusBadge(item),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.vendorSpotHeading,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C3CE1), fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            item.vendorSpotDetails,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          if (item.vendorSpotDetails.length > 120)
                            GestureDetector(
                              onTap: () => _showDetailsPopup(context, item.vendorName, item.vendorSpotDetails),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'View Full details',
                                  style: TextStyle(color: Color(0xFF6C3CE1), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Created: ${item.vendorSpotCreatedDate}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            

ElevatedButton.icon(
  onPressed: () => _showEditDialog(context, item),
  icon: const Icon(Icons.edit_outlined, size: 14),
  label: defaultTargetPlatform == TargetPlatform.android
      ? const Text('Edit')
      : const SizedBox.shrink(),
  style: ElevatedButton.styleFrom(
    backgroundColor: defaultTargetPlatform == TargetPlatform.android
        ? const Color(0xFFF5F0FF)
        : Colors.transparent,
    foregroundColor: const Color(0xFF6C3CE1),
    elevation: 0,
    shadowColor: Colors.transparent,
    side: BorderSide(
      color: defaultTargetPlatform == TargetPlatform.android
          ? const Color(0xFFE9DEFF)
          : Colors.transparent,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),
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

  void _showDetailsPopup(BuildContext context, String vendorName, String details) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Text(
              details,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF6C3CE1), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // "+ Add Spot Rate" dialog flow
  void _showAddDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C3CE1))),
    );

    final eligibleVendors = await _vendorService.fetchSpotEligibleVendors();
    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (eligibleVendors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No eligible spot vendors found'), backgroundColor: Colors.red),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    int? selectedVendorId;
    final headingCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
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
                            'Add Spot Rate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Define new vendor spot details',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Select Vendor Dropdown
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Vendor *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonFormField<int>(
                            isExpanded: true,
                            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                            iconSize: 28,
                            style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                            hint: const Text('Select Vendor'),
                            items: eligibleVendors.map((vendor) {
                              return DropdownMenuItem<int>(
                                value: vendor['id'] as int,
                                child: Text(
                                  vendor['vendor_name']?.toString() ?? 'N/A',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              selectedVendorId = val;
                            },
                            validator: (value) => value == null ? 'Please select a vendor' : null,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Heading Input
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Heading *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: headingCtrl,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter Heading',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Heading is required' : null,
                        ),
                        const SizedBox(height: 18),

                        // Details Input
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Spot Details *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: detailsCtrl,
                          maxLines: 6,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter Spot Details...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Details are required' : null,
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

                            final payload = {
                              'vendor_id': selectedVendorId,
                              'vendor_spot_heading': headingCtrl.text.trim(),
                              'vendor_spot_details': detailsCtrl.text.trim(),
                            };

                            final res = await _vendorService.createVendorSpotRate(payload);

                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                              Navigator.pop(context); // Close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Spot rate created successfully', style: const TextStyle(color: Colors.white)),
                                  backgroundColor: res['success'] ? Colors.green : Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (res['success']) {
                                _fetchSpotRates(); // Refresh screen
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
                      : const Text('Add Spot Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // "Edit Spot Rate" dialog flow
  void _showEditDialog(BuildContext context, VendorSpotRateModel item) {
    final formKey = GlobalKey<FormState>();
    final headingCtrl = TextEditingController(text: item.vendorSpotHeading);
    final detailsCtrl = TextEditingController(text: item.vendorSpotDetails);
    String vendorSpotStatus = item.vendorSpotStatus;
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
                            'Update Spot Details',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vendor Status Master Card (Requested Switch)
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Vendor Status',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Card(
                          elevation: 0,
                          color: vendorSpotStatus == 'Active' ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: vendorSpotStatus == 'Active' ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  vendorSpotStatus == 'Active' ? 'Status: Active' : 'Status: Inactive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: vendorSpotStatus == 'Active' ? const Color(0xFF047857) : const Color(0xFFBE123C),
                                  ),
                                ),
                                Switch(
                                  value: vendorSpotStatus == 'Active',
                                  activeColor: const Color(0xFF10B981),
                                  activeTrackColor: const Color(0xFFD1FAE5),
                                  inactiveThumbColor: const Color(0xFFEF4444),
                                  inactiveTrackColor: const Color(0xFFFEE2E2),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      vendorSpotStatus = val ? 'Active' : 'Inactive';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Heading Input
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Heading *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: headingCtrl,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter Heading',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Heading is required' : null,
                        ),
                        const SizedBox(height: 18),

                        // Details Input
                        const Row(
                          children: [
                            SizedBox(width: 4),
                            Text(
                              'Spot Details *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: detailsCtrl,
                          maxLines: 6,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter Spot Details...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 1.5)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Details are required' : null,
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

                            final payload = {
                              'vendor_id': item.vendorId,
                              'vendor_spot_heading': headingCtrl.text.trim(),
                              'vendor_spot_details': detailsCtrl.text.trim(),
                              'vendor_spot_status': vendorSpotStatus,
                            };

                            final res = await _vendorService.updateVendorSpotRate(item.id, payload);

                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                              Navigator.pop(context); // Close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Spot rate updated successfully', style: const TextStyle(color: Colors.white)),
                                  backgroundColor: res['success'] ? Colors.green : Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );

                              if (res['success']) {
                                _fetchSpotRates(); // Refresh screen
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
}