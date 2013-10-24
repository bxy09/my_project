package edu.tsinghua.bxy.Hymal.Analyzer

import org.scalatest.FunSuite
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner
import edu.tsinghua.bxy.Hymal.Analyzer.db._

@RunWith(classOf[JUnitRunner])
class NodeRecordReaderTest extends FunSuite {
	test("read sbatchd log"){
	  val sbatchdReader = new NodeRecordReader("sbatchd", LogRecord)
	  val testRecords = sbatchdReader.readAfterTime("c01b10", 0)
	  testRecords.foreach(record => println(record))
	}
	
	test("read sar log"){
	  val sarReader = new NodeRecordReader("Sar", SarRecord)
	  val testRecords = sarReader.readAfterTime("c01b10", 0)
	  testRecords.foreach(record => println(record))
	}
	
	test("min max"){
	  val sarReader = new NodeRecordReader("Sar", SarRecord)
	  val max = sarReader.maxTime("c01b10")
	  val min = sarReader.minTime("c01b10")
	  assert(min < max, s"$min should < than $max")
	}

  test("test for map set add"){
    val a = Map(1->Set(1,2),2->Set(3),4->Set(5))
    val b = Map(1->Set(1,3),2->Set(4),3->Set(7))
    (a++b).foreach{case(a,b)=>{println(a);println(b.mkString(":"))}}
  }
}