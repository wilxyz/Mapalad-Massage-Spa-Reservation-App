import 'lib/firestore_rest_service.dart';

Future<void> main() async {
  final categories = {
    'whole-body-massages': 'Whole Body Massages',
    'therapeutic-massages': 'Therapeutic Massages',
    'reflexology': 'Reflexology',
    'specialized-massages': 'Specialized Massages',
    'body-treatments': 'Body Treatments',
    'express-massages': 'Express Massages',
  };
  for (final entry in categories.entries) {
    await FirestoreRestService.setDocument('categories', entry.key, {'categoryName': entry.value});
  }
  print('Categories seeded.');

  final services = [
    {'serviceName': 'Swedish', 'price': 699.0, 'duration': '1 HR', 'categoryId': 'whole-body-massages'},
    {'serviceName': 'Regular Combination', 'price': 699.0, 'duration': '1 HR', 'categoryId': 'whole-body-massages'},
    {'serviceName': 'Thai Massage', 'price': 999.0, 'duration': '1 HR', 'categoryId': 'whole-body-massages'},
    {'serviceName': 'Customized Massage', 'price': 999.0, 'duration': '1 HR and 15 MINS', 'categoryId': 'whole-body-massages'},
    {'serviceName': 'Ala Eh! Masahe', 'price': 999.0, 'duration': '1 HR and 30 MINS', 'categoryId': 'therapeutic-massages'},
    {'serviceName': 'Traditional Hilot', 'price': 999.0, 'duration': '1 HR and 30 MINS', 'categoryId': 'therapeutic-massages'},
    {'serviceName': 'Deep Tissue', 'price': 999.0, 'duration': '1 HR and 15 MINS', 'categoryId': 'therapeutic-massages'},
    {'serviceName': 'Foot Reflexology', 'price': 499.0, 'duration': '30 MINS', 'categoryId': 'reflexology'},
    {'serviceName': 'Hand Reflexology', 'price': 499.0, 'duration': '30 MINS', 'categoryId': 'reflexology'},
    {'serviceName': 'Kiddie Massage', 'price': 599.0, 'duration': '45 MINS', 'categoryId': 'specialized-massages'},
    {'serviceName': 'Pre/Post Natal Therapy', 'price': 999.0, 'duration': '1 HR', 'categoryId': 'specialized-massages'},
    {'serviceName': 'Post Operation Massage Therapy', 'price': 999.0, 'duration': '1 HR', 'categoryId': 'specialized-massages'},
    {'serviceName': 'Sauna', 'price': 499.0, 'duration': '20 MINS', 'categoryId': 'body-treatments'},
    {'serviceName': 'Basic Footspa', 'price': 599.0, 'duration': '30 MINS', 'categoryId': 'body-treatments'},
    {'serviceName': 'Whole Body Scrub', 'price': 999.0, 'duration': '30 MINS', 'categoryId': 'body-treatments'},
    {'serviceName': '15 MINS Head Massage', 'price': 299.0, 'duration': '15 MINS', 'categoryId': 'express-massages'},
    {'serviceName': '30 MINS Back Massage', 'price': 499.0, 'duration': '30 MINS', 'categoryId': 'express-massages'},
  ];
  for (final service in services) {
    await FirestoreRestService.addDocument('services', service);
  }
  print('Services seeded.');

  final branches = [
    {'branchName': 'Mapalad Massage and Spa-Lipa Bayan', 'branchAddress': 'P. Torres St. corner Obispo Obviar St., Lipa City, Batangas'},
    {'branchName': 'Mapalad Massage and Spa-Tambo', 'branchAddress': '2nd Floor, Amerthyst Building, Tambo, Lipa City, Batangas'},
    {'branchName': 'Mapalad Massage and Spa-Ayala Highway', 'branchAddress': '3rd Floor, Desiree Building, Ayala Highway, Lipa City, Batangas'},
    {'branchName': 'Mapalad Massage and Spa-Marawouy', 'branchAddress': 'X568+M68, Marawouy, Lipa City, Batangas'},
    {'branchName': 'Mapalad Massage and Spa-Rosario Batangas', 'branchAddress': '2nd Floor, JCLC Building, Gualberto Avenue, Rosario, Batangas'},
    {'branchName': 'Mapalad Massage and Spa-Santo Tomas', 'branchAddress': 'Maharlika Highway, Santo Tomas, Batangas'},
    {'branchName': 'Mapalad Massage and Spa-Kumintang Batangas City', 'branchAddress': 'President Jose P. Laurel Highway, Kumintang, Batangas City'},
    {'branchName': 'Mapalad Massage and Spa Tagaytay', 'branchAddress': '320 Tagaytay–Calamba Road, Tagaytay City, Cavite'},
  ];
  for (final branch in branches) {
    await FirestoreRestService.addDocument('branches', branch);
  }
  print('Branches seeded.');

  print('All done!');
}