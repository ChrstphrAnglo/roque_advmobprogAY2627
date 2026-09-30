import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';

import '../services/product_service.dart';

import '../widgets/custom_text.dart';

import 'detail_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Future<List<Product>> _productsFuture;
  // Enhancement 1: search bar state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().getAllProducts();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) setState(() => _searchQuery = query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _searchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                hintText: 'Search',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A single-widget sliver used for the loading, error and empty states.
  Widget _centered(Widget child) => SliverToBoxAdapter(
        child: Center(
          child: Padding(padding: EdgeInsets.all(32.r), child: child),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // Enhancement 1: filter the loaded products by the search query
          final allProducts = snapshot.data ?? [];
          final products = _searchQuery.isEmpty
              ? allProducts
              : allProducts
                    .where(
                      (product) =>
                          product.title.toLowerCase().contains(_searchQuery),
                    )
                    .toList();

          // A sliver grid builds only the cards near the screen, instead of
          // all of them at once, which keeps 194 products fast.
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                sliver: SliverToBoxAdapter(child: _searchBar(context)),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                _centered(const CircularProgressIndicator())
              else if (snapshot.hasError)
                _centered(
                  CustomText(
                    text: 'Error: ${snapshot.error}',
                    fontSize: 14.sp,
                  ),
                )
              else if (products.isEmpty)
                _centered(
                  CustomText(text: 'No Products found.', fontSize: 14.sp),
                )
              else
                SliverPadding(
                  // Extra bottom room keeps the chat button clear of the last row.
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 88.h),
                  sliver: SliverGrid.builder(
                    itemCount: products.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) =>
                        _ProductCard(product: products[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      // Enhancement 2: open the details page when a card is tapped
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(product: product),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                // Decode at card size rather than the full image size.
                cacheWidth: 400,
                errorBuilder: (_, _, _) => Icon(Icons.image, size: 24.sp),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
