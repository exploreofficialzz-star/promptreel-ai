class AppConfig {
  AppConfig._();

  // ── App Info ──────────────────────────────────────────────────────────────
  static const String appName      = 'PromptReel AI';
  static const String tagline      = 'Turn simple ideas into complete AI video production plans.';
  static const String developer    = 'chAs Tech Group';
  static const String footerCredit = 'Made with ❤️ by chAs Tech Group';
  static const String version      = '1.0.0';

  // ── API ───────────────────────────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://promptreel-ai.onrender.com',
  );
  static const String apiPrefix       = '/api';
  static const int    connectTimeoutMs = 30000;
  static const int    receiveTimeoutMs = 300000; // 5 minutes for generation

  // ── Flutterwave ───────────────────────────────────────────────────────────
  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLW_PUBLIC_KEY',
    defaultValue: 'FLWPUBK-d13a22da091412b50785e44d7b7d2245-X',
  );
  static const bool   flutterwaveTestMode = false;
  static const double creatorPriceUsd     = 15.00;
  static const double studioPriceUsd      = 35.00;

  // ── Storage Keys ──────────────────────────────────────────────────────────
  static const String tokenKey        = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey         = 'cached_user';
  static const String onboardingKey   = 'onboarding_complete';
  static const String themeKey        = 'app_theme';

  // ── AdMob — Android LIVE IDs ──────────────────────────────────────────────
  static const String admobAppIdAndroid          = 'ca-app-pub-2492078126313994~1571011892';
  static const String bannerAdUnitAndroid        = 'ca-app-pub-2492078126313994/7847678030';
  static const String interstitialAdUnitAndroid  = 'ca-app-pub-2492078126313994/5357246065';
  static const String rewardedAdUnitAndroid      = 'ca-app-pub-2492078126313994/5879990244';
  static const String nativeAdUnitAndroid        = 'ca-app-pub-2492078126313994/7137231592';

  // ── NEW: Extra ad units — create in AdMob dashboard and replace XXXXXXXXXX ─
  static const String interstitial2AdUnitAndroid = 'ca-app-pub-2492078126313994/9852369740';
  static const String banner2AdUnitAndroid       = 'ca-app-pub-2492078126313994/1638971257';

  // ── AdMob — iOS (replace when submitting to App Store) ────────────────────
  static const String admobAppIdIos              = 'ca-app-pub-3940256099942544~1458002511';
  static const String bannerAdUnitIos            = 'ca-app-pub-3940256099942544/2934735716';
  static const String interstitialAdUnitIos      = 'ca-app-pub-3940256099942544/4411468910';
  static const String rewardedAdUnitIos          = 'ca-app-pub-3940256099942544/1712485313';
  static const String nativeAdUnitIos            = 'ca-app-pub-3940256099942544/3986624511';
  static const String interstitial2AdUnitIos     = 'ca-app-pub-3940256099942544/4411468910';
  static const String banner2AdUnitIos           = 'ca-app-pub-3940256099942544/2934735716';

  // ── AI Model Tiers (for display) ──────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> planAiModels = {
    'free': {
      'primary': 'Gemini 2.0 Flash',
      'chain': [
        'Gemini 2.0 Flash',
        'Groq Llama 3.3 70B',
        'Groq Llama 3.1 8B',
        'DeepSeek-V3',
        'Together Qwen 2.5',
        'OpenRouter Free',
      ],
      'description': 'Fast & capable free models',
    },
    'creator': {
      'primary': 'GPT-4o-mini',
      'chain': [
        'GPT-4o-mini',
        'Grok-2',
        'Gemini 1.5 Pro',
        'Mistral Large',
        'DeepSeek-V3',
      ],
      'description': 'Pro models for higher quality output',
    },
    'studio': {
      'primary': 'GPT-4o',
      'chain': [
        'GPT-4o',
        'Claude 3.5 Sonnet',
        'Grok-2',
        'Gemini 1.5 Pro',
        'Mistral Large',
      ],
      'description': 'Highest-capability frontier models',
    },
  };

  // ── Affiliate Links ───────────────────────────────────────────────────────
  static const Map<String, String> affiliateLinks = {
    'Runway':          'https://runwayml.com',
    'Pika':            'https://pika.art',
    'Kling':           'https://klingai.com',
    'Luma AI':         'https://lumalabs.ai',
    'Leonardo AI':     'https://leonardo.ai',
    'Midjourney':      'https://midjourney.com',
    'CapCut':          'https://capcut.com',
    'DaVinci Resolve': 'https://blackmagicdesign.com/products/davinciresolve',
    'Stable Diffusion':'https://stability.ai',
  };

  // ── Content Types ─────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> contentTypes = [
    {'name': 'Educational',  'icon': '🎓', 'desc': 'Informative & factual'},
    {'name': 'Narration',    'icon': '📖', 'desc': 'Story-driven narration'},
    {'name': 'Commentary',   'icon': '💬', 'desc': 'Opinion & analysis'},
    {'name': 'Documentary',  'icon': '🎬', 'desc': 'Cinematic documentary'},
    {'name': 'Storytelling', 'icon': '✨', 'desc': 'Narrative & drama'},
    {'name': 'Comedy',       'icon': '😂', 'desc': 'Funny & entertaining'},
    {'name': 'Horror',       'icon': '👻', 'desc': 'Scary & suspenseful'},
    {'name': 'Motivational', 'icon': '🔥', 'desc': 'Inspiring & uplifting'},
    {'name': 'News',         'icon': '📰', 'desc': 'News & current events'},
    {'name': 'Realistic',    'icon': '📽️', 'desc': 'Grounded & authentic'},
  ];

  // ── Platforms ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> platforms = [
    {'name': 'YouTube',        'icon': '▶️',  'color': 0xFFFF0000},
    {'name': 'TikTok',         'icon': '🎵',  'color': 0xFF010101},
    {'name': 'Instagram',      'icon': '📸',  'color': 0xFFE1306C},
    {'name': 'Facebook',       'icon': '👍',  'color': 0xFF1877F2},
    {'name': 'YouTube Shorts', 'icon': '📱',  'color': 0xFFFF0000},
    {'name': 'X (Twitter)',    'icon': '✖️',  'color': 0xFF000000},
  ];

  // ── Durations ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> durations = [
    {'minutes': 1,  'label': '1 min',  'desc': 'Quick bite'},
    {'minutes': 3,  'label': '3 min',  'desc': 'Short form'},
    {'minutes': 5,  'label': '5 min',  'desc': 'Standard'},
    {'minutes': 10, 'label': '10 min', 'desc': 'Deep dive'},
    {'minutes': 20, 'label': '20 min', 'desc': 'Long form', 'paid': true},
  ];

  // ── Generators ────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> generators = [
    {'name': 'Runway',  'clip': 5,  'desc': '5s clips • Cinematic quality'},
    {'name': 'Pika',    'clip': 3,  'desc': '3s clips • Fast & fluid'},
    {'name': 'Kling',   'clip': 10, 'desc': '10s clips • Long scenes'},
    {'name': 'Sora',    'clip': 15, 'desc': '10-20s clips • Narrative AI'},
    {'name': 'Luma',    'clip': 5,  'desc': '5s clips • 3D depth'},
    {'name': 'Haiper',  'clip': 4,  'desc': '4s clips • Motion focus'},
    {'name': 'Other',   'clip': 5,  'desc': 'Custom generator'},
  ];
}
