import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentRepository {
  static final PaymentRepository _instance = PaymentRepository._internal();
  late Razorpay _razorpay;

  PaymentRepository._internal() {
    _razorpay = Razorpay();
  }

  factory PaymentRepository() {
    return _instance;
  }

  Future<void> initializePayment({
    required Function(PaymentSuccessResponse) onPaymentSuccess,
    required Function(PaymentFailureResponse) onPaymentError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) async {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      onPaymentSuccess(response);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      onPaymentError(response);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      onExternalWallet(response);
    });
  }

  Future<void> startPayment({
    required String amount,
    required String description,
    String? phoneNumber,
    String razorpayKeyId = 'rzp_test_YOUR_KEY_HERE',
  }) async {
    var options = {
      'key': razorpayKeyId,
      'amount': amount,
      'name': 'MahaMaintain Pro',
      'description': description,
      'currency': 'INR',
      'prefill': {
        'contact': phoneNumber ?? '',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      throw Exception('Error starting payment: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
