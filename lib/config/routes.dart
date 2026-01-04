import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main_screen.dart';
import '../screens/timer_screen.dart';
import '../screens/goals_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String timer = '/timer';
  static const String goals = '/goals';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        main: (context) => const MainScreen(),
        timer: (context) => const TimerScreen(),
        goals: (context) => const GoalsScreen(),
      };
}
