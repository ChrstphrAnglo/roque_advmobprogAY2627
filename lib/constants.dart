import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

/// Flat delivery fee added to a non-empty cart at checkout.
const double deliveryFee = 4.99;
