import '../widgets/filter_chip_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/controllers/model_discovery_controller.dart';
import '../../core/theme/colors.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chip_widget.dart';
import '../widgets/model_card.dart';

class ModelDiscoveryScreen extends GetView<ModelDiscoveryController> {
  const ModelDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          // Search & Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  SearchBarWidget(
                    onChanged: controller.updateSearchQuery,
                  ),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.searchQuery.value.isNotEmpty
                            ? 'Search Results'
                            : 'Popular Models',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      Obx(() => Text(
                            '${controller.trendingModels.length} models',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondaryDark,
                            ),
                          )),
                    ],
                  )),
            ),
          ),
          // Loading indicator
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.isLoading.value || controller.isSearching.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          controller.isSearching.value
                              ? 'Searching HuggingFace...'
                              : 'Loading models...',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox();
            }),
          ),
          // Model list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: Obx(() {
              if (controller.isLoading.value || controller.isSearching.value) {
                return const SliverToBoxAdapter(child: SizedBox());
              }
              if (controller.trendingModels.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              size: 48,
                              color: AppColors.textSecondaryDark
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No models found',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: AppColors.textSecondaryDark
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final model = controller.trendingModels[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ModelCard(
                        model: model,
                        onDownload: () =>
                            controller.downloadModel(model.id),
                        onCancelDownload: () =>
                            controller.cancelDownload(model.id),
                      ),
                    );
                  },
                  childCount: controller.trendingModels.length,
                ),
              );
            }),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.backgroundDark.withValues(alpha: 0.95),
      elevation: 0,
      toolbarHeight: 60,
      title: Text(
        'Model Discovery',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_circle,
                color: AppColors.textPrimaryDark,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: Obx(() => ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.filterCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = controller.filterCategories[index];
              return FilterChipWidget(
                category: category,
                onTap: () => controller.selectFilter(category.id),
              );
            },
          )),
    );
  }
}
