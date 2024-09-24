import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view_profile.dart';
import 'welcome.dart'; 

class Account extends StatelessWidget {
  const Account({super.key});

  Future<void> _logOut(BuildContext context) async {
    try {
      // Replace this with your actual logout implementation
      print('Logging out...');
      // Example: await AuthService.logout(); // This line should be replaced with actual logout code
      print('Logout successful');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } catch (e) {
      print('Logout Error: $e');
      throw Exception('Failed to log out');
    }
  }

  Future<bool> showLogOutDialog(BuildContext context) {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are You Sure You Want To Logout?'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Logout')),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'))
            ],
          );
        }).then((value) => value ?? false);
  }

  void showLogoutSuccessDialog(BuildContext context) {
    Future.delayed(Duration.zero, () {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Logged Out'),
            content: const Text('You have successfully logged out.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        centerTitle: true,
        backgroundColor: const Color(0xFF171B63),
        title: const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Account',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 380.0,
                height: 70.0,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey, 
                    width: 2.0, 
                  ),
                  borderRadius: BorderRadius.circular(10.0), 
                  color: Colors.transparent, 
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ViewProfile()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'images/account.png', 
                          width: 50.0, 
                          height: 50.0, 
                        ),
                      ),
                      const SizedBox(width: 20.0), 
                      const Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Color(0xFF171B63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0), 
              Container(
                width: 380.0,
                height: 70.0,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey, 
                    width: 2.0, 
                  ),
                  borderRadius: BorderRadius.circular(10.0), 
                  color: Colors.transparent, 
                ),
                child: InkWell(
                  onTap: () {
                    // Handle change password 
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'images/password.png', 
                          width: 50.0, 
                          height: 50.0, 
                        ),
                      ),
                      const SizedBox(width: 20.0), 
                      const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Color(0xFF171B63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Container(
                width: 380.0,
                height: 70.0,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey, 
                    width: 2.0, 
                  ),
                  borderRadius: BorderRadius.circular(10.0), 
                  color: Colors.transparent, 
                ),
                child: InkWell(
                  onTap: () async {
                    bool shouldLogOut = await showLogOutDialog(context);
                    if (shouldLogOut) {
                      await _logOut(context);
                      showLogoutSuccessDialog(context);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'images/logout.png', 
                          width: 50.0, 
                          height: 50.0, 
                        ),
                      ),
                      const SizedBox(width: 20.0), 
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Color(0xFF171B63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
