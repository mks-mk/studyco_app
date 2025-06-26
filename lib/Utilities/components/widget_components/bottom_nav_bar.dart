import 'package:flutter/material.dart';
import '../../../controllers/navController.dart';
import '../../../controllers/scrollController.dart';

AnimatedOpacity bottomNavigationBar(
  BuildContext context,
  NavbarController navController,
  ScrollerController scrollControl,
) {
  return AnimatedOpacity(
    duration: Duration(milliseconds: 200),
    opacity: scrollControl.visibility.value == true ? 1 : 0,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Colors.transparent,
        width: MediaQuery.of(context).size.width,
        height: 85,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconOftheNB(
                child:Icon(Icons.home_rounded),
                id: 0,
                onTap: () {
                  navController.selectedIndex.value = 0;
                },
                navController: navController,
                text: "Home",
              ),
              iconOftheNB(
                child: Image.asset(
                  "assets/images/Book.png",
                  height: 28,
                  width: 28,
                ),
                id: 1,
                onTap: () {
                  navController.selectedIndex.value = 1;
                },
                navController: navController,
                text: "My Notes",
              ),
              iconOftheNB(
                child: Icon(Icons.notifications_active_rounded),
                id: 2,
                onTap: () {
                  navController.selectedIndex.value = 2;
                },
                navController: navController,
                text: "Alerts",
              ),
              iconOftheNB(
                child: Icon(Icons.person, color: Colors.black, size: 32),
                id: 3,
                onTap: () {
                  navController.selectedIndex.value = 3;
                },
                navController: navController,
                text: "Profile",
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Padding iconOftheNB({
  required Widget child,
  required int id,
  required void Function()? onTap,
  required NavbarController navController,
  required String text,
}) {
  return Padding(
    padding: const EdgeInsets.all(3.0),
    child: GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: navController.selectedIndex.value == id ? 50 : 55,
          width: navController.selectedIndex.value == id ? 100 : 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color:  navController.selectedIndex.value == id
            ? Color(0xffffbb00) : Color(0xffD9D9D9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
                child,
                Text(navController.selectedIndex.value == id ? text : "",style: TextStyle(
                  fontWeight: FontWeight.w600
                ),)
              ]),
        ),
      ),
    ),
  );
}
