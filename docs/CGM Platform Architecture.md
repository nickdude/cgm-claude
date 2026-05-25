# CGM Platform Architecture

# Backend Folder Structure (Node.js + Express + MongoDB)

```txt
backend/
│
├── src/
│
│   ├── config/
│   │   ├── db.js
│   │   ├── env.js
│   │   ├── jwt.js
│   │   ├── mail.js
│   │   └── socket.js
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── middlewares/
│   │   │   ├── auth.middleware.js
│   │   │   ├── error.middleware.js
│   │   │   └── upload.middleware.js
│   │   │
│   │   ├── utils/
│   │   │   ├── apiResponse.js
│   │   │   ├── jwt.js
│   │   │   ├── bcrypt.js
│   │   │   ├── mailer.js
│   │   │   ├── logger.js
│   │   │   └── validators.js
│   │   │
│   │   └── services/
│   │       ├── redis.service.js
│   │       ├── socket.service.js
│   │       └── cron.service.js
│   │
│   ├── modules/
│   │
│   │   ├── auth/
│   │   │   ├── auth.controller.js
│   │   │   ├── auth.service.js
│   │   │   ├── auth.routes.js
│   │   │   ├── auth.validation.js
│   │   │   └── auth.repository.js
│   │   │
│   │   ├── user/
│   │   │   ├── user.controller.js
│   │   │   ├── user.service.js
│   │   │   ├── user.routes.js
│   │   │   ├── user.validation.js
│   │   │   └── user.repository.js
│   │   │
│   │   ├── onboarding/
│   │   │   ├── onboarding.controller.js
│   │   │   ├── onboarding.service.js
│   │   │   ├── onboarding.routes.js
│   │   │   └── onboarding.repository.js
│   │   │
│   │   ├── cgm/
│   │   │   ├── cgm.controller.js
│   │   │   ├── cgm.service.js
│   │   │   ├── cgm.routes.js
│   │   │   ├── cgm.websocket.js
│   │   │   ├── cgm.repository.js
│   │   │   └── cgm.sdk.service.js
│   │   │
│   │   ├── food/
│   │   │   ├── food.controller.js
│   │   │   ├── food.service.js
│   │   │   ├── food.routes.js
│   │   │   └── food.repository.js
│   │   │
│   │   ├── insulin/
│   │   │   ├── insulin.controller.js
│   │   │   ├── insulin.service.js
│   │   │   ├── insulin.routes.js
│   │   │   └── insulin.repository.js
│   │   │
│   │   ├── exercise/
│   │   │   ├── exercise.controller.js
│   │   │   ├── exercise.service.js
│   │   │   ├── exercise.routes.js
│   │   │   └── exercise.repository.js
│   │   │
│   │   ├── fingerBlood/
│   │   │   ├── finger_blood.controller.js
│   │   │   ├── finger_blood.service.js
│   │   │   ├── finger_blood.routes.js
│   │   │   └── finger_blood.repository.js
│   │   │
│   │   ├── upload/
│   │   │   ├── upload.controller.js
│   │   │   ├── upload.service.js
│   │   │   └── upload.routes.js
│   │   │
│   │   └── analytics/
│   │       ├── analytics.controller.js
│   │       ├── analytics.service.js
│   │       ├── analytics.routes.js
│   │       └── analytics.repository.js
│   │
│   ├── models/
│   │   ├── User.js
│   │   ├── CGMDevice.js
│   │   ├── CGMReading.js
│   │   ├── Food.js
│   │   ├── Exercise.js
│   │   ├── Insulin.js
│   │   ├── FingerBlood.js
│   │   └── RefreshToken.js
│   │
│   ├── websocket/
│   │   ├── socket.js
│   │   ├── socketEvents.js
│   │   └── cgm.socket.js
│   │
│   ├── jobs/
│   │   ├── reconnect.job.js
│   │   ├── sync.job.js
│   │   ├── notification.job.js
│   │   └── cleanup.job.js
│   │
│   ├── docs/
│   │   ├── swagger.json
│   │   └── api.md
│   │
│   ├── app.js
│   └── server.js
│
├── uploads/
│
├── .env
├── package.json
└── README.md
```

---

# Flutter Folder Structure

```txt
mobile_app/
│
├── lib/
│
│   ├── app/
│   │   ├── routes/
│   │   ├── theme/
│   │   ├── constants/
│   │   └── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── storage_service.dart
│   │   │   ├── notification_service.dart
│   │   │   └── websocket_service.dart
│   │   │
│   │   ├── widgets/
│   │   ├── utils/
│   │   └── network/
│   │
│   ├── features/
│   │
│   │   ├── splash/
│   │   │   └── presentation/
│   │   │
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── onboarding/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── cgm/
│   │   │   ├── sdk/
│   │   │   │   ├── cgm_sdk.dart
│   │   │   │   ├── cgm_method_channel.dart
│   │   │   │   └── cgm_event_channel.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   ├── cgm_sync_service.dart
│   │   │   │   ├── cgm_history_service.dart
│   │   │   │   └── reconnect_service.dart
│   │   │   │
│   │   │   ├── connect/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   └── presentation/
│   │   │   │
│   │   │   ├── dashboard/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   └── presentation/
│   │   │   │
│   │   │   └── data/
│   │   │       └── models/
│   │   │
│   │   ├── food/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── insulin/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── exercise/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   ├── finger_blood/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │
│   │   └── analytics/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │
│   ├── main.dart
│   └── injection_container.dart
│
├── android/
├── ios/
├── assets/
│   ├── images/
│   ├── icons/
│   └── animations/
│
├── pubspec.yaml
└── README.md
```
