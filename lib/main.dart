import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizbit_2/app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
await dotenv.load(fileName:".env");

   WidgetsFlutterBinding.ensureInitialized();
   await MobileAds.instance.initialize();
  await Supabase.initialize(
  url: 'https://moysggirngqkxnhilosl.supabase.co',
  anonKey: 'sb_publishable_etTc3jUSj720tCb-M-ClPw_uBlv3b9T',
  );
  runApp(MainApp());
}