import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../controllers/cart/inApp_purchase.dart';
import '../../controllers/subjectController/getMaterialsWithSubjects.dart';
import '../../models/material_model.dart';

class MaterialDetailsPage extends StatefulWidget {
  final MaterialModel material;
  final String subject;

  const MaterialDetailsPage({
    Key? key,
    required this.material,
    required this.subject,
  }) : super(key: key);

  @override
  _MaterialDetailsPageState createState() => _MaterialDetailsPageState();
}

class _MaterialDetailsPageState extends State<MaterialDetailsPage> {
  late final ScrollController _scrollController;
  bool _isFabVisible = true;
  // Get an instance of the purchase controller
  final InAppPurchaseService _purchaseService = Get.put(InAppPurchaseService());

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = widget.material.color;
    final Color lightThemeColor = themeColor.withOpacity(0.15);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: _buildAnimatedFab(themeColor),
      // REVERTED: Using Stack and NestedScrollView to match your desired UI
      body: Stack(
        children: [
          ClipPath(
            clipper: _BackgroundClipper(),
            child: Container(
              height: Get.height * 0.5,
              color: lightThemeColor.withOpacity(0.5),
            ),
          ),
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(),
              _buildHeader(themeColor),
            ],
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _buildContentCard(themeColor, lightThemeColor),
                  const SizedBox(height: 100), // Padding for the FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFab(Color themeColor) {
    return Obx(() {
      final product = _purchaseService.products.firstWhere(
            (p) => p.id == widget.material.productID,
        orElse: () => ProductDetails(id: '', title: '', description: '', price: '', rawPrice: 0.0, currencyCode: ''),
      );

      bool canBuy = _purchaseService.storeIsAvailable.value && product.id.isNotEmpty;

      return AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isFabVisible ? 1 : 0,
          child: FloatingActionButton.extended(
            onPressed: canBuy
                ? () {
              _purchaseService.setPurchaseContext(widget.subject);
              _purchaseService.buyProduct(product);
            }
                : null,
            backgroundColor: canBuy ? themeColor : Colors.grey,
            icon: _purchaseService.isStoreLoading.value
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            label: Text(
              canBuy ? 'Buy Now for ${product.price}' : 'Unavailable',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    });
  }

  // REVERTED: Simple SliverAppBar for the back button
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.1),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
            onPressed: () => Get.back(),
          ),
        ),
      ),
    );
  }

  // REVERTED: Header with image and title, not part of the app bar
  SliverToBoxAdapter _buildHeader(Color themeColor) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          children: [
            Hero(
              tag: 'material_hero_${widget.material.id}',
              child: Container(
                height: Get.height * 0.28,
                width: Get.width * 0.55,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.network(
                  widget.material.thumbnail,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Skeletonizer(
                      enabled: true,
                      child: Bone.square(size: double.infinity),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.material.noteName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // REVERTED: Content card is now a regular widget, not a sliver
  Widget _buildContentCard(Color themeColor, Color lightThemeColor) {
    final MaterialsWithSubjectsController controller = Get.find();
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: AnimationConfiguration.staggeredList(
          position: 0,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDescriptionHeader(controller, themeColor),
                    const SizedBox(height: 24),
                    _buildInfoCards(lightThemeColor),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Description"),
                    const SizedBox(height: 8),
                    _buildDescriptionText(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionHeader(MaterialsWithSubjectsController controller, Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Obx(() {
          bool isBookmarked = controller.isBookmarked(subject: widget.subject, id: widget.material.id);
          return InkWell(
            onTap: () {
              controller.toggleBookmark(subject: widget.subject, id: widget.material.id);
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isBookmarked ? themeColor : const Color(0xFFF1F5F9),
                boxShadow: [
                  BoxShadow(
                    color: isBookmarked ? themeColor.withOpacity(0.3) : Colors.transparent,
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.white : const Color(0xFF64748B),
                size: 28,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoCards(Color lightThemeColor) {
    return Row(
      children: [
        Expanded(child: _buildInfoCard(Icons.school_outlined, "Subject", widget.subject, lightThemeColor)),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard(Icons.layers_outlined, "Module", 'Module ${widget.material.module}', lightThemeColor)),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: widget.material.color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: widget.material.color.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: widget.material.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: Color(0xFF475569),
      ),
    );
  }

  Widget _buildDescriptionText() {
    String description = widget.material.description != null && widget.material.description!.isNotEmpty
        ? widget.material.description!
        : "This comprehensive material covers all the essential topics for Module ${widget.material.module}. It includes detailed explanations, examples, and practice questions to help you master the subject.";

    return Text(
      description,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF64748B),
        height: 1.7,
      ),
    );
  }
}

class _BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
