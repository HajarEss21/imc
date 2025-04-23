import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:imc_secured/language_Switcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'bmi_history.dart';
import 'home.dart';
import 'firebase_options.dart';
import 'language_provider.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseUIAuth.configureProviders([EmailAuthProvider()]);

    runApp(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MyApp(),
      ),
    );
  } catch (err) {
    print("Firebase initialization failed: $err");
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Home(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(
          headerBuilder: (context, constraints, _) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: LanguageSwitcher(), 
              ),
            );
          },
          actions: [
            ForgotPasswordAction((context, email) {
              context.push('/forgot-password', extra: email);
            }),
            AuthStateChangeAction((context, state) {
              if (state is SignedIn || state is UserCreated) {
                context.pushReplacement('/');
              }
            }),
          ],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final email = state.extra as String?;
          return ForgotPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => BMIHistoryScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp.router(
          routerConfig: _router,
          theme: ThemeData(
            brightness: Brightness.light,  // Set the brightness to light theme
            primaryColor: Colors.deepPurple, // Set background color
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.black), // Set text color
              bodyMedium: TextStyle(color: Colors.black54), // Set secondary text color
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: Colors.deepPurple,  // Set button color
              textTheme: ButtonTextTheme.primary,  // Button text color
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.deepPurple, // Set app bar color
              titleTextStyle: TextStyle(color: Colors.white), // Set app bar title text color
            ),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.deepPurple), // Set focus border color
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey), // Set default border color
              ),
              labelStyle: TextStyle(color: Colors.deepPurple), // Set label text color
            ), colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orange).copyWith(background: Colors.grey[200]),
          ),
          debugShowCheckedModeBanner: false,

          // Configuration des localisations
          locale: languageProvider.locale,
         localizationsDelegates: [
  AppLocalizations.delegate, // Correct access to the static getter using the class name
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  FirebaseUILocalizations.delegate, // Firebase UI localization
],
          supportedLocales: [
            Locale('en'), // English
            Locale('fr'), // French
            Locale('ar'), // Arabic
            Locale('es'), // Spanish
          ],

          // Pour gérer correctement le RTL (pour l'arabe)
          builder: (context, child) {
            TextDirection textDirection = languageProvider.locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr;

            return Directionality(
              textDirection: textDirection,
              child: child!,
            );
          },
        );
      },
    );
  }
}
