import 'dart:async';

import "package:flutter/material.dart";

class SplashScreenPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SplashScreenPageState();
  }
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  bool _visible = false;
  final textStyle = TextStyle(
    color: Colors.cyan[700],
    fontFamily: "A-Sensible-Armadillo",
    fontWeight: FontWeight.bold,
    fontSize: 50.0,
  );

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 50), () {
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(color: Colors.white),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: AnimatedOpacity(
                  opacity: _visible ? 1.00 : 0.0,
                  duration: Duration(milliseconds: 3500),
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Image(
                          height: 180,
                          width: 240,
                          image: AssetImage("assets/splash_screen.png"),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20.0),
                        ),
                        Text(
                          "TaskBud",
                          style: textStyle,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 80.0),
                        ),
                        CircularProgressIndicator(
                          valueColor: new AlwaysStoppedAnimation<Color>(
                              Colors.cyan[700]),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 20.0),
                        ),
                        Text(
                          "Built for You",
                          style: TextStyle(
                            fontFamily: "A-Sensible-Armadillo",
                            fontWeight: FontWeight.bold,
                            fontSize: 30.0,
                            color: Colors.cyan[700],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
