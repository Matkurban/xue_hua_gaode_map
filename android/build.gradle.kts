group = "com.kurban.xue_hua_gaode_map"
version = "1.0.0"

buildscript {
    val kotlinVersion = "2.3.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.kurban.xue_hua_gaode_map"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
        consumerProguardFiles("consumer-rules.pro")
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Combined package: bundles map + location (incl. geofence) + search in a
    // single artifact, avoiding the duplicate `com.amap.apis.utils.core`
    // classes that occur when the standalone location/search/map artifacts are
    // combined. Amap only ships a combined artifact for the 3D map on Maven, so
    // both Android and iOS use the 3D map SDK (iOS via the modular `AMap3DMap`
    // pod). Both platforms expose the same Dart API and behavior.
    //
    // `latest.integration` always resolves to the newest published SDK. To pin
    // a reproducible build, replace it with an explicit version, e.g.
    // implementation("com.amap.api:3dmap-location-search:10.1.200_loc6.4.9_sea9.7.4").
    implementation("com.amap.api:3dmap-location-search:latest.integration")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.23.0")
}
