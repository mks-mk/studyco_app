import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/for_you_model.dart';


Widget forYouCard(ForYouModel forYou) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Container(
      width: 160,
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
      ),
      child: GestureDetector(
        onTap: (){
          print(Get.height);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: forYou.thumbnail,
            memCacheWidth: 173,
            memCacheHeight: 300,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Center(child: Column(
              children: [
                Icon(Icons.card_giftcard_rounded),
                Text(forYou.name)
              ],
            ),),
          ),


        ),
      ),
    ),
  );
}

