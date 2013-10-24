import sbt._
import Keys._

object ApplicationBuild extends Build {

  lazy val root = Project(id="Hymal", base = file(".")) aggregate(webService,analyserLayer)
  
  lazy val dependencies  = Seq(
            "org.mongodb" %% "casbah" % "2.6.2",
	    "junit" % "junit" % "4.10" % "test",
	    "org.scalatest" %% "scalatest" % "1.9.1" % "test",
	    "org.slf4j" % "slf4j-simple" % "1.7.5"
  )

  lazy val webService = play.Project("WebService","0.8", path = file("WebService")).dependsOn(analyserLayer)
  
  lazy val analyserLayer = Project(id="AnalyserLayer", base = file("AnalyserLayer")) settings (
	libraryDependencies ++= dependencies)
  val main = webService
}
