import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Full-screen shimmer placeholder displayed while the initial batch
/// of reels loads from Firestore.
///
/// The shimmer effect gives the user visual feedback that content is loading
/// (not frozen/crashed), and the layout mimics the actual reel structure
/// so there's no jarring layout shift when real content appears.
class ShimmerLoadingWidget extends StatelessWidget {
  const ShimmerLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // Dark shimmer colors because the app background is pure black.
      // Standard light-grey shimmer would look out of place here.
      baseColor: Colors.grey.shade900,
      highlightColor: Colors.grey.shade800,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center video loading placeholder
              Expanded(
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom UI and Right Sidebar simulation
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left side (Text)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simulates the username text
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Simulates two lines of description text
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 200,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Simulates the music ticker bar
                        Container(
                          width: 180,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right side (Action buttons)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildShimmerCircle(48),
                      const SizedBox(height: 16),
                      _buildShimmerCircle(40),
                      const SizedBox(height: 16),
                      _buildShimmerCircle(40),
                      const SizedBox(height: 16),
                      _buildShimmerCircle(40),
                      const SizedBox(height: 16),
                      _buildShimmerCircle(32),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
