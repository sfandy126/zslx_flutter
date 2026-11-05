allprojects {
    repositories {
        google()
        maven {
            url = uri("https://maven.aliyun.com/repository/central")
            content {
                includeModule("org.apache.commons", "commons-imaging")
            }
        }
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// 部分 Flutter 插件固定使用较旧的 compileSdk（如支付宝 31、百家云 33），
// 但其 AndroidX 依赖要求至少 34。统一使用项目已安装的 Android 36 编译库插件。
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                compileSdk = 36
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
