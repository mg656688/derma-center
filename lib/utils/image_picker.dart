import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class ImagePickerContainer extends StatelessWidget {
  final File? image;
  final VoidCallback onPressed;

  const ImagePickerContainer({required this.image, required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      dashPattern: [10, 6],
      color: Colors.deepPurpleAccent,
      borderType: BorderType.RRect,
      radius: Radius.circular(12),
      strokeWidth: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            image: image != null
                ? DecorationImage(
              image: FileImage(image!),
              fit: BoxFit.cover,
            )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: image == null
              ? Center(
            child: IconButton(
              icon: Icon(
                Icons.add_a_photo,
                color: Colors.deepPurpleAccent,
                size: 40,
              ),
              onPressed: onPressed,
            ),
          )
              : null,
        ),
      ),
    );
  }
}
var primaryColor = Color.fromARGB(255, 61, 202, 148);
