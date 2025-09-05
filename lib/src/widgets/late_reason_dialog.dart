import 'package:flutter/material.dart';



Future<String?> showLateReasonDialog(BuildContext context) async{
  String value = '';
  return showDialog<String>(
  context : context,
  builder: (ctx){
   return AlertDialog(
    title: const Text('Late reason'),
    content: TextField(
      autofocus: true,
      onChanged: (v) => value = v.trim(),
      decoration: const InputDecoration(
        hintText: 'Enter reason',
      ),
    ),
    actions:[
    TextButton(
    onPressed: () => Navigator.pop(ctx),
    child: const Text('Cancel'),
    ),
    ElevatedButton(
    onPressed: () {
    if(value.isEmpty) return;
    Navigator.pop(ctx, value);
    },
    child:const Text('Save'),
    ),
    ],
    );
  },
 );
}
