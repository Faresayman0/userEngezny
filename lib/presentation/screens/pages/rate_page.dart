import 'package:flutter/material.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';
import 'package:gradution_project2/presentation/widgets/rate_widget.dart';

class RatePage extends StatelessWidget {
  const RatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(children: [
          SizedBox(
            height: 200,
            child: ConstantWidget(),
          ),
          SizedBox(
            height: 4,
          ),
          RatingWidget()
        ]),
      ),
    );
  }
}
