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
}