package edu.tsinghua.bxy.Hymal.Analyzer.Module
import scala.annotation.tailrec
import edu.tsinghua.bxy.Hymal.Analyzer.db.{NodeEndMark, NodeAbstractionRecord}

trait Module {
  def run():Unit
  val modelName: String
}

trait AbstractionModule extends Module {

}
class SystemAbstractionModule(processor: SystemAbstractionProcessor) extends AbstractionModule {
  override def run() {
    val initNodesEndMark = processor.getEndMark
    val allRecords = processor.recordReader.readAfterTime(initNodesEndMark.endTime)
    processor(allRecords).
      foreach{case(key, value) => value.
        foreach{case(time, node) => new NodeAbstractionRecord(time, node, key, processor.collectionName).
          update(processor.NodeAbstractionVisitor)}}
  }
  val modelName = "SystemAbstractionModule"
}
class NodeAbstractionModule(processor: NodeAbstractionProcessor) extends AbstractionModule {
  def startTime(node: String): Int = processor.recordReader.minTime(node)
  def endTime(node: String): Int = processor.recordReader.maxTime(node)
  override def run() {
    val initNodesEndMark = processor.getNodesEndMark
    val collections = processor.recordReader.getCollectionsOfNodes
    val nodeEndMarks = initNodesEndMark.values ++ collections.filter(node => initNodesEndMark.get(node).isEmpty).
      map(node => new NodeEndMark(node, startTime(node), 0))
    @tailrec def eachNodeProcess(nodeEndMarkList:Iterable[NodeEndMark], allNodeAcc:Map[String,Set[Int]]):Map[String,Set[Int]] = {
      if(nodeEndMarkList.isEmpty) allNodeAcc
      else {
        nodeEndMarkList.head match{
          case NodeEndMark(node, _startTime, _endTime) => {
            val allRecords = processor.recordReader.readAfterTime(node, _endTime)
            val abstractions = processor(allRecords)
            abstractions.foreach {case (key, times) =>
              times.foreach(time => new NodeAbstractionRecord(time, node, key, processor.collectionName).update(processor.abstractionVisitor))
            } //update abstractions in database
            new NodeEndMark(node, _startTime, endTime(node)).update(processor.endMarkVisitor)
            val newKeysAbstraction = abstractions.filterNot{case(key, value) => allNodeAcc.contains(key)}
            val newAcc = allNodeAcc.map{case(key, value) => (key, value ++ abstractions.getOrElse(key, Set()))}
            eachNodeProcess(nodeEndMarkList.tail, newAcc ++ newKeysAbstraction)
          }
        }
      }
    }
    val allNodeAbstraction = eachNodeProcess(nodeEndMarks, Map())
    allNodeAbstraction.foreach {case (key, times) =>
      times.foreach(time => new NodeAbstractionRecord(time, "all", key, processor.collectionName).update(processor.abstractionVisitor))
    } //update abstractions in database
  }
  val modelName = "SarAbstractionModel"
}
