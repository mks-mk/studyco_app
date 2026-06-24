import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studyco_app/Utilities/components/gradient_bt.dart';
import '../../Utilities/components/dropdown_search.dart';
import '../../Utilities/variables/app_colors.dart';
import '../../controllers/authcontroller.dart';

class ProfileFillScreen extends StatefulWidget {
  const ProfileFillScreen({super.key});

  @override
  State<ProfileFillScreen> createState() => _ProfileFillScreenState();
}

class _ProfileFillScreenState extends State<ProfileFillScreen> {
  List<Map<String, dynamic>> courses = [];
  String? selectedCourse;
  List<String> groups = [];
  String? selectedGroup;
  List<String> semesters = [];
  String? selectedSemester;
  bool isLoading = true;
  bool showGroupDropdown = false;
  bool showSemesterDropdown = false;
  late TextEditingController nameController;
  late TextEditingController eduController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColor.backgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColor.backgroundColor,
      ),
    );
    _initializeData();
  }

  Future<void> _initializeData() async {
    User? user = FirebaseAuth.instance.currentUser;
    nameController = TextEditingController(text: user?.displayName ?? '');
    eduController = TextEditingController();

    try {
      courses = await getCourses();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading courses: $e');
      }
      courses = [];
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onCourseChanged(String? courseName) {
    if (courseName != null) {
      setState(() {
        selectedCourse = courseName;
        selectedGroup = null;
        selectedSemester = null;
        showGroupDropdown = false;
        showSemesterDropdown = false;

        // Find selected course data
        Map<String, dynamic>? selectedCourseData;
        for (var course in courses) {
          if (course['name'] == courseName) {
            selectedCourseData = course;
            break;
          }
        }

        if (selectedCourseData != null &&
            selectedCourseData['Groups'] != null) {
          groups = List<String>.from(selectedCourseData['Groups']);

          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                showGroupDropdown = true;
              });
            }
          });

          if (courseName == "BTech") {
            semesters = [
              '1st Semester',
              '2nd Semester',
              '3rd Semester',
              '4th Semester',
              '5th Semester',
              '6th Semester',
              '7th Semester',
              '8th Semester',
            ];

            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                setState(() {
                  showSemesterDropdown = true;
                });
              }
            });
          } else {
            semesters = [];
          }
        } else {
          groups = [];
          semesters = [];
        }
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    eduController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: Get.height * 0.10),
                Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: Get.height * 0.08,
                    fontFamily:
                        GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.bold,
                        ).fontFamily,
                  ),
                ),
                Text(
                  'Please provide your profile details to Continue',
                  style: TextStyle(
                    color: const Color(0xFF818181),
                    fontSize: Get.height * 0.02,
                    fontFamily:
                        GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.w300,
                        ).fontFamily,
                  ),
                ),
                SizedBox(height: Get.height * 0.02),

                // Name Input
                TextInput(
                  user: user?.photoURL,
                  controller: nameController,
                  hint: ' Name',
                  icon: Icons.person,
                ),

                // Course Dropdown
                DropdownSearchInput<String>(
                  user: '',
                  hint: "Select Course",
                  showSearchBox: false,
                  icon: Icons.school_rounded,
                  items:
                      courses
                          .map((course) => course['name'] as String)
                          .toList(),
                  selectedItem: selectedCourse,
                  onChanged: _onCourseChanged,
                ),

                // Groups Dropdown (animated)
                AnimatedOpacity(
                  opacity: showGroupDropdown ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child:
                      showGroupDropdown
                          ? DropdownSearchInput<String>(
                            user: '',
                            hint: "Select Group",
                            showSearchBox: false,
                            icon: Icons.group,
                            items: groups,
                            selectedItem: selectedGroup,
                            onChanged: (value) {
                              setState(() {
                                selectedGroup = value;
                              });
                              if (kDebugMode) {
                                print("Selected group: $value");
                              }
                            },
                          )
                          : const SizedBox.shrink(),
                ),

                // Semester Dropdown (only for BTech, animated)
                AnimatedOpacity(
                  opacity: showSemesterDropdown ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child:
                      showSemesterDropdown
                          ? DropdownSearchInput<String>(
                            user: '',
                            hint: "Select Semester",
                            showSearchBox: false,
                            icon: Icons.calendar_today,
                            items: semesters,
                            selectedItem: selectedSemester,
                            onChanged: (value) {
                              setState(() {
                                selectedSemester = value;
                              });
                              if (kDebugMode) {
                                print("Selected semester: $value");
                              }
                            },
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
            Positioned(
              bottom: 1,

              child: GradientBG(
                onTap: () async {
                 if(selectedCourse != null && selectedGroup != null && selectedSemester != null && nameController.text.isNotEmpty && nameController.text != ''){
                   if(selectedSemester == '1st Semester'){
                     GetStorage().write('sem', "S${semesters.indexOf(selectedSemester ?? '') + 1}");
                     GetStorage().write('class', "${selectedCourse}_A");

                   }else{
                     GetStorage().write('sem', "S${semesters.indexOf(selectedSemester ?? '') + 1}");
                     GetStorage().write('class', "${selectedCourse}_$selectedGroup");

                   }

                   await Get.find<AuthController>().saveProfile(
                     name: nameController.text,
                     course: selectedCourse ?? '',
                     stream: selectedGroup ?? '',
                     sem:
                     selectedCourse == "BTech"
                         ? semesters.indexOf(selectedSemester ?? '') + 1
                         : selectedGroup == "Plus one"
                         ? 11
                         : selectedGroup == "Plus two"
                         ? 12
                         : 10,
                   );
                 }else{
                   Get.snackbar(
                     'Please fill your details !',
                     'Provide all details to personalise the contends to you',
                     colorText: Colors.white,
                     backgroundColor: Colors.red,
                   );
                 }
                },
                height: Get.height * 0.06,
                width: Get.width * 0.6,
                child: Center(
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: Get.height * 0.03,
                      fontFamily:
                          GoogleFonts.leagueSpartan(
                            fontWeight: FontWeight.bold,
                          ).fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    try {
      final DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('strings')
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('courses')) {
          List<dynamic> coursesData = data['courses'];

          return coursesData.map((course) {
            return {
              'name': course['name'] as String,
              'Groups': course['Groups'] as List<dynamic>,
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching courses: $e');
      }
      return [];
    }
  }
}

class TextInput extends StatelessWidget {
  const TextInput({
    super.key,
    required this.user,
    required this.controller,
    required this.hint,
    required this.icon,
  });

  final String? user;
  final String? hint;
  final IconData? icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 46,
            decoration: BoxDecoration(
              color:
                  (user != null &&
                          user!.isNotEmpty &&
                          Uri.tryParse(user!) != null)
                      ? Colors.transparent
                      : const Color(0x59DDDDDD),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                (user != null &&
                        user!.isNotEmpty &&
                        Uri.tryParse(user!) != null)
                    ? CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(user!),
                    )
                    : Icon(icon, color: Colors.black),
          ),
          const SizedBox(width: 6),
          Container(
            height: 42,
            width: Get.width * 0.7,
            decoration: BoxDecoration(
              color: const Color(0x59DDDDDD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              textAlign: TextAlign.center,
              controller: controller,
              cursorColor: Colors.yellow,
              cursorOpacityAnimates: true,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: const Color(0xFF818181),
                  fontSize: Get.height * 0.02 + 3,
                  fontFamily:
                      GoogleFonts.leagueSpartan(
                        fontWeight: FontWeight.w400,
                      ).fontFamily,
                ),
                contentPadding: const EdgeInsets.only(right: 12),
              ),
              style: TextStyle(
                color: Colors.black,
                fontSize: Get.height * 0.02 + 3,
                fontFamily:
                    GoogleFonts.leagueSpartan(
                      fontWeight: FontWeight.w400,
                    ).fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
