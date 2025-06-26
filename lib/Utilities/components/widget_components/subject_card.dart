import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/subject_model.dart';
import '../../../pages/materials/materials_page.dart';

Widget buildSubjectCard(SubjectModel subject) {
  return GestureDetector(
    onTap: (){
      Get.to(()=>MaterialsPage(subject: subject.subjectName,));
    },
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        width: 173,
        height: 173,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: CachedNetworkImage(
              imageUrl: subject.thumbnail,
            memCacheWidth: 173,
            memCacheHeight: 173,
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
                  Icon(Icons.menu_book_rounded),
                  Text(subject.subjectName)
                ],
              ),),
          ),


        ),
      ),
    ),
  );
}

