import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/presentation/widgets/constant_widget.dart';
import 'package:gradution_project2/presentation/widgets/nav_bar2new.dart';
import 'package:gradution_project2/presentation/widgets/navbar.dart';

class ChoseLogin extends StatefulWidget {
  const ChoseLogin({Key? key}) : super(key: key);

  @override
  _ChoseLoginState createState() => _ChoseLoginState();
}

class _ChoseLoginState extends State<ChoseLogin> {
  bool isLoading = false;

  Future signInWithGoogle(BuildContext context) async {
    setState(() {
      isLoading = true; // يتم تعيين isLoading للقيمة true هنا لإظهار مؤشر التحميل
    });

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      setState(() {
        isLoading = false; // يتم تعيين isLoading للقيمة false هنا لإخفاء مؤشر التحميل
      });
      return;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // Navigate after successful sign-in
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) {
        return const Navbar();
      }),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleBackButton(context);
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        child: ConstantWidget(),
                      ),
                      SizedBox(height: 90),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            setState(() {
                              isLoading = true;
                            });
                            await Navigator.pushNamed(context, loginScreen);

                            setState(() {
                              isLoading = false;
                            });
                          },
                          icon: const Icon(Icons.phone, color: Colors.white),
                          label: const Text("تسجيل الدخول باستخدام رقم الهاتف",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Row(
                        children: [
                          Expanded(
                              child: Divider(
                            endIndent: 14,
                            color: Colors.blue,
                          )),
                          Text("or"),
                          Expanded(
                              child: Divider(
                            indent: 14,
                            color: Colors.blue,
                          )),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  // Loading while signing in with Google
                                  signInWithGoogle(context);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "asset/images/search.png",
                                      height: 20,
                                    ),
                                    const Text(
                                      "   تسجيل الدخول باستخدام جوجل  ",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Row(
                        children: [
                          Expanded(
                              child: Divider(
                            endIndent: 14,
                            color: Colors.blue,
                          )),
                          Text("or"),
                          Expanded(
                              child: Divider(
                            indent: 14,
                            color: Colors.blue,
                          )),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () {
                                  // Loading while signing in as a guest
                                  setState(() {
                                    isLoading = true;
                                  });
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) {
                                      return const NavBarNew();
                                    }),
                                    (route) => false,
                                  );

                                  // Update isLoading value after navigation
                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      "   الدخول كضيف",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 1),
                      const Text(
                        "powered by",
                        style: TextStyle(color: Colors.blue, fontSize: 20),
                      ),
                      const Text(
                        "Engzny Team",
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    if (isLoading) {
      return false;
    } else {
      await _logOutOrExitApp(context);
      return true;
    }
  }

  Future<void> _logOutOrExitApp(BuildContext context) async {
    SystemNavigator.pop();
  }
}
