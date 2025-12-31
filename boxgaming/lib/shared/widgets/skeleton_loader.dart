import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader for venue cards
class VenueCardSkeleton extends StatelessWidget {
  const VenueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A1A),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 20, width: 200, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 150, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 100, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for venues list
class VenuesListSkeleton extends StatelessWidget {
  const VenuesListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Show 5 skeleton cards
      itemBuilder: (context, index) => const VenueCardSkeleton(),
    );
  }
}

/// Skeleton loader for booking cards
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 18, width: 150, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 14, width: 120, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 14, width: 100, color: Colors.white),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(height: 14, width: 100, color: Colors.white),
                  const SizedBox(width: 16),
                  Container(height: 14, width: 80, color: Colors.white),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(height: 16, width: 80, color: Colors.white),
                  Container(height: 12, width: 100, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for bookings list
class BookingsListSkeleton extends StatelessWidget {
  const BookingsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const BookingCardSkeleton(),
    );
  }
}

/// Skeleton loader for dashboard stats cards
class DashboardStatsSkeleton extends StatelessWidget {
  const DashboardStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.grey[800],
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 100, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 24, width: 80, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.grey[800],
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 100, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(height: 24, width: 60, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

