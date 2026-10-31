/// Defines `globalThis.__jsBridgeCall(name, args)`. Evaluated once per runtime.
const jsBridgeScript = r'''
globalThis.__jsBridgeCall = async (name, args) => {
  try {
    const fn = globalThis[name];
    if (typeof fn !== 'function') {
      throw new Error('Function not found: ' + name);
    }
    const value = await fn(...args);
    return JSON.stringify({ ok: true, value: value === undefined ? null : value });
  } catch (error) {
    return JSON.stringify({
      ok: false,
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : null,
    });
  }
};
''';
