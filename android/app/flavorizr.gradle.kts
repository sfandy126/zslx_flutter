import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("channel")

    productFlavors {
        create("xiaomi") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
        create("huawei") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
        create("oppo") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
        create("vivo") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
        create("meizu") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
        create("tengxun") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
        create("honor") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
        create("companywebsite") {
            dimension = "channel"
            applicationId = "com.zs.zslx"
            resValue(type = "string", name = "app_name", value = "卓仕遴选")
        }
    }

    buildFeatures.resValues = true
}