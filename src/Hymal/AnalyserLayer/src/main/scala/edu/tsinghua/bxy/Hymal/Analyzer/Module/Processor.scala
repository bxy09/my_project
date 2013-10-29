package edu.tsinghua.bxy.Hymal.Analyzer.Module

import edu.tsinghua.bxy.Hymal.Analyzer.db._
import edu.tsinghua.bxy.Hymal.Global.Setting
import scala.annotation.tailrec


/**
 * Created with IntelliJ IDEA.
 * User: bxy
 * Date: 13-10-18
 * Time: 上午10:06
 */
trait Processor

trait SystemAbstractionProcessor extends Processor{
  def apply(records: Iterator[Entity]): Map[String, Set[(Int,String)]]
  def getEndMark: EndMark
  def endMarkVisitor: EndMarkVisitor
  def NodeAbstractionVisitor: NodeAbstractionVisitor
  def recordReader: SystemRecordReader
  def collectionName: String
}
object JobAbstractionProcessor extends SystemAbstractionProcessor{
  def apply(records: Iterator[Entity]): Map[String, Set[(Int,String)]] = {
    @tailrec
    def applyAcc(records: Iterator[Entity], acc: Map[String, Set[(Int,String)]]):Map[String, Set[(Int,String)]] = {
      if(records.hasNext){
        val newAcc = records.next() match{
          case JobRecord(eventTime,submitTime,beginTime,_,exitStatus,_,_,nodes) =>
            val startTime = {
              val startTime= if(beginTime == 0) submitTime else beginTime
              if(startTime < Setting.systemStartTime) Setting.systemStartTime else startTime
            }
            val times = 0::((startTime/3600+8)/24*(3600*24) to(eventTime, 3600*24)).toList
            val newTimeNodePair = ("all"::nodes).map(node => times.map(time => (time, node))).reduce(_++_)
            val exitInfo = exitStatus match{
              case KnownExit(_)=> "KnownExit"
              case Complete => "Complete"
              case UnknownExit => "UnKnownExit"
            }
            acc.updated(exitInfo, acc.getOrElse(exitInfo, Set()) ++ newTimeNodePair)
        }
        applyAcc(records, newAcc)
      } else acc
    }
    applyAcc(records, Map())
  }
  def getEndMark: EndMark = endMarkVisitor.get.getOrElse(new NodeEndMark("all", recordReader.minTime, 0))
  val endMarkVisitor: EndMarkVisitor = new EndMarkVisitor("Job")
  val NodeAbstractionVisitor: NodeAbstractionVisitor = new NodeAbstractionVisitor()
  def recordReader: SystemRecordReader = new SystemRecordReader("JobAssign", "JobAssign", JobRecord)
  val collectionName = "Job"
}
trait NodeAbstractionProcessor extends Processor{
  def apply(records: Iterator[Entity]): Map[String, Set[Int]]
  def getNodesEndMark: Map[String, NodeEndMark] =
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
        records.next() match {
          case record: SarRecord =>
            val time = (record.time/3600+8)/24*(24*3600)
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
      if (records.hasNext) records.next() match {
        case record: LogRecord =>
          val time = (record.time/3600+8)/24*(24*3600)
          val key:String = name + record.tempId
          val newAcc:Map[String, Set[Int]] =
            if(acc.contains(key)) acc.updated(key, acc(key)+time)
            else acc + (key -> Set(0,time))
          applyAcc(records, newAcc)
      } else acc
    }
    applyAcc(records, Map())
  }
  override val endMarkVisitor = new NodeEndMarkVisitor(s"[Log][$name]")
  override val recordReader = new NodeRecordReader(name, LogRecord)
  override val abstractionVisitor  = new NodeAbstractionVisitor
  override val collectionName = "Log"
}
