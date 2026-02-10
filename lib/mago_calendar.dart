/// A Flutter package for integrating Google and Microsoft calendar OAuth
/// and booking sync.
library;

// Config
export 'src/config/auth_config.dart';

// Models
export 'src/models/booking.dart';
export 'src/models/oauth_token.dart';
export 'src/models/sync_result.dart';

// Services
export 'src/services/google_auth_client.dart';
export 'src/services/microsoft_auth_client.dart';

export 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    show
        GSIAPButtonUiConfig,
        GSIAPButtonType,
        GSIAPButtonTheme,
        GSIAPButtonSize,
        GSIAPButtonText,
        GSIAPButtonShape,
        GSIAPButtonLogoAlignment;

// UI
export 'src/ui/calendar_home_page.dart';
export 'src/ui/widgets/action_card.dart';
export 'src/ui/widgets/booking_tile.dart';
export 'src/ui/widgets/config_status.dart';

// Utils
export 'src/utils/date_parsers.dart';
export 'src/utils/env_loader.dart';
export 'src/utils/formatting.dart';
