export class ValidationEngine {
  generateWithRetries<T>(
    factory: () => T,
    validate: (candidate: T) => boolean,
    fallback: T,
    maxAttempts = 40,
  ): T {
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const candidate = factory();
      if (validate(candidate)) {
        return candidate;
      }
    }
    return fallback;
  }
}
