# mago_calendar

A Flutter package for integrating Google and Microsoft calendar OAuth and booking sync.

## Features

- **Google Calendar Integration**: OAuth sign-in and calendar event sync using Google Workspace APIs
- **Microsoft 365 Integration**: OAuth sign-in and calendar event sync using Microsoft Graph API
- **Incremental Sync**: Support for delta/incremental sync to efficiently fetch only changed events
- **Ready-to-use Widgets**: Pre-built UI components for calendar connection and booking display
- **Cross-platform**: Works on Android, iOS, Windows, macOS, Linux, and Web

## Getting started

### Prerequisites

1. Set up OAuth credentials for Google and/or Microsoft:
   - **Google**: Create credentials in [Google Cloud Console](https://console.cloud.google.com/)
   - **Microsoft**: Register an app in [Azure Portal](https://portal.azure.com/)

2. Create a `.env` file in your project root with the following keys:
   ```
   MICROSOFT_CLIENT_ID=your_microsoft_client_id
   MICROSOFT_CLIENT_SECRET=your_microsoft_client_secret
   GOOGLE_WEB_CLIENT_ID=your_google_web_client_id
   GOOGLE_ANDROID_CLIENT_ID=your_google_android_client_id
   GOOGLE_WINDOWS_CLIENT_ID=your_google_windows_client_id
   GOOGLE_WINDOWS_CLIENT_SECRET=your_google_windows_client_secret
   ```

3. Add the `.env` file to your `pubspec.yaml` assets:
   ```yaml
   flutter:
     assets:
       - .env
   ```

4. **For Web**: Copy the `auth.html` callback page to your `web/` folder:
   ```bash
   # From your Flutter project root:
   cp .pub-cache/git/mago_calendar-*/assets/web/auth.html web/auth.html
   ```
   Or manually create `web/auth.html` with this content:
   ```html
   <!DOCTYPE html>
   <html>
   <head><meta charset="UTF-8"><title>Authentication</title></head>
   <body>
     <p>Signing in...</p>
     <script>
       const url = window.location.href;
       if (window.opener) {
         window.opener.postMessage(url, window.location.origin);
         window.close();
       }
     </script>
   </body>
   </html>
   ```

## Usage

### Initialize the environment

```dart
import 'package:mago_calendar/mago_calendar.dart';

void main() async {
  await loadMagoCalendarEnv();
  runApp(MyApp());
}
```

### Use the CalendarHomePage widget

```dart
import 'package:mago_calendar/mago_calendar.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CalendarHomePage(),
    );
  }
}
```

### Use the auth clients directly

```dart
import 'package:mago_calendar/mago_calendar.dart';

// Google Calendar
final googleClient = GoogleAuthClient();
await googleClient.signIn();
final bookings = await googleClient.fetchBookings(
  start: DateTime.now(),
  end: DateTime.now().add(Duration(days: 7)),
);

// Microsoft 365
final microsoftClient = MicrosoftAuthClient();
await microsoftClient.signIn();
final msBookings = await microsoftClient.fetchBookings(
  start: DateTime.now(),
  end: DateTime.now().add(Duration(days: 7)),
);
```

## Exported APIs

### Models
- `Booking` - Represents a calendar event
- `BookingSource` - Enum for event source (google, microsoft)
- `OAuthToken` - OAuth token with expiration handling
- `SyncResult` - Result of incremental sync operation

### Services
- `GoogleAuthClient` - Google OAuth and Calendar API client
- `MicrosoftAuthClient` - Microsoft OAuth and Graph API client

### Widgets
- `CalendarHomePage` - Complete calendar connection and display page
- `ActionCard` - Card widget for auth actions
- `BookingTile` - Widget to display a single booking
- `ConfigStatus` - Widget showing configuration status

### Utilities
- `loadMagoCalendarEnv()` - Load environment configuration
- `formatDateTime()` / `formatTime()` - Date/time formatting helpers

