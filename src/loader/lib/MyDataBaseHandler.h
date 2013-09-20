#ifndef MYDATABASEHANDLER
#define MYDATABASEHANDLER
#include "MyBasicTool.h"
using mongo::Query;
using mongo::DBClientCursor;
typedef auto_ptr<DBClientCursor> aptr_dbc;
class MyDataBaseHandler {
	public:
		MyDataBaseHandler(string host,string port,string db_namespace);
		MyDataBaseHandler(string host);
		bool insert(BSONObj obj,int flags);
		bool insert(string db_namespace,BSONObj obj,int flags);
		auto_ptr<DBClientCursor> query(const string &ns,Query query,int limit = 0,
			int offset = 0,BSONObj *retFields = 0);
		void update(const string &ns,Query query,BSONObj obj,bool upser = 0,bool multi = 0);
		int count(const string &db,const string &sns);
	private:
		string db_namespace;
		mongo::DBClientConnection dbConnect;
};
#endif

