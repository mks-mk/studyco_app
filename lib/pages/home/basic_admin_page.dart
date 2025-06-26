// import 'package:flutter/material.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:io';
//
// class BasicAdminPage extends StatefulWidget {
//   const BasicAdminPage({super.key});
//
//   @override
//   State<BasicAdminPage> createState() => _BasicAdminPageState();
// }
//
// class _BasicAdminPageState extends State<BasicAdminPage> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//
//   // Text field controllers
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _typeController = TextEditingController();
//   final TextEditingController _sourceController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _imageController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController classController = TextEditingController(text: "BTech_A");
//   final TextEditingController semController = TextEditingController(text: "S1");
//   final TextEditingController subjectController = TextEditingController(text: "Physics");
//
//   // Color picker
//   Color selectedColor = Color(0xFF2196F3);
//
//   // Loading states
//   bool isLoading = false;
//   bool isImageUploading = false;
//   bool isFileUploading = false;
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _typeController.dispose();
//     _sourceController.dispose();
//     _priceController.dispose();
//     _imageController.dispose();
//     _descriptionController.dispose();
//     classController.dispose();
//     semController.dispose();
//     subjectController.dispose();
//     super.dispose();
//   }
//
//   // Firebase Storage Functions
//   Future<String> uploadImageToFirebase(XFile imageFile) async {
//     try {
//       setState(() {
//         isImageUploading = true;
//       });
//
//       // Create storage reference
//       final storageRef = FirebaseStorage.instance.ref();
//       final imageRef = storageRef.child('BTech/S1/images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}');
//
//       // Upload file
//       final uploadTask = await imageRef.putFile(File(imageFile.path));
//
//       // Get download URL
//       final downloadURL = await uploadTask.ref.getDownloadURL();
//
//       Get.snackbar(
//         'Success',
//         'Image uploaded successfully!',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//
//       return downloadURL;
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to upload image: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       throw e;
//     } finally {
//       setState(() {
//         isImageUploading = false;
//       });
//     }
//   }
//
//   Future<String> uploadFileToFirebase(PlatformFile file) async {
//     try {
//       setState(() {
//         isFileUploading = true;
//       });
//
//       // Create storage reference
//       final storageRef = FirebaseStorage.instance.ref();
//       final fileRef = storageRef.child('BTech/S1/materials/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
//
//       // Upload file
//       UploadTask uploadTask;
//       if (file.bytes != null) {
//         // For web
//         uploadTask = fileRef.putData(file.bytes!);
//       } else {
//         // For mobile
//         uploadTask = fileRef.putFile(File(file.path!));
//       }
//
//       final snapshot = await uploadTask;
//       final downloadURL = await snapshot.ref.getDownloadURL();
//
//       Get.snackbar(
//         'Success',
//         'File uploaded successfully!',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );
//
//       return downloadURL;
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to upload file: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       throw e;
//     } finally {
//       setState(() {
//         isFileUploading = false;
//       });
//     }
//   }
//
//   Future<String> saveDataWithAutoId({
//     required String className,
//     required String semester,
//     required String subject,
//     required Map<String, dynamic> data,
//   }) async {
//     try {
//       final CollectionReference collectionRef = FirebaseFirestore.instance
//           .collection(className)
//           .doc(semester)
//           .collection(subject);
//
//       final DocumentReference docRef = await collectionRef.add(data);
//
//       print('Data saved successfully with auto-generated ID: ${docRef.id}');
//       return docRef.id;
//     } catch (e) {
//       print('Error saving data: $e');
//       throw e;
//     }
//   }
//
//   void _pickImage() async {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Select Image Source'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: Icon(Icons.photo_library),
//               title: Text('Gallery'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 final ImagePicker picker = ImagePicker();
//                 final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//
//                 if (image != null) {
//                   try {
//                     final downloadURL = await uploadImageToFirebase(image);
//                     setState(() {
//                       _imageController.text = downloadURL;
//                     });
//                   } catch (e) {
//                     // Error handled in uploadImageToFirebase
//                   }
//                 }
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.camera_alt),
//               title: Text('Camera'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 final ImagePicker picker = ImagePicker();
//                 final XFile? image = await picker.pickImage(source: ImageSource.camera);
//
//                 if (image != null) {
//                   try {
//                     final downloadURL = await uploadImageToFirebase(image);
//                     setState(() {
//                       _imageController.text = downloadURL;
//                     });
//                   } catch (e) {
//                     // Error handled in uploadImageToFirebase
//                   }
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
//       );
//
//       if (result != null) {
//         PlatformFile file = result.files.first;
//         final downloadURL = await uploadFileToFirebase(file);
//         setState(() {
//           _sourceController.text = downloadURL;
//         });
//       }
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Failed to pick file: $e',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text(
//           'Admin Panel',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: selectedColor,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [selectedColor.withOpacity(0.1), Colors.white],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(20),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(15),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.admin_panel_settings,
//                         size: 50,
//                         color: selectedColor,
//                       ),
//                       SizedBox(height: 10),
//                       Text(
//                         'Add New Material',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.grey[800],
//                         ),
//                       ),
//                       Text(
//                         'Fill in the details below',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 SizedBox(height: 25),
//
//                 // Text Fields Section
//                 _buildSectionTitle('Material Information'),
//                 SizedBox(height: 15),
//
//                 // Class Name Field
//                 _buildTextField(
//                   controller: classController,
//                   label: 'Class Name',
//                   hint: 'Enter Class',
//                   icon: Icons.clear_all_sharp,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter class name';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Semester Field
//                 _buildTextField(
//                   controller: semController,
//                   label: 'Semester',
//                   hint: 'Enter sem',
//                   icon: Icons.numbers,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter semester';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Subject Field
//                 _buildTextField(
//                   controller: subjectController,
//                   label: 'Subject Name',
//                   hint: 'Enter subject name',
//                   icon: Icons.book,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter subject name';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Material Name Field
//                 _buildTextField(
//                   controller: _nameController,
//                   label: 'Material Name',
//                   hint: 'Enter material name',
//                   icon: Icons.book,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter material name';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Type Field
//                 _buildTextField(
//                   controller: _typeController,
//                   label: 'Material Type',
//                   hint: 'e.g., PDF, Video, Audio',
//                   icon: Icons.category,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter material type';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Source Field with File Picker
//                 _buildTextFieldWithSuffix(
//                   controller: _sourceController,
//                   label: 'Source URL',
//                   hint: 'Enter source URL or pick file',
//                   icon: Icons.link,
//                   suffixIcon: isFileUploading
//                       ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                       : IconButton(
//                     icon: Icon(Icons.attach_file, color: selectedColor),
//                     onPressed: _pickFile,
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter source URL or pick a file';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Price Field
//                 _buildTextField(
//                   controller: _priceController,
//                   label: 'Price',
//                   hint: 'Enter price (0 for free)',
//                   icon: Icons.attach_money,
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter price';
//                     }
//                     if (int.tryParse(value) == null) {
//                       return 'Please enter a valid number';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Image URL Field with Image Picker
//                 _buildTextFieldWithSuffix(
//                   controller: _imageController,
//                   label: 'Image URL',
//                   hint: 'Enter image URL or pick image',
//                   icon: Icons.image,
//                   suffixIcon: isImageUploading
//                       ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                       : IconButton(
//                     icon: Icon(Icons.add_a_photo, color: selectedColor),
//                     onPressed: _pickImage,
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter image URL or pick an image';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 15),
//
//                 // Description Field
//                 _buildTextField(
//                   controller: _descriptionController,
//                   label: 'Description',
//                   hint: 'Enter material description',
//                   icon: Icons.description,
//                   maxLines: 3,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter description';
//                     }
//                     return null;
//                   },
//                 ),
//
//                 SizedBox(height: 30),
//
//                 // Color Picker Section
//                 _buildSectionTitle('Theme Color'),
//                 SizedBox(height: 15),
//
//                 _buildColorPicker(),
//
//                 SizedBox(height: 40),
//
//                 // Submit Button
//                 _buildSubmitButton(),
//
//                 SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: Colors.grey[800],
//       ),
//     );
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//     String? Function(String?)? validator,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         validator: validator,
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: hint,
//           prefixIcon: Icon(icon, color: selectedColor),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey.shade200),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: selectedColor, width: 2),
//           ),
//           errorBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.red, width: 2),
//           ),
//           filled: true,
//           fillColor: Colors.white,
//           labelStyle: TextStyle(color: selectedColor),
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextFieldWithSuffix({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     required Widget suffixIcon,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//     String? Function(String?)? validator,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         validator: validator,
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: hint,
//           prefixIcon: Icon(icon, color: selectedColor),
//           suffixIcon: suffixIcon,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey.shade200),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: selectedColor, width: 2),
//           ),
//           errorBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.red, width: 2),
//           ),
//           filled: true,
//           fillColor: Colors.white,
//           labelStyle: TextStyle(color: selectedColor),
//           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildColorPicker() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Select Theme Color',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[800],
//               ),
//             ),
//             SizedBox(height: 15),
//
//             // Color Preview
//             GestureDetector(
//               onTap: _showColorPicker,
//               child: Container(
//                 width: double.infinity,
//                 height: 60,
//                 decoration: BoxDecoration(
//                   color: selectedColor,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: Colors.grey.shade300, width: 2),
//                   boxShadow: [
//                     BoxShadow(
//                       color: selectedColor.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.palette,
//                         color: selectedColor.computeLuminance() > 0.5
//                             ? Colors.black
//                             : Colors.white,
//                       ),
//                       SizedBox(width: 10),
//                       Text(
//                         'Tap to change color',
//                         style: TextStyle(
//                           color: selectedColor.computeLuminance() > 0.5
//                               ? Colors.black
//                               : Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//
//             SizedBox(height: 10),
//
//             // Color Code Display
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 'Color Code: #${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontFamily: 'monospace',
//                   color: Colors.grey[700],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSubmitButton() {
//     return Container(
//       width: double.infinity,
//       height: 56,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [selectedColor, selectedColor.withOpacity(0.8)],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: selectedColor.withOpacity(0.3),
//             blurRadius: 12,
//             offset: Offset(0, 6),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed: (isLoading || isImageUploading || isFileUploading) ? null : _submitForm,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: isLoading
//             ? SizedBox(
//           width: 24,
//           height: 24,
//           child: CircularProgressIndicator(
//             color: Colors.white,
//             strokeWidth: 2,
//           ),
//         )
//             : Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.save, color: Colors.white),
//             SizedBox(width: 10),
//             Text(
//               'Save Material',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showColorPicker() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Pick a Color'),
//         content: SingleChildScrollView(
//           child: ColorPicker(
//             pickerColor: selectedColor,
//             onColorChanged: (Color color) {
//               setState(() {
//                 selectedColor = color;
//               });
//             },
//             showLabel: true,
//             pickerAreaHeightPercent: 0.8,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               setState(() {});
//             },
//             child: Text('Select'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         isLoading = true;
//       });
//
//       try {
//         // Create material data
//         final materialData = {
//           'name': _nameController.text,
//           'type': _typeController.text,
//           'source': _sourceController.text,
//           'price': int.parse(_priceController.text),
//           'image': _imageController.text,
//           'description': _descriptionController.text,
//           'color': '#${selectedColor.value.toRadixString(16).substring(2)}',
//         };
//
//         // Save to Firestore with auto-generated document ID
//         String docId = await saveDataWithAutoId(
//           className: classController.text,
//           semester: semController.text,
//           subject: subjectController.text,
//           data: materialData,
//         );
//
//         // Show success message
//         Get.snackbar(
//           'Success',
//           'Material added successfully!\nDocument ID: $docId',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.green,
//           colorText: Colors.white,
//           icon: Icon(Icons.check_circle, color: Colors.white),
//           duration: Duration(seconds: 4),
//         );
//
//         // Clear form
//         _clearForm();
//       } catch (e) {
//         Get.snackbar(
//           'Error',
//           'Failed to add material: $e',
//           snackPosition: SnackPosition.BOTTOM,
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//           icon: Icon(Icons.error, color: Colors.white),
//         );
//       } finally {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }
//
//   void _clearForm() {
//     _nameController.clear();
//     _typeController.clear();
//     _sourceController.clear();
//     _priceController.clear();
//     _imageController.clear();
//     _descriptionController.clear();
//     setState(() {
//       selectedColor = Color(0xFF2196F3);
//     });
//   }
// }
