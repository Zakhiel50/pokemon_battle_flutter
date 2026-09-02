import 'package:flutter/material.dart';

import '../models/card-models.dart';

class PokemonCard extends StatelessWidget {
  final PokemonData data;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? width;

  const PokemonCard({
    super.key,
    required this.data,
    this.onTap,
    this.isSelected = false,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : Colors.transparent,
            width: isSelected ? 4 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.amber.withValues(alpha: 0.8)
                  : Colors.black38,
              blurRadius: isSelected ? 14 : 8,
              spreadRadius: isSelected ? 4 : 1,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                data.imageUrl,
                width: cardWidth,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: cardWidth,
                    height: cardWidth != null ? cardWidth * 1.4 : 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: cardWidth,
                  height: cardWidth != null ? cardWidth * 1.4 : 200,
                  color: Colors.grey.shade300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Badge Sélectionné
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
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
