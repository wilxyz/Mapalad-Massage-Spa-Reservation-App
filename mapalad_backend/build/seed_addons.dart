import 'lib/firestore_rest_service.dart';

Future<void> main() async {
  final addOns = [
    {'addOnName': 'Ear Candling', 'price': 299.0, 'duration': '15 MINS'},
    {'addOnName': 'Mark Bentusa Therapy', 'price': 499.0, 'duration': '15 MINS'},
    {'addOnName': 'Facial Mask Treatment', 'price': 499.0, 'duration': '15 MINS'},
  ];
  for (final addOn in addOns) {
    await FirestoreRestService.addDocument('add_ons', addOn);
  }
  print('Add-ons seeded.');
}