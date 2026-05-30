plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.belvix.app"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion

    compileOptions {

        isCoreLibraryDesugaringEnabled =
            true

        sourceCompatibility =
            JavaVersion.VERSION_11

        targetCompatibility =
            JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget =
            JavaVersion.VERSION_11.toString()
    }

    defaultConfig {

        applicationId =
            "com.belvix.app"

        minSdk = 26

        targetSdk =
            flutter.targetSdkVersion

        versionCode =
            flutter.versionCode

        versionName =
            flutter.versionName
    }

    buildTypes {

        release {

            signingConfig =
                signingConfigs.getByName(
                    "debug"
                )
        }
    }

    repositories {

        flatDir {
            dirs("libs")
        }
    }
}

dependencies {

    implementation(
        files(
            "libs/bleHealth-release.aar"
        )
    )
    
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.0.4"
    )
}

flutter {
    source = "../.."
}