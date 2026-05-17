allprojects {
    repositories {
        google()
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension

        // Fix missing namespace for older plugins (reads from AndroidManifest.xml)
        try {
            val getNamespace = android.javaClass.getMethod("getNamespace")
            if (getNamespace.invoke(android) == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val pkg = Regex("""package\s*=\s*["']([^"']+)["']""")
                        .find(manifestFile.readText())?.groupValues?.get(1)
                    if (pkg != null) {
                        android.javaClass.getMethod("setNamespace", String::class.java)
                            .invoke(android, pkg)
                    }
                }
            }
        } catch (_: Exception) {}

        // Fix Java compatibility for older plugins that default to 1.8
        android.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_11
            targetCompatibility = JavaVersion.VERSION_11
        }
    }

    pluginManager.withPlugin("kotlin-android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}
