//job_assignment_log:parse job_assignment_log 
//                   and store the log into mongodb
#include<vector>
#include<iostream>
#include<fstream>
#include<string>
#include"../lib/MyBasicTool.h"
#include"../lib/BasicTools.h"
#include"../lib/MyDataBaseHandler.h"
#include"../lib/LSFTermLog.h"
using namespace std;
void LoadTermLog(char *dbFName, char *logFName);
int main(int argc,char **argv) {
    if(argc!=3) {
        cout<<"arg1:database_path,arg2:log_path\n";
        return -1;
    }
	LoadTermLog(argv[1],argv[2]);
    cout<<"quququ\n";
	return 0;
}
void LoadTermLog(char *dbFName, char *logFName)
{
	int itemNum = 0;
	string host = "localhost";
	string port;
	string db_namespace = "JobAssign.JobAssign";
	MyDataBaseHandler *dbHandler = new MyDataBaseHandler(host,port,db_namespace);
	
	//Dbc* cursorp = NULL; 
	ifstream fin(logFName); 
	CTermLog termLog; 

	//db.GetDb().cursor(NULL, &cursorp, 0); 

	if (fin == NULL)
	{
		cout<<"termReasonLog:"<<logFName<<"***"<<endl;
		cout<<"strlen:"<<strlen("lsb.acct")<<endl;
		perror("Cannot open the termination reason log."); 
	}
	else
	{
		printf("Loading the termination reason log.\n"); 
	}


	while (!fin.eof())
	{
		string line; 
		int pos = 0; 
		string subString; 

		termLog.Clear(); 
		getline(fin, line);

		if (line.empty())
		{
			continue;
		}

		pos = CBasicTools::GetNextBlank(line, subString); 

		if (subString != "\"JOB_FINISH\"")
		{
			//cout << "no job finish" <<endl; 
			continue;
		}

		pos = CBasicTools::GetNextNBlank(2, line, subString); 
		termLog.SetEventTime(atol(subString.c_str())); 
		pos = CBasicTools::GetNextBlank(line, subString); 
		termLog.SetJobID(atol(subString.c_str())); 
		pos = CBasicTools::GetNextBlank(line, subString); 
		termLog.SetUserID(atol(subString.c_str())); 
		pos = CBasicTools::GetNextNBlank(3, line, subString); 
		termLog.SetSubmitTime(atol(subString.c_str())); 
		pos = CBasicTools::GetNextBlank(line, subString); 
		termLog.SetBeginTime(atol(subString.c_str())); 
		pos = CBasicTools::GetNextBlank(line, subString); 
		termLog.SetTermTime(atol(subString.c_str())); 
		pos = CBasicTools::GetNextBlank(line, subString); 
		termLog.SetStartTime(atol(subString.c_str())); 
		pos = CBasicTools::GetNextBlank(line, subString); 
		termLog.SetUserName(subString.substr(1, subString.size()-2)); 
		pos = CBasicTools::GetNextNBlank(11, line, subString); 
		int num = atol(subString.c_str()); 
		pos = CBasicTools::GetNextNBlank(num+1, line, subString); 
		termLog.SetNumExHosts(atol(subString.c_str()));
		string nodeNameList = ""; 
		
		mongo::BSONArrayBuilder hostsBuilder;
		FOR (i, termLog.GetNumExHosts())
		{
			pos = CBasicTools::GetNextBlank(line, subString); 
			hostsBuilder.append(subString.substr(1,subString.length()-2));
		}
		termLog.SetExecHosts(hostsBuilder.arr());
		pos = CBasicTools::GetNextBlank(line, subString); 
		termLog.SetFinishStatus(atol(subString.c_str()));
		pos = CBasicTools::GetLastNBlank(17, line, subString); 
		termLog.SetExitInfo(atol(subString.c_str()));

		int flag = 0;
		dbHandler->insert(termLog.GetBSONObj(),flag);
			
		if(itemNum ++%100 == 0)
			cout<<itemNum <<endl;
	}	
	delete dbHandler;
	fin.close(); 
}


