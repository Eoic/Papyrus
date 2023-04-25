import 'package:flutter/material.dart';

class ProfileButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Function? onPressed;

  const ProfileButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onPressed?.call(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2)
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary,),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)
        ),
        child: const Icon(Icons.arrow_right),
      ),
    );
  }
}
