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
    project.plugins.withId("com.android.library") {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        
        // Fix missing namespace
        try {
            val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
            val getNamespace = android.javaClass.getMethod("getNamespace")
            if (getNamespace.invoke(android) == null) {
                setNamespace.invoke(android, "com.lucasjosino.on_audio_query")
            }
        } catch (e: Exception) {}
    }

    project.plugins.withId("com.android.application") {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        
        // Fix missing namespace
        try {
            val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
            val getNamespace = android.javaClass.getMethod("getNamespace")
            if (getNamespace.invoke(android) == null) {
                setNamespace.invoke(android, project.group.toString())
            }
        } catch (e: Exception) {}
    tasks.withType<JavaCompile>().configureEach {
        if (sourceCompatibility == "1.8") {
            sourceCompatibility = "11"
            targetCompatibility = "11"
        }
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
        }
    }
}

}

allprojects {
}
