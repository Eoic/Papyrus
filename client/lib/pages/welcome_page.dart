import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const Spacer(),
              Column(
                children: [
                  const Image(
                    image: AssetImage("assets/images/logo.png"),
                    height: 150.0,
                  ),
                  Text(
                    "Papyrus",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 48
                    ),
                  ),
                  const Text(
                    "Your ultimate digital library",
                    style: TextStyle(
                      fontSize: 16.0
                    ),
                  )
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 12.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(50)),
                        elevation: const MaterialStatePropertyAll<double>(2.0),
                        backgroundColor: MaterialStatePropertyAll<Color>(Theme.of(context).colorScheme.primary),
                        foregroundColor: MaterialStatePropertyAll<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/register'
                        );
                      },
                      child: const Text("Get started")
                    ),
                    const SizedBox(height: 16.0,),
                    ElevatedButton(
                      style: const ButtonStyle(
                        minimumSize: MaterialStatePropertyAll<Size>(Size.fromHeight(50)),
                        elevation: MaterialStatePropertyAll<double>(2.0),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/'
                        );
                      },
                      child: const Text("Sign in")
                    ),
                    const SizedBox(height: 16.0),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Use offline mode"),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}