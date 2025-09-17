import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast extends StatefulWidget {
  const CustomToast({super.key});

  @override
  State<CustomToast> createState() => _CustomToastState();
}

class _CustomToastState extends State<CustomToast> {
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  void showToastWithIcon(String message, IconData icon) {
    fToast.showToast(
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 16),
            Text(message, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
