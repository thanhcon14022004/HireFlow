import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Shimmer effect without any extra package.
///
/// Wrap a tree of [SkeletonBox] / [SkeletonCircle] widgets in a [Shimmer];
/// the light band sweeps across every opaque pixel of the child.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;

  const Shimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the "reduce motion" accessibility setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(_controller.value * 2 - 1),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Rounded rectangle placeholder. Must be placed under a [Shimmer].
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // replaced by the shimmer gradient
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Circular placeholder (avatars, icons). Must be placed under a [Shimmer].
class SkeletonCircle extends StatelessWidget {
  final double size;
  const SkeletonCircle({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );
  }
}

/// White card frame shared by all skeleton cards, matching the real cards.
class _SkeletonCardFrame extends StatelessWidget {
  final Widget child;
  const _SkeletonCardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Shimmer(child: child),
    );
  }
}

/// Placeholder that mimics the job card in the freelancer "Tìm việc" tab.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 44, height: 44, radius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 11),
                    SizedBox(height: 8),
                    SkeletonBox(height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 14),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              SkeletonBox(width: 70, height: 22, radius: 11),
              SizedBox(width: 8),
              SkeletonBox(width: 60, height: 22, radius: 11),
              SizedBox(width: 8),
              SkeletonBox(width: 80, height: 22, radius: 11),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 110, height: 16),
              SkeletonBox(width: 70, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Placeholder that mimics the card in "Hồ sơ ứng tuyển".
class ApplicationCardSkeleton extends StatelessWidget {
  const ApplicationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: SkeletonBox(height: 15)),
              SizedBox(width: 24),
              SkeletonBox(width: 80, height: 22, radius: 11),
            ],
          ),
          SizedBox(height: 10),
          SkeletonBox(width: 200, height: 12),
          SizedBox(height: 14),
          SkeletonBox(height: 8, radius: 4),
          SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 120, height: 26, radius: 6),
          ),
        ],
      ),
    );
  }
}

/// Generic "avatar + two lines" row for admin / employer / wallet lists.
class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _SkeletonCardFrame(
      child: Row(
        children: const [
          SkeletonCircle(size: 40),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 140, height: 11),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBox(width: 56, height: 20, radius: 10),
        ],
      ),
    );
  }
}

enum SkeletonType { jobCard, applicationCard, listTile }

/// Drop-in replacement for a centred `CircularProgressIndicator` while a list
/// is loading.
///
/// * Full-screen lists: `const SkeletonList(type: SkeletonType.jobCard)`
/// * Lists nested inside another scroll view: pass `shrinkWrap: true`.
class SkeletonList extends StatelessWidget {
  final SkeletonType type;
  final int itemCount;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.type = SkeletonType.jobCard,
    this.itemCount = 6,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.all(12),
  });

  Widget _item() {
    switch (type) {
      case SkeletonType.jobCard:
        return const JobCardSkeleton();
      case SkeletonType.applicationCard:
        return const ApplicationCardSkeleton();
      case SkeletonType.listTile:
        return const ListTileSkeleton();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Đang tải dữ liệu',
      child: ListView.separated(
        padding: shrinkWrap ? EdgeInsets.zero : padding,
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => _item(),
      ),
    );
  }
}
