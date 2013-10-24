package edu.tsinghua.bxy.Hymal.Analyzer.db

import com.mongodb.casbah.Imports._
import edu.tsinghua.bxy.Hymal.Global.Setting

trait DBConnector {
  val connect = MongoClient("localHost", 27017)
}
trait DBReader extends DBConnector

trait DBWriter extends DBConnector {
  def update(collectionName:String, key: =>DBObject, entity:DBUpdateable)
}

class NodeRecordReader(dbName:String, recordObject:RecordObject) extends DBReader {
  val dbConnect = connect(dbName)
  def getCollectionsOfNodes:Iterable[String] = dbConnect.getCollectionNames().filterNot(name => name.startsWith("system"))
  def readAfterTime(node:String, time:Long):Iterator[Entity] = {
    dbConnect(node).find(MongoDBObject(recordObject.timeName -> MongoDBObject("$gt" -> time))).
    	map((line)=>recordObject(line))
  }
  private def extremeTime(node:String, isDescend:Boolean):Int = {
    val result = dbConnect(node).find().
    		sort(MongoDBObject(recordObject.timeName -> (if(isDescend)-1 else 1))).limit(1).toList
    assert(result.length == 1)
    val resultOne:Any = result.head.get(recordObject.timeName) 
    val time = resultOne match {
      case time:Int => time
      case time:Long => time.toInt
      case _ => throw new Exception(s"don't have extremeTime! node:$node dbName:$dbName") 
    }
    if(time < Setting.systemStartTime) Setting.systemStartTime else time
  }
  @inline def maxTime(node:String):Int = extremeTime(node, true)
  @inline def minTime(node:String):Int = extremeTime(node, false)
}


class SystemRecordReader(dbName:String, collectionName:String, recordObject:RecordObject) extends DBReader {
  val collectionConnect = connect(dbName)(collectionName)
  def readAfterTime(time:Long):Iterator[Entity] = {
    collectionConnect.find(MongoDBObject(recordObject.timeName -> MongoDBObject("$gt" -> time))).
      map((line)=>recordObject(line))
  }
  private def extremeTime(isDescend:Boolean):Int = {
    val result = collectionConnect.find().
      sort(MongoDBObject(recordObject.timeName -> (if(isDescend)-1 else 1))).limit(1).toList
    assert(result.length == 1)
    val resultOne:Any = result.head.get(recordObject.timeName)
    resultOne match {
      case time:Int => time
      case time:Long => time.toInt
      case _ => throw new Exception(s"don't have extremeTime! collection:$collectionName dbName:$dbName")
    }
  }
  @inline def maxTime:Int = extremeTime(true)
  @inline def minTime:Int = extremeTime(false)
}

class LogTemplateReader(dbName:String) extends DBReader {
  val collectionConnect = connect(dbName)("str")
  def readAll():Iterator[LogTemplate] = {
    collectionConnect.find().
    	map((line)=>new LogTemplate(line))
  }
}
class NodeAbstractionVisitor extends DBReader with DBWriter {
  val dbConnect = connect("Abstraction")
  override def update(collectionName:String, key: =>DBObject, entity:DBUpdateable) = {
    dbConnect(collectionName).update(key, entity.asInstanceOf[Entity].toDBObject, true)
    println(s"update $entity")
  }
} 
class NodeEndMarkVisitor(collectionName:String) extends DBReader with DBWriter {
  val collectionConnect = connect("EndMark")(collectionName)
  val getAll = collectionConnect.find().
    	map((line) => NodeEndMark(line))
  override def update(collectionName:String, key: =>DBObject, entity:DBUpdateable) = {
      collectionConnect.update(key, entity.asInstanceOf[Entity].toDBObject, true)
      	println(s"update $entity")
  }
}
class EndMarkVisitor(collectionName:String) extends DBReader with DBWriter {
  val collectionConnect = connect("EndMark")(collectionName)
  val get = collectionConnect.findOne().
    map((line) => NodeEndMark(line))
  override def update(collectionName:String, key: =>DBObject, entity:DBUpdateable) = {
    collectionConnect.update(key, entity.asInstanceOf[Entity].toDBObject, true)
    println(s"update $entity")
  }
}
