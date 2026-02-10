import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../utils/formatting.dart';

const _kAssetPackage = 'mago_calendar';

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    String? platformAsset;
    final descLower = booking.description.toLowerCase();
    if (descLower.contains('microsoft teams')) {
      platformAsset = 'assets/microsoft_teams.png';
    } else if (descLower.contains('google meet')) {
      platformAsset = 'assets/google_meet.png';
    } else if (descLower.contains('zoom meeting')) {
      platformAsset = 'assets/zoom.png';
    } else if (descLower.contains('webex meeting')) {
      platformAsset = 'assets/webex.png';
    }

    final platform = platformAsset != null
        ? Image.asset(
            platformAsset,
            package: _kAssetPackage,
            width: 24,
            height: 24,
          )
        : const Text('Other');

    final details = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${formatTime(booking.start)} to ${formatTime(booking.end)}'),
          platform,
        ],
      ),
      Text(
        booking.title.isEmpty ? '(No title)' : booking.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(
        booking.organizerName.isNotEmpty
            ? booking.organizerName
            : booking.organizerEmail,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => {},
            child: const Text('Join on screen'),
          ),
        ],
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details,
        ),
      ),
    );
  }
}
