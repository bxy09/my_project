#include "MyDataBaseHandler.h"
MyDataBaseHandler::MyDataBaseHandler(string host,string port,string db_namespace)
{
	try{
		string error;
		if(!dbConnect.connect((host),error)) {
			std::cout<<error<<std::endl;
			perror("Can't connect Database!!\n");
	}
	}catch ( const mongo::DBException &e) {
		std::cout << "caught"<<e.what()<<std::endl;
		perror("Can't connect Database!!\n");
	}
	this->db_namespace = db_namespace;
}
bool MyDataBaseHandler::insert(BSONObj obj,int flags)
{

	dbConnect.insert(db_namespace,obj);
	return 1;
}
MyDataBaseHandler::MyDataBaseHandler(string host){
	try{
		string error;
		if(!dbConnect.connect((host),error)) {
			std::cout<<error<<std::endl;
			perror("Can't connect Database!!\n");
	}
	}catch ( const mongo::DBException &e) {
		std::cout << "caught"<<e.what()<<std::endl;
		perror("Can't connect Database!!\n");
	}

}
bool MyDataBaseHandler::insert(string i_db_namespace,BSONObj obj,int flags)
{
	dbConnect.insert(i_db_namespace,obj);
	return 1;
}
aptr_dbc MyDataBaseHandler::query(const string &ns,Query query,int limit ,
		int offset ,BSONObj *retFields) {
	try{
		return dbConnect.query(ns,query,limit,offset,retFields);
	}catch (const mongo::DBException &e) {
		std::cout<<"caught"<<e.what()<<std::endl;
		cout<<query.toString()<<endl;
		perror("Can't query ns");
	}
}

void MyDataBaseHandler::update(const string &ns,Query query,BSONObj obj,bool upser,bool multi) {
	dbConnect.update(ns,query,obj,upser,multi);
	return;
}
int MyDataBaseHandler::count(const string &db,const string &sns) {
	BSONObj ret;
	dbConnect.runCommand(db,BSON("count"<<sns),ret);
	return (int)(ret["n"].Number());
}
