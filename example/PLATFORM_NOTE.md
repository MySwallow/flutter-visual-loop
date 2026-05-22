# Platform scaffolding

`android/` and `ios/` directories are NOT committed. Generate them once
after cloning:

```bash
cd example
flutter create . --platforms=android,ios --org com.example.visualloop
flutter pub get
```

This keeps the repo small and avoids platform-specific drift in source
control. The Dart sources in `lib/` are the source of truth.
