/// Riverpod's retry policy for this app.
///
/// Returning `null` disables Riverpod 3's automatic retry-with-backoff for
/// failed providers. Automatic retries are the wrong default here for two
/// reasons:
///
/// * A provider that is silently retrying reports `isLoading` while it waits,
///   so a failed request renders as a spinner that never resolves instead of an
///   error the reader can act on.
/// * An explanation is a paid model call. Re-issuing it without being asked is
///   both surprising and expensive.
///
/// Every failure state in the app offers an explicit Retry, which invalidates
/// the provider — user-initiated, visible, and bounded.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
