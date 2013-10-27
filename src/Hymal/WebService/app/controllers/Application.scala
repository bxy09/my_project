package controllers

import play.api._
import play.api.libs.json._
import play.api.mvc._
import edu.tsinghua.bxy.Hymal.Analyzer.db._
import play.api.libs.iteratee.Enumerator
import com.mongodb.casbah.Imports._

object Application extends Controller {

  lazy val sarReader = new NodeRecordReader("Sar", SarRecord)
  def index = Action {
    Ok(views.html.index("Your new application is ready."))
  }
  val abstractionConnector = new NodeAbstractionVisitor
  val logNameModel = """^(\S*)(\d+)$""".r
  case class LogName(id1:String,id2:String)
  object LogName{implicit val fmt = Json.format[LogName]}
  case class LogName2(id1:String,id2:List[String])
  object LogName2{implicit val fmt = Json.format[LogName2]}

  //prepare data
  def data = Action {
    val nodesList = abstractionConnector.getDistinctionNode("Sar").filterNot(_=="all")
    val daysList = abstractionConnector.getDistinctionDay("Sar").filterNot(_==0).sortBy(value=>value)
    val sarNames = abstractionConnector.getDistinctionName("Sar").sortBy(str=>str)map(str =>{
      val names = str.split("]")
      val id2 = names(names.length - 1)
      new LogName(names.dropRight(1).mkString("]")+"]", id2)
    })
    val logNames = abstractionConnector.getDistinctionName("Log").map(str =>{
      val logNameModel(id1,id2) = str
      (id1,id2)
    }).groupBy{case (id1,id2)=>id1}.map{case (key,value)=> new LogName2(key,value.map{case (a,b)=>b}.sortBy(a=>a.toInt))}
    val outStr:String = s"var nodes=${Json.toJson(nodesList)};\n" +
      s"var days=${Json.toJson(daysList)};\n" +
      s"var sars=${Json.toJson(sarNames)};\n" +
      s"var logs_in=${Json.toJson(logNames)};\nvar logs=[]\n"
    Ok(outStr).as("text/javascript")
  }
  
    val connect = MongoClient("localHost", 27017)
  def db(dbName:String, colName:String, criteria:Option[String], fields:Option[String], sort:Option[String]) = Action {
    println(s"find db:$dbName, col:$colName, ${criteria.get}")
    val gets = connect(dbName)(colName).find(com.mongodb.util.JSON.parse(criteria.get).asInstanceOf[DBObject],
    		com.mongodb.util.JSON.parse(fields.get).asInstanceOf[DBObject]
    		).sort(com.mongodb.util.JSON.parse(sort.get).asInstanceOf[DBObject]).toList
    Ok(s"[${gets.mkString(",")}]").as("text/json")
  }
}