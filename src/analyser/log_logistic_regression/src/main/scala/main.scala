import breeze.optimize._
import breeze.optimize.FirstOrderMinimizer.OptParams
import breeze.math.MutableCoordinateSpace
import breeze.util.Index
import scala.reflect.ClassTag
import breeze.classify._
import breeze.linalg._
import breeze.data.{ DataMatrix, Example }
import breeze.stats.ContingencyStats
import com.mongodb.casbah.Imports._
object main extends App {
  def trainer[L, T]: Classifier.Trainer[L, Counter[T, Double]] =
    new LogisticClassifier.Trainer[L, Counter[T, Double]](
      OptParams(tolerance = 1E-2, regularization = 1.0, useL1 = true))

  val signal_groups = Map(
    "Sar_signal" -> 181,
    "lim" -> 7,
    "pim" -> 1,
    "res" -> 15,
    "sbatchd" -> 20,
    "messages" -> 2)
  var feature_col = new collection.mutable.HashSet[Tuple2[String, Int]]()
  for (useless <- Array(0); (k, v) <- signal_groups; no <- 0 until v) {
    feature_col.add((k, no));
  }
  val mongoClient = MongoClient("166.111.69.20", 27017)
  def getList(beginTime: Long, node: String): Array[Example[String, Counter[String, Double]]] = {
    def read_records(beginTime: Long, endTime: Long, dbName: String, tempID: Int, node: String): Array[Long] = {
      var record_buffer = new collection.mutable.ArrayBuffer[Long]()
      var label_list = new collection.mutable.ArrayBuffer[Long];
      var time: Long = 0;
      var lastTrashTime: Long = 0;
      var temp: Long = 0
      for (label <- mongoClient(dbName)(node).find(MongoDBObject("tempID" -> tempID,
        "logTime" -> MongoDBObject("$gte" -> beginTime, "$lt" -> endTime)))) {
        try {
          if (label.get("logTime").isInstanceOf[Int]) {
            temp = label.get("logTime").asInstanceOf[Int];
          } else {
            temp = label.get("logTime").asInstanceOf[Long];
          }
          if(temp < time){throw new Exception}
          if(temp < lastTrashTime){throw new Exception}
          if (temp - time < 5 * 60) {
            lastTrashTime = temp
          } else {
            if (lastTrashTime != 0) {
              if (temp - time > 6 * 60) {
                record_buffer += lastTrashTime
              }
              lastTrashTime = 0;
            }
            time = temp
            record_buffer += time
          }
        } catch {
          case ex: Exception =>
            ex.printStackTrace; println(label);
            println("temp:%d,time:%d,trash:%d".format(temp,time,lastTrashTime))
            assert(false);
        }

      }
      //label_cursor.close
      return record_buffer.toArray;
    }
    var list_buffer = new collection.mutable.ArrayBuffer[Example[String, Counter[String, Double]]]()
    val unknown_label_col = read_records(beginTime, beginTime + 24 * 3600, "Job_signal", 3, node)
    var known_label_col = new collection.mutable.ArrayBuffer[Long];
    for (reason_no <- 1 until 8 if reason_no != 3)
      known_label_col ++= read_records(beginTime, beginTime + 24 * 3600, "Job_signal", 3, node)
    if (unknown_label_col.length == 0) return Array();
    val feature_data = for (feature <- feature_col) yield (feature._1 + feature._2,
      read_records(beginTime - 3600, beginTime + 25 * 3600, feature._1, feature._2, node))
      
    def search(target: Long, l: Array[Long]) = {
      def recursion(low: Int, high: Int): Int = (low + high) / 2 match {
        case _ if high < low => low
        case mid if l(mid) > target => recursion(low, mid - 1)
        case mid if l(mid) < target => recursion(mid + 1, high)
        case mid => mid
      }
      recursion(0, l.size - 1)
    }
    for (job_time <- unknown_label_col) {
      var traits = new collection.mutable.ArrayBuffer[String]
      for ((feature_name, data)<-feature_data) {
        val index = search(job_time-60*60,data)
        if(index<data.length && data(index)<=job_time+60*60){
          traits += feature_name;
        }
      }
      list_buffer += Example("unknown", Counter.count(traits:_*).mapValues(_.toDouble))
    }
    for (job_time <- known_label_col) {
      var traits = new collection.mutable.ArrayBuffer[String]
      for ((feature_name, data)<-feature_data) {
        val index = search(job_time-60*60,data)
        if(index<data.length && data(index)<=job_time+60*60){
          traits += feature_name;
        }
      }
      list_buffer += Example("known", Counter.count(traits:_*).mapValues(_.toDouble))
    }
    return list_buffer.toArray;
  }
  val node_col = for (i <- 1 to 4; j <- 1 to 20) yield ("c%02db%02d" format (i, j))
  val start_unixtime = 1366819200
  val dayCount = 31

  var workSet = new collection.mutable.ArrayBuffer[Tuple2[String,Long]]()
  for(day<-0 until dayCount;node<-node_col){
    workSet+= Tuple2(node,start_unixtime+3600*24*day)
  }
  var trainingData = new collection.mutable.ArrayBuffer[Example[String, Counter[String, Double]]]
  for(work<-workSet){
    println("====")
    trainingData ++= getList(work._2,work._1)
    println(work._1 +":"+ trainingData.size)
  }
  var classifier = trainer[String,String].train(trainingData) 
  for (label <- feature_col) {
    val known_val = classifier.scores(Counter.count(label._1+label._2).mapValues(_.toDouble)).get("known");
    if(known_val.isDefined){
      if(known_val.get.abs > 0.01) print("****")
      println(label+":"+known_val.get)
    }
  }
}