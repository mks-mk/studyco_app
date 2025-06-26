import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScrollerController extends GetxController{
  RxDouble currentScrollPosition = 0.0.obs;
  RxBool visibility = true.obs;
  ScrollController scrollController = ScrollController();


  @override
  void onInit() {
    scrollController.addListener(_scrollListener);
    super.onInit();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Check scroll direction
    if (scrollController.offset > currentScrollPosition.value) {
      visibility.value = false;
    } else if (scrollController.offset < currentScrollPosition.value) {
      visibility.value = true;
    }

    currentScrollPosition.value = scrollController.offset;
  }
}