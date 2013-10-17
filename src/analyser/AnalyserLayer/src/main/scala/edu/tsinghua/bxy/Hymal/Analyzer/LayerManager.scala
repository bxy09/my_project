package edu.tsinghua.bxy.Hymal.Analyzer
import com.mongodb.casbah.Imports._
import edu.tsinghua.bxy.Hymal.Analyzer.db._
import edu.tsinghua.bxy.Hymal.Analyzer.Module._

object LayerManager {
	def main(args:Array[String]) = {
		val sarModule = new NodeAbstractionModule(SarAbstractionProcessor)
		val sbatchdModule = new NodeAbstractionModule(new LogAbstractionProcessor("sbatchd"))
		sarModule.run()
		sbatchdModule.run()
	}
}
