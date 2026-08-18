/// Fork-local provider customisation. Not intended for upstream.
///
/// Upstream's built-in provider lists are kept byte-identical and filtered
/// through this allowlist at their use sites, so syncing upstream does not
/// conflict here, and providers upstream adds later stay hidden until they
/// are listed below.
library;

/// Built-in providers this fork keeps in the provider list.
///
/// Display order is not set here — it follows upstream's list and is
/// reorderable on the providers page.
const kForkBuiltInProviderAllowlist = <String>{
  'OpenAI',
  'Gemini',
  'Claude',
  'Grok',
  'DeepSeek',
  'OpenRouter',
};

/// Whether first launch seeds provider configs.
///
/// Upstream seeds KelivoIN / Tensdaq / SiliconFlow / AIhubmix, none of which
/// this fork keeps, so seeding would only recreate hidden providers.
const kForkSeedsBuiltInProviders = false;
