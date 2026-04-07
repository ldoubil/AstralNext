
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../widgets/user_info_card.dart';
import '../widgets/quick_network_config_card.dart';
import '../widgets/hitokoto_card.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/connect_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _getColumnCount(double width) {
    if (width >= 1200) {
      return 5;
    } else if (width >= 900) {
      return 4;
    } else if (width >= 600) {
      return 3;
    }
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columnCount = _getColumnCount(width);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: StaggeredGrid.count(
                      crossAxisCount: columnCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        StaggeredGridTile.fit(
                          crossAxisCellCount: columnCount,
                          child: const BannerCarousel(),
                        ),
                        const UserInfoCard(),
                        const QuickNetworkConfigCard(),
                        const HitokotoCard(),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: columnCount,
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            right: 0,
            child: ConnectButton(),
          ),
        ],
      ),
    );
  }
}

