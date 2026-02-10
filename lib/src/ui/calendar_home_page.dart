import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/auth_config.dart';
import '../models/booking.dart';
import '../models/sync_result.dart';
import '../services/google_auth_client.dart';
import '../services/microsoft_auth_client.dart';
import 'widgets/action_card.dart';
import 'widgets/booking_tile.dart';
import 'widgets/config_status.dart';

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  final MicrosoftAuthClient _microsoft = MicrosoftAuthClient();
  final GoogleAuthClient _google = GoogleAuthClient();

  final List<Booking> _bookings = [];
  final Map<String, Booking> _bookingById = {};
  bool _isLoading = false;
  String? _error;
  DateRangeFilter _rangeFilter = DateRangeFilter.daily;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _google.silentSignIn();
    _microsoft.restoreSession().then((_) {
      if (mounted) {
        setState(() {});
        _maybeAutoLoad();
      }
    });
    _google.authenticationState.listen((_) {
      if (mounted) {
        setState(() {});
        _maybeAutoLoad();
      }
    });
    _pollTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _maybeAutoLoad(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _connectMicrosoft() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      await _microsoft.signIn();
      _maybeAutoLoad();
    } catch (error) {
      _error = 'Microsoft sign-in failed: $error';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectGoogle() async {
    if (kIsWeb) {
      setState(() {
        _error = 'Google sign-in on web must use the provided sign-in button.';
      });
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      await _google.signIn();
      _maybeAutoLoad();
    } catch (error) {
      _error = 'Google sign-in failed: $error';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnectMicrosoft() async {
    setState(() {
      _microsoft.signOut();
      _microsoft.resetSync();
    });
  }

  Future<void> _disconnectGoogle() async {
    await _google.signOut();
    _google.resetSync();
    setState(() {});
  }

  bool _hasActiveConnection() => _microsoft.isSignedIn || _google.isSignedIn;

  Future<void> _maybeAutoLoad() async {
    if (!_hasActiveConnection() || _isLoading) {
      return;
    }
    await _syncBookings(forceFull: false);
  }

  Future<void> _loadBookings() async {
    await _syncBookings(forceFull: true);
  }

  Future<void> _syncBookings({bool forceFull = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (forceFull) {
        _bookingById.clear();
        _bookings.clear();
      }
    });

    final now = DateTime.now();
    final windowEnd = _rangeFilter.windowEnd(now);

    try {
      if (_microsoft.isSignedIn) {
        final result = await _microsoft.fetchChanges(
          start: now,
          end: windowEnd,
          forceFull: forceFull,
        );
        _applySync(result);
      }

      if (_google.isSignedIn) {
        final result = await _google.fetchChanges(
          start: now,
          end: windowEnd,
          forceFull: forceFull,
        );
        _applySync(result);
      }

      setState(() {
        _bookings
          ..clear()
          ..addAll(_bookingById.values)
          ..sort((a, b) => a.start.compareTo(b.start));
      });
    } catch (error) {
      setState(() {
        _error = 'Failed to load bookings: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applySync(SyncResult<Booking> result) {
    for (final removedId in result.removedIds) {
      _bookingById.remove(removedId);
    }
    for (final booking in result.upserts) {
      _bookingById[booking.id] = booking;
    }
  }

  @override
  Widget build(BuildContext context) {
    final microsoftConfigured = AuthConfig.microsoftClientId.isNotEmpty;
    final googleConfigured = AuthConfig.googleClientIdForPlatform().isNotEmpty;
    final googleWebButton = kIsWeb && !_google.isSignedIn
        ? _google.signInButton(
            onSignedIn: () {
              setState(() {
                _error = null;
              });
            },
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Connect'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect your Microsoft 365 and Google Workspace calendars to read bookings.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ConfigStatus(
              microsoftConfigured: microsoftConfigured,
              googleConfigured: googleConfigured,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionCard(
                  title: 'Microsoft 365',
                  subtitle: _microsoft.isSignedIn
                      ? 'Connected'
                      : 'Not connected',
                  primaryLabel: _microsoft.isSignedIn
                      ? 'Disconnect'
                      : 'Connect',
                  onPrimaryPressed: _microsoft.isSignedIn
                      ? _disconnectMicrosoft
                      : (microsoftConfigured ? _connectMicrosoft : null),
                  secondaryLabel: 'Scopes: Calendars.Read',
                ),
                ActionCard(
                  title: 'Google Workspace',
                  subtitle: _google.isSignedIn ? 'Connected' : 'Not connected',
                  primaryLabel: _google.isSignedIn ? 'Disconnect' : 'Connect',
                  primaryWidget: googleWebButton,
                  onPrimaryPressed: _google.isSignedIn
                      ? _disconnectGoogle
                      : (googleConfigured && !kIsWeb ? _connectGoogle : null),
                  secondaryLabel: 'Scopes: calendar.readonly',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                DropdownButton<DateRangeFilter>(
                  value: _rangeFilter,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _rangeFilter = value;
                            _microsoft.resetSync();
                            _google.resetSync();
                            _bookingById.clear();
                            _bookings.clear();
                          });
                          _syncBookings(forceFull: true);
                        },
                  items: DateRangeFilter.values
                      .map(
                        (range) => DropdownMenuItem(
                          value: range,
                          child: Text(range.label),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadBookings,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Load ${_rangeFilter.label.toLowerCase()}'),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _bookings.isEmpty
                  ? const Center(child: Text('No bookings loaded yet.'))
                  : ListView.separated(
                      itemCount: _bookings.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return BookingTile(booking: booking);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DateRangeFilter { daily, weekly, monthly }

extension DateRangeFilterUi on DateRangeFilter {
  String get label {
    switch (this) {
      case DateRangeFilter.daily:
        return 'Daily';
      case DateRangeFilter.weekly:
        return 'Weekly';
      case DateRangeFilter.monthly:
        return 'Monthly';
    }
  }

  DateTime windowEnd(DateTime start) {
    switch (this) {
      case DateRangeFilter.daily:
        return start.add(const Duration(days: 1));
      case DateRangeFilter.weekly:
        return start.add(const Duration(days: 7));
      case DateRangeFilter.monthly:
        return DateTime(start.year, start.month + 1, start.day);
    }
  }
}
