package edu.tsinghua.bxy.Hymal.Analyzer.db
import com.mongodb.casbah.Imports._


abstract class EndMark(_startTime:Int, _endTime:Int) extends Entity with DBUpdateable {
  @inline def startTime:Int = _startTime
  @inline def endTime:Int = _endTime
}

abstract class AbstractionRecord(_time:Int) extends Entity with DBUpdateable{
  val time = NodeEndMark.startTimeOfDay(_time)
}
class NodeAbstractionRecord(_time:Int, _node:String, _name:String, typeName:String) 
	extends AbstractionRecord(_time){
  @inline def node = _node
  @inline def name = _name
  override def toString = 
    "{NodeAbstractionRecord:::time: " + time + ", node: " + node + " name: " + _name + "}"
  override def toDBObject = MongoDBObject("time" -> time , "node" -> node, "name" -> _name)
  override def update(dbWriter:DBWriter) = dbWriter.update(typeName, MongoDBObject("time"->time, "node"->node, "name" -> _name),this)
  
} 
object NodeEndMark{
  def startTimeOfDay(time:Int):Int = if(time>0) ((time/3600+8)/24*24-8)*3600 else 0
  def apply(dbObject:DBObject) = {
    new NodeEndMark(dbObject.get("_id").asInstanceOf[String], dbObject.get("startTime").asInstanceOf[Int], 
        dbObject.get("endTime").asInstanceOf[Int])
  }
}
case class NodeEndMark(_node:String, _startTime:Int, _endTime:Int) 
	extends EndMark(_startTime, _endTime) {
  @inline def node = _node
  override def toDBObject = 
    MongoDBObject("_id"->node, "startTime"->_startTime, "endTime"->endTime)
  override def toString = s"{NodeEndSign::: node:$node startTime:$startTime endTime:$endTime}"
  override def update(dbWriter:DBWriter) = dbWriter.update(_node, MongoDBObject("_id"->node),this)
}
