import 'package:flutter/material.dart';
import '../utils/colors.dart';

class HeaderContainer extends StatelessWidget {
  final String text;

  const HeaderContainer({super.key, required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.orangeColors, AppColors.orangeLightColors],
              end: Alignment.bottomCenter,
              begin: Alignment.topCenter),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(100))),
      child: Stack(
        children: <Widget>[
          Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 20),
            )),
          Center(
            child: Image.asset("assets/logo_rsu.png"),
          ),
        ],
      ),
    );
  }
}