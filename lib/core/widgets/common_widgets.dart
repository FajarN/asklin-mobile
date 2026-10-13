import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Header melengkung merah dengan ornamen khas ASKLIN
class AsklinHeaderOrnament extends StatelessWidget {
  final double height;
  final Widget? child;

  const AsklinHeaderOrnament({
    Key? key,
    this.height = 220,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: _WaveHeaderClipper(),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryRed, AppColors.primaryDarkRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        if (child != null)
          SafeArea(
            child: SizedBox(
              height: height - 30,
              child: child!,
            ),
          ),
      ],
    );
  }
}

class _WaveHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 45);
    var secondEndPoint = Offset(size.width, size.height - 15);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Tombol Merah Khas ASKLIN
class AsklinPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AsklinPrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Status Badge (Aktif / Pending / Nonaktif)
class AsklinStatusBadge extends StatelessWidget {
  final String status;
  final bool isApproved;

  const AsklinStatusBadge({
    Key? key,
    required this.status,
    this.isApproved = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg = isApproved ? AppColors.statusGreenBg : AppColors.statusYellowBg;
    Color textCol = isApproved ? AppColors.statusGreen : AppColors.statusYellow;
    String label = isApproved ? 'Terverifikasi / Aktif' : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.verified : Icons.access_time_rounded,
            size: 14,
            color: textCol,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textCol,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip Filter Kategori (Merah Lembut jika aktif)
class AsklinCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const AsklinCategoryChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.borderSubtle,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
