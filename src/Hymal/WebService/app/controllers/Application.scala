package controllers

import play.api._
import play.api.mvc._
import edu.tsinghua.bxy.Hymal.Analyzer.db._

object Application extends Controller {

  lazy val sarReader = new NodeRecordReader("Sar", SarRecord)
  def index = Action {
    Ok(views.html.index("Your new application is ready."))
  }

}