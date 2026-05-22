# Visual Loop demo app

A throwaway Flutter app to verify the SDK + skill end-to-end.

## Run

```bash
cd example
flutter create . --platforms=android,ios --org com.example.visualloop  # generates android/ ios/ if missing
flutter pub get
flutter run -d <device-id>
```

You should see:

```
[flutter_visual_loop] registered route: /
[flutter_visual_loop] registered route: /login
[flutter_visual_loop] registered route: /product/detail
[flutter_visual_loop] registered route: /order/detail
[flutter_visual_loop] listening on http://127.0.0.1:9123
```

## Drive from your laptop

```bash
adb forward tcp:9123 tcp:9123

curl http://localhost:9123/health
# → {"ok":true,"version":"0.1.0","service":"flutter_visual_loop"}

curl http://localhost:9123/routes
# → {"ok":true,"routes":["/","/login","/product/detail","/order/detail"]}

curl -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail","args":{"id":"ORD-001"}}'
# → {"ok":true,"route":"/order/detail"}
# device should jump to the order page

curl -X POST http://localhost:9123/mock \
  -H 'content-type: application/json' \
  -d '{"action":"set","key":"order","value":{"id":"ORD-007","amount":42.0,"status":"待发货","items":[]}}'
# next time you navigate to /order/detail, the new mock data shows

curl -X POST http://localhost:9123/reset \
  -H 'content-type: application/json' \
  -d '{"clearMock":true}'
```

## Drive from Claude Code

```
/flutter-visual-loop example/design/order_detail.md /order/detail
```
