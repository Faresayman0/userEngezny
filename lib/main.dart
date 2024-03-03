import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradution_project2/app_routes.dart';
import 'package:gradution_project2/bussines_logic/cubit/phone_auth_cubit.dart';
import 'package:gradution_project2/constant/strings.dart';
import 'package:gradution_project2/firebase_options.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  String initialRoute = '/';

  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) {
      initialRoute = animitedSplashScreen;
    } else {
      initialRoute = navBar;
    }

    runApp(GraduationProject(
      appRouter: AppRouter(),
      phoneAuthCubit: PhoneAuthCubit(),
      initialRoute: initialRoute,
    ));
  });
}

class GraduationProject extends StatelessWidget {
  final AppRouter appRouter;
  final PhoneAuthCubit phoneAuthCubit;
  final String initialRoute;

  const GraduationProject({
    super.key,
    required this.appRouter,
    required this.phoneAuthCubit,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PhoneAuthCubit>.value(
      value: phoneAuthCubit,
      child: MaterialApp(
        theme: ThemeData(
            fontFamily: "LamaSans",
            primaryColor: Colors.blue,
            textSelectionTheme: const TextSelectionThemeData(
                selectionColor: Colors.blue,
                cursorColor: Colors.blue,
                selectionHandleColor: Colors.blue)),
        debugShowCheckedModeBanner: false,
        initialRoute: initialRoute,
        onGenerateRoute: appRouter.generateRoute,
      ),
    );
  }
}
