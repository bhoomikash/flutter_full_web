#!/usr/bin/env bash
set -euxo pipefail

curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.0-stable.tar.xz -o flutter.tar.xz
tar -xf flutter.tar.xz -C /tmp
export PATH="/tmp/flutter/bin:$PATH"

flutter --version
flutter channel stable
flutter upgrade
flutter config --enable-web
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_KEY="${SUPABASE_KEY:-}"
