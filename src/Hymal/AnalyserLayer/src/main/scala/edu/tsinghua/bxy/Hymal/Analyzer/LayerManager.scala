package edu.tsinghua.bxy.Hymal.Analyzer
import edu.tsinghua.bxy.Hymal.Analyzer.Module._

object LayerManager {
	def main(args:Array[String]) = {
		val sarModule = new NodeAbstractionModule(SarAbstractionProcessor)
		val sbatchdModule = new NodeAbstractionModule(new LogAbstractionProcessor("sbatchd"))
    val jobModule = new SystemAbstractionModule(JobAbstractionProcessor)
		//sarModule.run()
		//sbatchdModule.run()
    jobModule.run()
	}
}
