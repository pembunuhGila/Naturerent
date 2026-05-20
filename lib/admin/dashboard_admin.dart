import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  DASHBOARD PAGE  –  NatureRent Operations Portal
//  Dioptimalkan untuk layar mobile (Poco M3 ~393×851dp)
// ══════════════════════════════════════════════════════════════════════════════

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedNav = 0;
  bool _sidebarOpen = false;

  // ── Warna brand ─────────────────────────────────────────────────────────────
  static const kGreen = Color(0xFF1C4532);
  static const kGreenLight = Color(0xFF2D6A4F);
  static const kBg = Color(0xFFF3F4F6);
  static const kCard = Colors.white;
  static const kText = Color(0xFF111827);
  static const kSub = Color(0xFF6B7280);

  // ── Nav items ────────────────────────────────────────────────────────────────
  final _navItems = const [
    {'icon': Icons.grid_view_rounded, 'label': 'Overview'},
    {'icon': Icons.receipt_long_outlined, 'label': 'Rental Orders'},
    {'icon': Icons.directions_car_outlined, 'label': 'Fleet Management'},
    {'icon': Icons.people_outline, 'label': 'Customer Base'},
    {'icon': Icons.bar_chart_outlined, 'label': 'Analytics'},
    {'icon': Icons.settings_outlined, 'label': 'System Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
                    const SizedBox(height: 16),
                    _buildTransactionVolume(),
                    const SizedBox(height: 16),
                    _buildSystemLog(),
                    const SizedBox(height: 16),
                    _buildRecentTransactions(),
                    const SizedBox(height: 16),
                    _buildInventoryStatus(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DRAWER / SIDEBAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NatureRent',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: kText)),
                      Text('OPERATIONS PORTAL',
                          style: TextStyle(
                              fontSize: 9,
                              color: kSub,
                              letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Menu items ────────────────────────────────────────────────
            ...List.generate(_navItems.length, (i) {
              final isActive = _selectedNav == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedNav = i);
                  Navigator.pop(context);
                },
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: isActive
                        ? kGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _navItems[i]['icon'] as IconData,
                        size: 18,
                        color: isActive ? kGreen : kSub,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _navItems[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isActive ? kGreen : kSub,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Spacer(),
            const Divider(height: 1),

            // ── Footer ────────────────────────────────────────────────────
            _drawerFooterItem(
                context, Icons.help_outline, 'Help Center', null),
            _drawerFooterItem(
                context, Icons.logout, 'Sign Out', Colors.redAccent),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerFooterItem(
      BuildContext context, IconData icon, String label, Color? color) {
    return GestureDetector(
      onTap: () {
        if (label == 'Sign Out') {
          Navigator.pop(context);
          Navigator.of(context).pushReplacementNamed('/');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? kSub),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14, color: color ?? kSub)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Hamburger
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, size: 20, color: kText),
            ),
          ),
          const SizedBox(width: 10),

          // Search bar
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Search orders, customers...',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Notif
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined,
                  size: 22, color: Colors.grey[600]),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: kGreen,
            child: const Text('A',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PAGE HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Operational Overview',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kText)),
        const SizedBox(height: 3),
        Text(
          'Real-time performance metrics for NatureRent nationwide operations.',
          style: TextStyle(fontSize: 12, color: kSub),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STATS CARDS  –  2×2 grid
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'TOTAL OWNERS',
        'value': '1,284',
        'change': '+12%',
        'up': true,
        'icon': Icons.people_outline,
        'color': const Color(0xFF3B82F6),
        'highlight': false,
      },
      {
        'title': "TODAY'S TRANSACTIONS",
        'value': '342',
        'change': '+8%',
        'up': true,
        'icon': Icons.receipt_long_outlined,
        'color': const Color(0xFFF97316),
        'highlight': false,
      },
      {
        'title': 'COMMISSION REVENUE',
        'value': '\$42,590',
        'change': '+24%',
        'up': true,
        'icon': Icons.monetization_on_outlined,
        'color': Colors.white,
        'highlight': true, // dark green card
      },
      {
        'title': 'ACTIVE RENTALS',
        'value': '892',
        'change': '-3%',
        'up': false,
        'icon': Icons.directions_bike_outlined,
        'color': const Color(0xFF8B5CF6),
        'highlight': false,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: stats.map((s) => _statsCard(s)).toList(),
    );
  }

  Widget _statsCard(Map<String, dynamic> s) {
    final hl = s['highlight'] as bool;
    final up = s['up'] as bool;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: hl ? kGreen : kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(s['icon'] as IconData,
                  size: 20,
                  color: hl
                      ? Colors.white.withOpacity(0.8)
                      : s['color'] as Color),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: up
                      ? Colors.green.withOpacity(hl ? 0.25 : 0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        up
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 10,
                        color: up
                            ? (hl ? Colors.greenAccent : Colors.green[700])
                            : Colors.red[700]),
                    const SizedBox(width: 2),
                    Text(
                      s['change'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: up
                              ? (hl
                                  ? Colors.greenAccent
                                  : Colors.green[700])
                              : Colors.red[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'] as String,
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.5,
                      color: hl
                          ? Colors.white.withOpacity(0.6)
                          : kSub)),
              const SizedBox(height: 2),
              Text(s['value'] as String,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hl ? Colors.white : kText)),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TRANSACTION VOLUME CHART
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTransactionVolume() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final values = [0.38, 0.55, 0.45, 0.70, 0.52, 0.88];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transaction Volume',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kText)),
                  Text('Monthly breakdown of rental activity',
                      style: TextStyle(fontSize: 11, color: kSub)),
                ],
              ),
              _pillBtn('Last 6 Months'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (i) {
                final isLast = i == months.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 400 + i * 60),
                              curve: Curves.easeOut,
                              width: double.infinity,
                              height: 90 * values[i],
                              decoration: BoxDecoration(
                                gradient: isLast
                                    ? const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [kGreenLight, kGreen],
                                      )
                                    : null,
                                color: isLast ? null : const Color(0xFFB7D5C4),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(months[i],
                            style: TextStyle(
                                fontSize: 11,
                                color: isLast ? kGreen : kSub,
                                fontWeight: isLast
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SYSTEM LOG
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSystemLog() {
    final logs = [
      {
        'msg': 'Marcus V. approved 6 new listing requests.',
        'sub': '#Minutes ago • Rental Desk',
        'icon': Icons.person,
        'dark': true,
        'warn': false,
      },
      {
        'msg': 'Manual payout initiated for ID #9283.',
        'sub': '16 minutes ago • Finance',
        'icon': Icons.warning_amber_rounded,
        'dark': false,
        'warn': true,
      },
      {
        'msg': 'Sarah K. resolved customer dispute #442.',
        'sub': '1 hour ago • Support',
        'icon': Icons.person,
        'dark': true,
        'warn': false,
      },
      {
        'msg': 'System backup and maintenance completed.',
        'sub': '2 hours ago • Automated',
        'icon': Icons.cloud_done_outlined,
        'dark': false,
        'warn': false,
        'blue': true,
      },
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('System Log',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kText)),
              Text('View All',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          ...logs.map((log) {
            final isDark = log['dark'] as bool;
            final isWarn = log['warn'] as bool;
            final isBlue = (log['blue'] ?? false) as bool;
            Color avatarBg = isDark
                ? const Color(0xFF1F2937)
                : isWarn
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFEFF6FF);
            Color iconColor = isDark
                ? Colors.white
                : isWarn
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF3B82F6);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: avatarBg,
                    child: Icon(log['icon'] as IconData,
                        size: 14, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['msg'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kText,
                                height: 1.3)),
                        const SizedBox(height: 2),
                        Text(log['sub'] as String,
                            style: TextStyle(
                                fontSize: 10, color: kSub)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RECENT TRANSACTIONS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentTransactions() {
    final txs = [
      {
        'item': 'Mountain e-Bike Pro',
        'sub': 'Trek Dual Sport • #RE-9821',
        'customer': 'David Miller',
        'csub': 'Platinum Member',
        'status': 'COMPLETED',
        'commission': '\$12.40',
        'icon': Icons.directions_bike,
        'icolor': const Color(0xFF1C4532),
        'ibg': const Color(0xFFD1FAE5),
      },
      {
        'item': 'Tandem Kayak X-1',
        'sub': 'Water Sports • #RE-3018',
        'customer': 'Samantha Reed',
        'csub': 'Guest',
        'status': 'IN PROGRESS',
        'commission': '\$28.50',
        'icon': Icons.kayaking,
        'icolor': const Color(0xFF2563EB),
        'ibg': const Color(0xFFDBEAFE),
      },
      {
        'item': 'Portable Glamping Tent',
        'sub': 'Shelter • #RE-9122',
        'customer': 'Johnathan Doe',
        'csub': 'Regular',
        'status': 'PENDING',
        'commission': '\$45.00',
        'icon': Icons.home_outlined,
        'icolor': const Color(0xFFEA580C),
        'ibg': const Color(0xFFFFEDD5),
      },
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Transactions',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kText)),
                  Text('Live feed of global rental activities.',
                      style: TextStyle(fontSize: 11, color: kSub)),
                ],
              ),
              Row(
                children: [
                  _pillBtn('Filters', icon: Icons.filter_list),
                  const SizedBox(width: 6),
                  _pillBtn('Export', icon: Icons.upload_outlined),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Header row
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                    flex: 5,
                    child: _thLabel('RENTAL ENTITY')),
                Expanded(
                    flex: 4,
                    child: _thLabel('CUSTOMER')),
                Expanded(
                    flex: 3,
                    child: _thLabel('STATUS')),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          ...txs.map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: tx['ibg'] as Color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(tx['icon'] as IconData,
                              size: 17, color: tx['icolor'] as Color),
                        ),
                        // Item + customer
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(tx['item'] as String,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kText)),
                              Text(tx['sub'] as String,
                                  style: TextStyle(
                                      fontSize: 10, color: kSub)),
                            ],
                          ),
                        ),
                        // Customer
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(tx['customer'] as String,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: kText)),
                              Text(tx['csub'] as String,
                                  style: TextStyle(
                                      fontSize: 10, color: kSub)),
                            ],
                          ),
                        ),
                        // Status
                        Expanded(
                          flex: 3,
                          child: _statusChip(tx['status'] as String),
                        ),
                      ],
                    ),
                    // Commission row
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 42),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Commission: ${tx['commission']}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kGreen),
                          ),
                          const Icon(Icons.more_horiz,
                              size: 16, color: kSub),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _thLabel(String t) => Text(t,
      style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: kSub,
          letterSpacing: 0.6));

  Widget _statusChip(String status) {
    Color bg, fg;
    switch (status) {
      case 'COMPLETED':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        break;
      case 'IN PROGRESS':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INVENTORY STATUS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInventoryStatus() {
    final inv = [
      {
        'cat': 'Camping Gear',
        'pct': 0.82,
        'label': '82%',
        'sub': '120 units currently rented',
        'color': kGreen,
      },
      {
        'cat': 'Bicycles',
        'pct': 0.64,
        'label': '64%',
        'sub': '63 units currently rented',
        'color': kGreen,
      },
      {
        'cat': 'Water Sports',
        'pct': 0.91,
        'label': '91%',
        'sub': 'Critical high demand',
        'color': const Color(0xFFEF4444),
      },
      {
        'cat': 'Photography',
        'pct': 0.12,
        'label': '12%',
        'sub': 'Seasonal low',
        'color': kGreen,
      },
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inventory Status',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: kText)),
          const SizedBox(height: 14),
          ...inv.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['cat'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kText)),
                        Text(item['label'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: kText)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item['pct'] as double,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            item['color'] as Color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item['sub'] as String,
                          style: TextStyle(
                              fontSize: 10, color: kSub)),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20, color: Color(0xFFF3F4F6)),

          // Optimization insight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: kGreenLight),
                    const SizedBox(width: 6),
                    const Text('Optimization Insight',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kGreen)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Consider shifting marketing focus to "Photography" category for upcoming weekend.',
                  style: TextStyle(
                      fontSize: 11, color: kSub, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }

  Widget _pillBtn(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: kSub),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(fontSize: 11, color: kSub)),
          if (icon == null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 14, color: kSub),
          ],
        ],
      ),
    );
  }
}