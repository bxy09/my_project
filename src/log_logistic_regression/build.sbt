
libraryDependencies  ++= Seq(
            // other dependencies here
            // pick and choose:
            "org.scalanlp" %% "breeze-math" % "0.2.3",
            "org.scalanlp" %% "breeze-learn" % "0.2.3",
            "org.scalanlp" %% "breeze-process" % "0.2.3",
            "org.scalanlp" %% "breeze-viz" % "0.2.3",
            "org.scalanlp" % "nak" % "1.1.3",
            "org.mongodb" % "casbah_2.10" % "2.6.2"
)

resolvers ++= Seq(
            // other resolvers here
            // if you want to use snapshot builds (currently 0.3-SNAPSHOT), use this.
            "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots/"
)

// Scala 2.9.2 is still supported for 0.2.1, but is dropped afterwards.
scalaVersion := "2.10.1"