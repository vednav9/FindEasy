import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'main.dart';
import 'pages/Customer/booking_detail_screen.dart';
import 'pages/Customer/edit_profile_screen.dart';
import 'pages/Customer/profile_screen.dart';
import 'pages/Customer/special_offer_screen.dart';
import 'pages/Provider/provide_profile_screen.dart';
import 'pages/Provider/provider_edit_profile_screen.dart';
import 'provider_register_screen.dart';
import 'register_screen.dart';

class AppRoutes {
  static const String authCheck = '/';
  static const String login = "/login";
  static const String register = "/register";
  static const String forgotPassword = "/forgot_password";
  static const String providerRegister = "/provider_register";
  static const String customerHome = "/customer_home";
  static const String providerHome = "/provider_home";
  static const String search = "/search_screen";
  static const String booking = "/booking_screen";
  static const String providerBooking = "/provider_booking_screen";
  static const String customerProfile = "/profile_screen";
  static const String providerProfile = "/provider_profile_screen";
  static const String specialOffer = "/special_offer";
  static const String fcmLanding = "/fcm_landing";
  static const String bookingDetail = "/booking_detail";
  static const String editProfile = "/edit_profile";
  static const String providerEditProfile = "/provider_edit_profile";

  static final Map<String, WidgetBuilder> routes = {
    authCheck: (context) => AuthCheck(),
    login: (context) => LoginScreen(),
    register: (context) => RegisterScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
    providerRegister: (context) => ProviderRegisterScreen(),
    customerHome:
        (context) => BottomNavBarWrapper(userType: "customer", initialIndex: 0),
    providerHome:
        (context) => BottomNavBarWrapper(userType: "provider", initialIndex: 0),
    search:
        (context) => BottomNavBarWrapper(userType: "customer", initialIndex: 1),
    booking:
        (context) => BottomNavBarWrapper(userType: "customer", initialIndex: 2),
    providerBooking:
        (context) => BottomNavBarWrapper(userType: "provider", initialIndex: 2),
    customerProfile: (context) => ProfileScreen(),
    providerProfile: (context) => ProviderProfileScreen(),
    specialOffer: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      return SpecialOfferScreen(
        id: args["id"] ?? "",
        imagePath: args["imagePath"] ?? "",
        title: args["title"] ?? "",
        offerDetails: args["offerDetails"] ?? "",
        validity: args["validity"] ?? "",
        terms: List<String>.from(args["terms"] ?? []),
        rating: args["rating"] ?? 0,
        reviews: List<Map<String, dynamic>>.from(args["reviews"] ?? []),
      );
    },
    fcmLanding:
        (context) => const Scaffold(
          body: Center(child: Text("Opened from Notification")),
        ), // placeholder
    bookingDetail: (context) {
      final bookingData =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return BookingDetailScreen(bookingId: bookingData['bookingId']);
    },
    editProfile: (context) => const EditProfileScreen(),
    providerEditProfile: (context) => const ProviderEditProfileScreen(),
  };
}
