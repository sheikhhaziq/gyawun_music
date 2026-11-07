import 'dart:convert';

/// Builds the script that runs one extension.
///
/// It captures the host bridge, builds a context containing only the
/// [granted] capabilities, evaluates [extensionSource] (which must evaluate
/// to a function `(ctx) => methods`), and registers the returned methods
/// behind `__extensionCall`.
///
/// Both inputs are embedded as JSON data, so neither can break out of the
/// template.
String buildExtensionScript(
  String extensionSource, {
  required Set<String> granted,
}) => _template
    .replaceFirst('__GRANTED__', jsonEncode(granted.toList()))
    .replaceFirst('__SOURCE__', jsonEncode(extensionSource));

const _template = r'''
(() => {
  // Capture the bridge, then remove it so extension code can't send raw
  // {cap, method, args} messages.
  const send = globalThis.sendMessage;
  delete globalThis.sendMessage;

  const call = async (cap, method, args = {}) => {
    const raw = await send('extensionAction', JSON.stringify({ cap, method, args }));
    const env = typeof raw === 'string' ? JSON.parse(raw) : raw;
    if (!env.ok) throw new Error(env.error);
    return env.value === undefined ? null : env.value;
  };

  const format = (v) => {
    if (typeof v === 'string') return v;
    if (v instanceof Error) return v.stack || v.message;
    try { return JSON.stringify(v); } catch (_) { return String(v); }
  };

  // Fire and forget: a failing logger must never break the extension.
  const logger = (level) => (...parts) => {
    call('logging', 'write', { level, message: parts.map(format).join(' ') })
      .catch(() => {});
  };

  const available = {
    storage: {
      get: (key) => call('storage', 'get', { key }),
      set: (key, value) => call('storage', 'set', { key, value }),
      remove: (key) => call('storage', 'remove', { key }),
      keys: () => call('storage', 'keys'),
      clear: () => call('storage', 'clear'),
    },
    log: {
      debug: logger('debug'),
      info: logger('info'),
      warn: logger('warn'),
      error: logger('error'),
    },
    http: {
      fetch: (url, init = {}) => call('network', 'fetch', {
        url: String(url),
        method: init.method,
        headers: init.headers,
        body: init.body,
      }),
    },
  };

  // Only granted capabilities exist on the context.
  const granted = new Set(__GRANTED__);
  const context = {};
  for (const [name, api] of Object.entries(available)) {
    if (granted.has(name)) context[name] = Object.freeze(api);
  }
  Object.freeze(context);

  // Indirect eval runs in global scope and can't see this closure.
  const factory = (0, eval)(__SOURCE__);
  if (typeof factory !== 'function') {
    throw new Error('Extension must evaluate to a function');
  }
  const methods = factory(context);
  if (methods === null || typeof methods !== 'object') {
    throw new Error('Extension function must return an object of methods');
  }
  for (const [key, value] of Object.entries(methods)) {
    if (typeof value !== 'function') {
      throw new Error('Extension member "' + key + '" must be a function');
    }
  }
  const frozen = Object.freeze({ ...methods });

  // The one global Dart needs. It grants nothing: it only runs the
  // extension's own methods.
  Object.defineProperty(globalThis, '__extensionCall', {
    value: async (method, ...args) => {
      const fn = frozen[method];
      if (typeof fn !== 'function') {
        throw new Error('Extension does not implement: ' + method);
      }
      return fn(...args);
    },
    writable: false,
    configurable: false,
  });
    // Lets Dart see what the extension implements without calling anything.
  Object.defineProperty(globalThis, '__extensionMethods', {
    value: () => Object.keys(frozen),
    writable: false,
    configurable: false,
  });
})();
''';
