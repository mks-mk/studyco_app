import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../Utilities/components/widget_components/for_you_widget.dart';
import '../../controllers/subjectController/for_you_controller.dart';

class ForYouFullPage extends StatelessWidget {
  const ForYouFullPage({super.key});

  @override
  Widget build(BuildContext context) {
    ForYouController forYouController = Get.find<ForYouController>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.6,
            colors: [Color(0xFFDDCFAF), Color(0xFFFFFFFF)],
            stops: [0.05, 0.80],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- HANDSOME SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    onChanged: (value) =>
                    forYouController.searchQuery.value = value,
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: "Search for you...",
                      prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Obx(() => forYouController.searchQuery.value.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          forYouController.searchQuery.value = '';
                          FocusScope.of(context).unfocus();
                        },
                      )
                          : SizedBox()),
                    ),
                  ),
                ),
              ),
              // -- GRIDVIEW --
              Expanded(
                child: Obx(() {
                  if (forYouController.isLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final items = forYouController.filteredItems;
          
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        forYouController.searchQuery.value.isEmpty
                            ? "No items yet."
                            : "No results found.",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    );
                  }
          
                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 columns
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return forYouCard(items[index]);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
