import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../functions/firebase/google_sighnout.dart';

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return CupertinoAlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w400,
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Use dialogContext
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              await signOut();
            },
          ),
        ],
      );
    },
  );
}

