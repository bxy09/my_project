package edu.tsinghua.bxy.Hymal.Analyzer.db
import edu.tsinghua.bxy.Hymal.Analyzer.Util._
import com.mongodb.casbah.Imports._

trait Entity {
	def toDBObject:DBObject
}
trait DBUpdateable {
  def update(dbWriter:DBWriter)
}
trait Record extends Entity{
}
trait Template extends Entity{
}

trait RecordObject {
  def apply(dbObject:DBObject):Entity
  def timeName:String
}

object LogRecord extends RecordObject{
  def apply(dbObject:DBObject) = new LogRecord(dbObject)
  def timeName = "logTime"
}

object JobRecord extends RecordObject{
  def apply(dbObject:DBObject):Entity = {
    def toInt(_time:Any):Int = _time match {
      case time:Int => time
      case time:Long => time.toInt
    }
    val nodes = dbObject.get("execHosts").asInstanceOf[BasicDBList].map(a=>a.asInstanceOf[String]).
          distinct.sortWith((a,b)=>a<b)
    val exitInfo:JobExitInfo = dbObject.get("jStatus").asInstanceOf[Int] match{
      case 32 => dbObject.get("exitInfo").asInstanceOf[Int] match{
        case 0 => UnknownExit
        case num => new KnownExit(num)
      }
      case 64 => Complete
    }
    new JobRecord(toInt(dbObject.get("eventTime")),
      toInt(dbObject.get("submitTime")),
      toInt(dbObject.get("beginTime")),
      toInt(dbObject.get("jobID")),
      exitInfo,
      dbObject.get("userName").asInstanceOf[String],
      toInt(dbObject.get("userID")),
      nodes.toList
      )
  }
  def timeName = "eventTime"
  type JobExitStatus = Int
}
trait JobExitInfo
object Complete extends JobExitInfo{override def  toString = "Complete"}
object UnknownExit extends JobExitInfo{override def toString = "UnKnownExit"}
case class KnownExit(exitNum:Int) extends JobExitInfo{override def toString = s"KnownExit($exitNum)"}

case class JobRecord(eventTime:Int, submitTime:Int, beginTime:Int, JobId:Int,
                     exitStatus:JobExitInfo, userName:String, userId:Int, nodes:List[String]) extends Record{
  override def toString = s"{JobRecord::eventTime: $eventTime, submitTime:$submitTime, beginTime:$beginTime, JobId:$JobId, " +
              s"exitStatus: $exitStatus, userName: $userName, userId: $userId, nodes:${nodes.mkString(":")}"
  override def toDBObject =
    throw new NotRealizeException("LogRecord don't need convert to DBObject (Don't need Store in this level)")
}
class LogRecord(_time:Int, _node:String, _logType:Int, _tempId:Int, _logId:Int) extends Record{
  @inline def time = _time
  @inline def node = _node
  @inline def logType = _logType
  @inline def tempId = _tempId
  @inline def logId = _logId
  def this(dbObject:DBObject) {
	 this(dbObject.get("logTime").asInstanceOf[Int],
		  dbObject.get("nodeName").asInstanceOf[String],
		  dbObject.get("logType").asInstanceOf[Int],
		  dbObject.get("tempID").asInstanceOf[Int],
		  dbObject.get("logID").asInstanceOf[Int])
  }
  override def toString = "{LogRecord::time: " + time + ", node: " + 
		  node + ", logType: " + logType + ", tempId: " + tempId + ", logId: " + 
		  logId + "}"
  override def toDBObject = 
    throw new NotRealizeException("LogRecord don't need convert to DBObject (Don't need Store in this level)")
}
class LogTemplate(_id:Int, _str:String) extends Template{
  val id = _id
  val string = _str
  def this(dbObject:DBObject) {
    this(dbObject.get("_id").asInstanceOf[Int],
        dbObject.get("str").asInstanceOf[String])
  }
  override def toString = "{LogTemplate::id: " + id + ", string: " + string + "}"
  override def toDBObject = 
     throw new NotRealizeException("LogTemplate don't need convert to DBObject (Don't need Store in this level)")
}
object SarRecord extends RecordObject{
  def applyAcc(dbObject:DBObject, nameAcc:List[String]):List[(String, Double)] = {
    val list =  dbObject.map{case(name, value) =>
      val names = name::nameAcc
      val nameString = names.reverse.reduce(_+_)
      val valueObject:Any = value
      valueObject match{
        case value:Int => List((nameString,value.toDouble))
        case value:Double => List((nameString,value))
        case value:Long => List((nameString,value.toDouble))
        case obj:DBObject => applyAcc(obj, names)
        case str:String => List((nameString,str.toDouble))
        case _ => throw new Error(valueObject.getClass.toString)
      }
    }
    list.reduce((a,b)=>a:::b)
  }
  def apply(dbObject:DBObject) = {
    val map = applyAcc(dbObject,Nil).filterNot{case (k,v) => k=="_id"}.toMap
    val time:Int = dbObject.get("_id").asInstanceOf[Any] match {
      case time:Int => time
      case time:Long => time.toInt
    }
    new SarRecord(time,map)
  }	
  def timeName = "_id"
}
class SarRecord(_time:Int, _features:Map[String,Double]) extends Record{
  val time = _time
  val features = _features
  override def toDBObject = 
    throw new NotRealizeException("LogTemplate don't need convert to DBObject (Don't need Store in this level)")
  override def toString = "{SarRecord:::time: "+ time + ", " +
  	features.map(o=>"" + o._1 + ": "+ o._2).reduce((a,b)=>a + ", " + b)+ "}"
}
