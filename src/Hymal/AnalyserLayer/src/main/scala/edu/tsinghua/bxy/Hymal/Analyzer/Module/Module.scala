package edu.tsinghua.bxy.Hymal.Analyzer.Module
import scala.annotation.tailrec
import edu.tsinghua.bxy.Hymal.Analyzer.db.{ NodeEndMark, NodeAbstractionRecord, EndMark }

trait Module {
  def run(): Unit
  val modelName: String
}

trait AbstractionModule extends Module {

}
class SystemAbstractionModule(processor: SystemAbstractionProcessor) extends AbstractionModule {
  override def run() {
    val initNodesEndMark = processor.getEndMark
    val allRecords = processor.recordReader.readAfterTime(initNodesEndMark.endTime)
    processor(allRecords).par.
      foreach {
        case (key, value) => value.
          foreach {
            case (time, node) => new NodeAbstractionRecord(time, node, key, processor.collectionName).
              update(processor.NodeAbstractionVisitor)
          }
      }
    new NodeEndMark("all", initNodesEndMark.startTime, processor.recordReader.maxTime).update(processor.endMarkVisitor)
  }
  val modelName = "SystemAbstractionModule"
}
class NodeAbstractionModule(processor: NodeAbstractionProcessor) extends AbstractionModule {
  def startTime(node: String): Int = processor.recordReader.minTime(node)
  def endTime(node: String): Int = processor.recordReader.maxTime(node)
  override def run() {
    val initNodesEndMark = processor.getNodesEndMark
    val collections = processor.recordReader.getCollectionsOfNodes
    val nodeEndMarks = (initNodesEndMark.values ++ collections.filter(node => initNodesEndMark.get(node).isEmpty).
      map(node => try { new NodeEndMark(node, startTime(node), 0) } catch {
        case ex: Exception => println("Exception:from new NodeEndMark"); new NodeEndMark("trash", 0, 0)
      }).filter { case NodeEndMark(node, _, _) => node != "trash" }).toList

    @tailrec def eachNodeProcess(nodeEndMarkList: Iterable[NodeEndMark], allNodeAcc: Map[String, Set[Int]]): Map[String, Set[Int]] = {
      if (nodeEndMarkList.isEmpty) allNodeAcc
      else {
        nodeEndMarkList.head match {
          case NodeEndMark(node, _startTime, _endTime) => {
            val allRecords = processor.recordReader.readAfterTime(node, _endTime)
            val abstractions = processor(allRecords)
            abstractions.foreach {
              case (key, times) =>
                times.foreach(time => new NodeAbstractionRecord(time, node, key, processor.collectionName).update(processor.abstractionVisitor))
            } //update abstractions in database
            new NodeEndMark(node, _startTime, endTime(node)).update(processor.endMarkVisitor)
            val newKeysAbstraction = abstractions.filterNot { case (key, value) => allNodeAcc.contains(key) }
            val newAcc = allNodeAcc.map { case (key, value) => (key, value ++ abstractions.getOrElse(key, Set())) }
            eachNodeProcess(nodeEndMarkList.tail, newAcc ++ newKeysAbstraction)
          }
        }
      }
    }
    if (nodeEndMarks.length > 0) {
      val allNodeAbstraction = //eachNodeProcess(nodeEndMarks, Map())
        nodeEndMarks.par.map {
          case NodeEndMark(node, _startTime, _endTime) => {
            val allRecords = processor.recordReader.readAfterTime(node, _endTime)
            val abstractions = processor(allRecords)
            abstractions.foreach {
              case (key, times) =>
                times.foreach(time => new NodeAbstractionRecord(time, node, key, processor.collectionName).update(processor.abstractionVisitor))
            } //update abstractions in database
            new NodeEndMark(node, _startTime, endTime(node)).update(processor.endMarkVisitor)
            abstractions
          }
        }.reduce((allNodeAcc, abstractions) => {
          println(s"reduce: $allNodeAcc,$abstractions")
          val newKeysAbstraction = abstractions.filterNot { case (key, value) => allNodeAcc.contains(key) }
          val newAcc = allNodeAcc.map { case (key, value) => (key, value ++ abstractions.getOrElse(key, Set())) }
          println("reduce end")
          newAcc ++ newKeysAbstraction
        })
      allNodeAbstraction.foreach {
        case (key, times) =>
          times.foreach(time => new NodeAbstractionRecord(time, "all", key, processor.collectionName).update(processor.abstractionVisitor))
      } //update abstractions in database
      println("foreach end")
    }
  }
  val modelName = "SarAbstractionModel"
}
