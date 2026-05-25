# CGM Platform API Documentation

Base URL

http://localhost:5000/api

---

# Authentication APIs

## Register User

Endpoint

POST /auth/register

Body

```json
{
  "fullName": "Puja",
  "email": "puja@gmail.com",
  "password": "123456"
}
```

Response

```json
{
  "success": true,
  "message": "Registration successful. Please verify email."
}
```

---

## Verify Email

Endpoint

GET /auth/verify-email/:token

Response

```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

---

## Login

Endpoint

POST /auth/login

Body

```json
{
  "email": "puja@gmail.com",
  "password": "123456"
}
```

Response

```json
{
  "success": true,
  "data": {
    "token": "JWT_TOKEN",
    "user": {
      "_id": "USER_ID",
      "fullName": "Puja",
      "email": "puja@gmail.com",
      "isProfileCompleted": false,
      "isOnboardingCompleted": false,
      "activeDeviceId": null
    }
  }
}
```

---

## Forgot Password

Endpoint

POST /auth/forgot-password

Body

```json
{
  "email": "puja@gmail.com"
}
```

Response

```json
{
  "success": true,
  "message": "Reset email sent successfully"
}
```

---

## Reset Password

Endpoint

POST /auth/reset-password/:token

Body

```json
{
  "password": "newpassword123"
}
```

Response

```json
{
  "success": true,
  "message": "Password reset successful"
}
```

---

# Profile APIs

Authorization

Bearer Token Required

---

## Get Profile

Endpoint

GET /profile/me

Headers

```txt
Authorization: Bearer JWT_TOKEN
```

---

## Update Profile

Endpoint

PUT /profile/update

Body

```json
{
  "fullName": "Puja Sharma",
  "profileImage": "IMAGE_URL"
}
```

---

# Onboarding APIs

## Submit Onboarding

Endpoint

POST /onboarding/submit

Body

```json
{
  "age": 30,
  "gender": "Female",
  "diabetesType": "Type 2",
  "height": 160,
  "weight": 65,
  "insulinUsage": true,
  "diagnosedYear": 2022,
  "activityLevel": "Moderate"
}
```

---

## Get Onboarding

Endpoint

GET /onboarding/me

---

# CGM Device APIs

## Connect Device

Endpoint

POST /cgm-device/connect

Body

```json
{
  "serialNumber": "SN123456",
  "deviceName": "Libre Sensor",
  "manufacturer": "Abbott"
}
```

---

## Get Active Device

Endpoint

GET /cgm-device/active

---

# CGM Reading APIs

## Add Reading

Endpoint

POST /cgm-reading/add

Body

```json
{
  "glucoseValue": 120,
  "trend": "UP"
}
```

---

## Get Readings

Endpoint

GET /cgm-reading/list

---

# Food APIs

## Create Food

Endpoint

POST /food/create

---

## Get Foods

Endpoint

GET /food/list

---

## Delete Food

Endpoint

DELETE /food/delete/:id

---

# Insulin APIs

## Create Insulin

Endpoint

POST /insulin/create

---

## Get Insulin

Endpoint

GET /insulin/list

---

## Delete Insulin

Endpoint

DELETE /insulin/delete/:id

---

# Exercise APIs

## Create Exercise

Endpoint

POST /exercise/create

---

## Get Exercise

Endpoint

GET /exercise/list

---

## Delete Exercise

Endpoint

DELETE /exercise/delete/:id

---

# Finger Blood APIs

## Create Finger Blood

Endpoint

POST /finger-blood/create

---

## Get Finger Blood

Endpoint

GET /finger-blood/list

---

## Delete Finger Blood

Endpoint

DELETE /finger-blood/delete/:id

---

# Upload APIs

## Upload Single File

Endpoint

POST /upload/single

Content-Type

multipart/form-data

Form Data

```txt
file: IMAGE_FILE
```

---

# Authentication Header

```txt
Authorization: Bearer JWT_TOKEN
```
