import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DropdownSearchInput<T> extends StatelessWidget {
  const DropdownSearchInput({
    super.key,
    required this.user,
    required this.hint,
    required this.icon,
    this.items,
    this.asyncItems,
    required this.onChanged,
    this.selectedItem,
    this.itemAsString,
    this.showSearchBox = true,
  });

  final String? user;
  final String? hint;
  final IconData? icon;
  final List<T>? items;
  final Future<List<T>> Function(String)? asyncItems;
  final ValueChanged<T?> onChanged;
  final T? selectedItem;
  final String Function(T)? itemAsString;
  final bool showSearchBox;

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
              color: user!.isURL ? Colors.transparent : const Color(0x59DDDDDD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: user!.isURL
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
            child: DropdownSearch<T>(
              items: (filter, infiniteScrollProps) async {
                if (asyncItems != null) {
                  return await asyncItems!(filter);
                }
                return items ?? [];
              },
              selectedItem: selectedItem,
              onSelected: onChanged,
              itemAsString: itemAsString,
              decoratorProps: DropDownDecoratorProps(
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                baseStyle: TextStyle(
                  color: Colors.black,
                  fontSize: Get.height * 0.02 + 3,
                  fontFamily: GoogleFonts.leagueSpartan(
                    fontWeight: FontWeight.w500,
                  ).fontFamily,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,

                  hintStyle: TextStyle(
                    color: const Color(0xFF818181),
                    fontSize: Get.height * 0.02 + 3,
                    fontFamily: GoogleFonts.leagueSpartan(
                      fontWeight: FontWeight.w400,
                    ).fontFamily,
                  ),
                  contentPadding: const EdgeInsets.only(left: 10),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: showSearchBox,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: "Search...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                menuProps: MenuProps(
                  backgroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
