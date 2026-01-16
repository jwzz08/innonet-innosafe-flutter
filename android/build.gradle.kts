buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 1. 안드로이드 빌드 툴 (필수)
        classpath("com.android.tools.build:gradle:8.2.1")

        // 2. 코틀린 플러그인 (필수 - 버전은 프로젝트 설정에 따라 다를 수 있으나 보통 이 정도 사용)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.20")

        // 3. 구글 서비스 플러그인 (추가하신 것)
        classpath("com.google.gms:google-services:4.4.4")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}