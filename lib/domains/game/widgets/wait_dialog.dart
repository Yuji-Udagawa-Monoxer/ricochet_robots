import 'package:flutter/material.dart';

class WaitDialog extends StatelessWidget {
  const WaitDialog({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: const AlertDialog(
        title: Text('Waiting'),
        content: CircularProgressIndicator(),
      ),
    );
  }
}
