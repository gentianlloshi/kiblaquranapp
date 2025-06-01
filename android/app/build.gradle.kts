plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kiblaapp.islamic"
    compileSdk = 35  // Restored to 35 as required by several plugins
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring for Java 8 features
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Add configuration to handle flutter_compass resource issue
    sourceSets {
        getByName("main") {
            // Exclude flutter_compass resources from being processed
            res.srcDirs("src/main/res", "src/main/res-compass-excluded")
        }
    }
    
    // Add lint options to ignore resource issues
    lintOptions {
        disable("MissingDefaultResource")
    }

    // Add packaging options to exclude problematic resources
    packagingOptions {
        resources {
            excludes.add("**/values.xml")  // Exclude values.xml files from flutter_compass that might be causing issues
        }
    }

    // Add signing configuration for release build
    signingConfigs {
        getByName("debug") {
            // Default debug config is already defined by Android plugin
        }

        create("release") {
            // Use the same values as debug keystore for simplicity
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    defaultConfig {
        applicationId = "com.kiblaapp.islamic"
        minSdk = 23  // Required by flutter_compass
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Use default debug config
            signingConfig = signingConfigs.getByName("debug")
        }

        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            // Add ndk filters to avoid ABI issues in release builds
            ndk {
                abiFilters.add("armeabi-v7a")
                abiFilters.add("arm64-v8a")
                abiFilters.add("x86_64")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
