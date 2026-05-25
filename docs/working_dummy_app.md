# COPILOT_CLAUDE_CGM_INTEGRATION_INSTRUCTIONS.md

# Objective

Integrate the Eaglenos CGM SDK into the existing Flutter application WITHOUT breaking existing architecture, navigation, authentication, state management, APIs, UI, or business logic.

This document contains the COMPLETE integration requirements, architecture, constraints, implementation details, pitfalls, and production considerations.

The AI assistant (Copilot/Claude) must strictly follow these instructions.

---

# Critical Requirements

## DO NOT BREAK EXISTING APP

The integration MUST:
- preserve existing navigation
- preserve existing routes
- preserve existing state management
- preserve existing APIs
- preserve existing authentication
- preserve existing themes
- preserve existing architecture
- preserve existing package structure
- preserve existing dependencies

Do NOT rewrite existing architecture.

Only ADD CGM functionality modularly.

---

# Integration Goal

Add:
- CGM device connection
- BLE scanning
- SDK authentication
- Live glucose streaming
- Device status
- Historical data sync
- Realtime callbacks

inside existing app.

---

# Existing App Constraints

The existing app already contains:
- UI screens
- navigation
- business logic
- APIs
- user management
- authentication

CGM integration must behave as an independent feature module.

---

# Required Architecture

Use this architecture ONLY:

Flutter UI
↓
Flutter Service Layer
↓
MethodChannel / EventChannel
↓
Native Android Kotlin Layer
↓
Eaglenos CGM SDK
↓
BLE + Cloud Validation

---

# Important SDK Understanding

This SDK is NOT BLE-only.

SDK flow:

1. SDK Authentication
2. Cloud SN Validation
3. BLE Scan
4. BLE Connection
5. Device Activation
6. Historical Data Sync
7. Live Glucose Streaming

If SN is not registered on backend:
- BLE connection WILL NOT start
- SDK returns:
  "Device not found"

This is expected SDK behavior.

Do NOT bypass this flow.

---

# Package Name

Android package name MUST remain:

```txt
com.belvix.app