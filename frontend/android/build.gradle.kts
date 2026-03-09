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
    // Only redirect build dir if the project and build dir share the same filesystem root.
    // This avoids "this and base files have different roots" when plugins (e.g. from Pub cache
    // on C:\) are built alongside a project on a different drive (e.g. F:\).
    val projectRoot = project.projectDir.toPath().root
    val buildRoot = newSubprojectBuildDir.asFile.toPath().root
    if (projectRoot == buildRoot) {
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
