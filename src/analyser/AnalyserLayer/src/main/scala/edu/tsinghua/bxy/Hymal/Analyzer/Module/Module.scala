package edu.tsinghua.bxy.Hymal.Analyzer.Module
import edu.tsinghua.bxy.Hymal.Analyzer.db._
import edu.tsinghua.bxy.Hymal.Analyzer.db.NodeEndMark
import edu.tsinghua.bxy.Hymal.Analyzer.db.NodeAbstractionRecord
import annotation.tailrec;

trait Module {
  def run {
  }
  val modelName: String
}

trait AbstractionModule extends Module {

}

trait NodeAbstractionProcessor {
  def apply(records: Iterator[Entity]): Map[String, Set[Int]]

  def getNodesEndMark(): Map[String, NodeEndMark] =
    endMarkVisitor.getAll.map(endMark => (endMark._node, endMark)).toMap
  def endMarkVisitor: NodeEndMarkVisitor
  def abstractionVisitor: NodeAbstractionVisitor
  def recordReader: NodeRecordReader
  def collectionName: String
}
object SarAbstractionProcessor extends NodeAbstractionProcessor {
  override def apply(records: Iterator[Entity]): Map[String, Set[Int]] = {
    @tailrec
    def applyAcc(records: Iterator[Entity], acc: Map[String, Set[Int]]): Map[String, Set[Int]] = {
      if (records.hasNext) {
        records.next match {
          case record: SarRecord => 
          	val time = record.time/(24*3600)*(24*3600)
          	val keys = record.features.filter{case (key, value) => Math.abs(value) > 0.001}.map{case (key, value) => key}.toSet
          	val newKeys:Map[String, Set[Int]] = keys.filter(key => acc.get(key).isEmpty).map(key => (key,Set(0))).toMap
          	val newAcc:Map[String, Set[Int]] = acc ++ newKeys
          	applyAcc(records, newAcc.map{case (key, value) =>
          	  if(keys.contains(key)) (key, value + time)
          	  else (key, value)
          	  })
        }
      } else acc
    }
    applyAcc(records, Map())
  }
  override val endMarkVisitor = new NodeEndMarkVisitor("Sar")
  override val recordReader = new NodeRecordReader("Sar", SarRecord)
  override val abstractionVisitor  = new NodeAbstractionVisitor
  override val collectionName = "Sar"
}
class LogAbstractionProcessor(name:String) extends NodeAbstractionProcessor {
  override def apply(records: Iterator[Entity]): Map[String, Set[Int]] = {
    @tailrec
    def applyAcc(records: Iterator[Entity], acc: Map[String, Set[Int]]): Map[String, Set[Int]] = {
      if (records.hasNext) {
        records.next match {
          case record: LogRecord => 
          	val time = record.time/(24*3600)*(24*3600)
          	val key = name + record.tempId
          	val newAcc:Map[String, Set[Int]] =
          	  if(acc.contains(key)) acc.updated(key, acc(key)+time) 
          	  else acc + (key -> Set(0,time))
          	applyAcc(records, newAcc)
        }
      } else acc
    }
    applyAcc(records, Map())
  }
  override val endMarkVisitor = new NodeEndMarkVisitor(s"[Log][$name]")
  override val recordReader = new NodeRecordReader(name, LogRecord)
  override val abstractionVisitor  = new NodeAbstractionVisitor
  override val collectionName = "Log"
}
//todo: 可以抽象同样处理Sar与log，甚至是任务
class NodeAbstractionModule(processor: NodeAbstractionProcessor) extends AbstractionModule {
  def startTime(node: String): Int = processor.recordReader.minTime(node)
  def endTime(node: String): Int = processor.recordReader.maxTime(node)
  override def run() {
    val initNodesEndMark = processor.getNodesEndMark()
    val collections = processor.recordReader.getCollectionsOfNodes()
    val nodeEndSign = initNodesEndMark.values ++ collections.filter(node => initNodesEndMark.get(node).isEmpty).
      map(node => new NodeEndMark(node, startTime(node), 0))
    nodeEndSign.foreach {
      case NodeEndMark(node, _startTime, _endTime) => {
        val allRecords = processor.recordReader.readAfterTime(node, _endTime)
        val abstractions = processor(allRecords)
        abstractions.foreach {case (key, times) =>  
          times.foreach(time => new NodeAbstractionRecord(time, node, key, processor.collectionName).update(processor.abstractionVisitor))
        } //update abstractions in database
        //update end mark
        new NodeEndMark(node, _startTime, endTime(node)).update(processor.endMarkVisitor)
      }
    }

  }
  val modelName = "SarAbstractionModel"
}