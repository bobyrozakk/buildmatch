import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../data/providers/architect_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../shared/screens/notification_screen.dart';
import '../screens/upload_design_screen.dart';
import '../screens/detail_desain_screen.dart';

class ArsitekDesainTab extends StatefulWidget {
  const ArsitekDesainTab({super.key});

  @override
  State<ArsitekDesainTab> createState() => _ArsitekDesainTabState();
}

class _ArsitekDesainTabState extends State<ArsitekDesainTab> {
  String _selectedCategory = "Semua";
  late Future<List<Map<String, dynamic>>> _portfolioFuture;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  void _loadPortfolios() {
    final architect = Provider.of<ArchitectProvider>(context, listen: false);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "";
    _portfolioFuture = architect.fetchPortfolios(userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadPortfolios();
    });
    await _portfolioFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5), // Light cream background from Figma
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCF8F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.hardware_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(children: [
                TextSpan(
                    text: 'Build',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary)),
                TextSpan(
                    text: 'Match',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87)),
              ]),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadDesignScreen()),
              );
              if (result == true) {
                _refresh();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Consumer<NotificationProvider>(
            builder: (context, notif, child) => GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.cardCream,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.primary),
                  ),
                  if (notif.unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _portfolioFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final List<Map<String, dynamic>> displayList = snapshot.data ?? [];

            final filteredList = displayList.where((item) {
              if (_selectedCategory == "Semua") return true;
              final style = (item['style'] as String? ?? "").toLowerCase();
              return style.contains(_selectedCategory.toLowerCase());
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildCategoryFilters(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Eksplorasi Ide',
                        style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.filter_list, size: 14, color: Colors.black54),
                            SizedBox(width: 6),
                            Text('Terpopuler', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredList.isEmpty 
                    ? const Center(child: Text("Belum ada desain dalam kategori ini.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredList.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, i) {
                          final item = filteredList[i];
                          final title = item['title'] ?? "";
                          final style = item['style'] ?? "Modern";
                          final likes = item['likes'] ?? "0";
                          final views = item['views'] ?? "1.2k";
                          final imgUrl = item['image_url'] ?? "";

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailDesainScreen(designData: item),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      imgUrl.startsWith('http')
                                        ? Image.network(imgUrl, fit: BoxFit.cover)
                                        : Container(color: AppColors.cardCream),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            style,
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.favorite, size: 12, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text(likes, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                          const Spacer(),
                                          const Icon(Icons.visibility, size: 12, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text(views, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ));
                        },
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final List<String> categories = ["Semua", "Minimalis", "Modern", "Tropis"];
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF3EEE9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
