import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de version (ADR-0015) : hors du dépôt, décrite par android/key.properties
// (ignoré par git). Absente (CI, autre machine) : la version est signée avec la
// clé de débogage, comme avant.
val releaseKey = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "store.voxlivre.app"
    // 36 : exigé par flutter_secure_storage 10 (compilation seulement ;
    // l'app tourne toujours dès Android 7, minSdk 24).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Domaine voxlivre.store inversé : identifiant définitif sur le Play Store.
        applicationId = "store.voxlivre.app"
        // Android 7.0 : couvre les téléphones d'entrée de gamme encore en usage au Cameroun.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKey.isNotEmpty()) {
            create("release") {
                storeFile = file(releaseKey.getProperty("storeFile"))
                storePassword = releaseKey.getProperty("storePassword")
                keyAlias = releaseKey.getProperty("keyAlias")
                keyPassword = releaseKey.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // L'empreinte SHA-1 de cette clé est déclarée chez Google (client
            // OAuth Android) : un APK signé autrement ne peut pas se connecter.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
