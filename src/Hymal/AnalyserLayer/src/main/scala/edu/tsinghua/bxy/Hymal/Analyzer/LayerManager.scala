package edu.tsinghua.bxy.Hymal.Analyzer
import edu.tsinghua.bxy.Hymal.Analyzer.Module._

object LayerManager {
	def main(args:Array[String]) = {
		val sarModule = new NodeAbstractionModule(SarAbstractionProcessor)
		val sbatchdModule = new NodeAbstractionModule(new LogAbstractionProcessor("sbatchd"))
		val limModule = new NodeAbstractionModule(new LogAbstractionProcessor("lim"))
		val messagesModule = new NodeAbstractionModule(new LogAbstractionProcessor("messages"))
		val pimModule = new NodeAbstractionModule(new LogAbstractionProcessor("pim"))
		val resModule = new NodeAbstractionModule(new LogAbstractionProcessor("res"))
    val jobModule = new SystemAbstractionModule(JobAbstractionProcessor)
		sarModule.run()
		sbatchdModule.run()
		limModule.run()
		pimModule.run()
		resModule.run()
		messagesModule.run()
    	jobModule.run()
	}
}
