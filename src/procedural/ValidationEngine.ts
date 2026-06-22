export class ValidationEngine {
  generateWithRetries<T>(
    factory: () => T,
    validate: (candidate: T) => boolean,
    fallbackFactory: () => T,
    maxAttempts = 40,
  ): T {
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const candidate = factory();
      if (validate(candidate)) {
        return candidate;
      }
    }
    const fallback = fallbackFactory();
    if (validate(fallback)) {
      return fallback;
    }
    throw new Error("Procedural generation failed: fallback did not pass validation");
  }
}
