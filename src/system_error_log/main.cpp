#include"../lib/MyBasicTool.h"
#include <fstream>
#include"../lib/MyDataBaseHandler.h"
#include"../lib/LSFErrorLog.h"
#include"../lib/LogParser.h"
//#include"../lib/SIMToolbox.h"
using namespace std;
//hack code since the year is missing 
int MonthToYear[12] = {2013, 2013, 2013, 2013, 2013, 2012, 2012, 2012, 2012, 2012, 2012, 2012}; 
void LoadSystemLog(char *dbFName, char *fileListFilePath);
int main(int argc,char** argv) {
	if(argc!=3) {
		cout<<"para error!"<<endl;
		return -1;
	}
	LoadSystemLog(argv[1],argv[2]);
	return 0;
}

void LoadSystemLog(char *dbFName, char *fileListFilePath)
{
	vector<string> fileNameVec; 
	int nFiles = 0; 
	CSystemLog sysLog; 
	CLogParser* m_paser = new CLogParser(); 
	m_paser->Initialize("syslog"); 
	//errorLog.SetParseLog(m_isParseLog); 
	ifstream fin(fileListFilePath);
	if(fin==0) {perror("can't open file_list!!");}
	string line;
	while(!fin.eof()) {
		getline(fin,line);
		if(line.length()==0) continue;
		fileNameVec.push_back(line);
		//cout<<line<<endl;
	}
	nFiles = (int)fileNameVec.size(); 
	cout << "<#Loaded files> " << nFiles << endl; 
	NUMBER logID = 0;
	MyDataBaseHandler* dbHandler = new MyDataBaseHandler("localhost");
	if(dbHandler == 0) {perror("can't connect db!!");}

	FOR (f, nFiles)
	{
		string path = fileNameVec[f]; 
		ifstream fin(path.c_str()); 
		NUMBER tempID; 

		if (fin == NULL)
		{
			perror("Cannot load the system log.\n"); 
		}
		else 
		{
			cout << "Loading the system log " << fileNameVec[f] << endl; 
		}
		string fName = fileNameVec[f]; 
		int indexofslash = fName.find_last_of("/")+1;
		fName = fName.substr(indexofslash);
		string strType = fName.substr(0, fName.find("."));
		m_paser->SetDBName("SysLog_"+strType);
		int count_of_out =0;
		while (!fin.eof())
		{
			string line; 
			string tmpStr; 
			string chunkStr; 
			tm* timep = new tm(); 

			sysLog.Clear(); 
			getline(fin, line); 

			if (line.empty())
			{
				continue;
			}

			stringstream ss(line); 
			time_t t = 0; 
			ss >> tmpStr; 
			timep->tm_mon = CBasicTools::GetMonth(tmpStr); 
			ss >> tmpStr; 
			timep->tm_mday = atoi(tmpStr.c_str());
			if(!(timep->tm_mon >= 4 || (timep->tm_mon == 3 && timep->tm_mday>24))) {
				continue;
			}
			ss >> tmpStr; 
			CBasicTools::GetDayTime(tmpStr, timep->tm_hour, timep->tm_min, timep->tm_sec); 
			timep->tm_year = MonthToYear[timep->tm_mon] -1900; 
			t = mktime(timep); 

			if (t == - 1)
			{
				perror("Wrong time conversion!"); 
			}
			ss >> tmpStr; 
			sysLog.SetLogTime((NUMBER)t); 
			sysLog.SetLogType(strType);
			if(tmpStr.at(0) != 'c') {
				continue;
			}
++count_of_out;
			sysLog.SetNodeName(tmpStr); 
			tmpStr = ss.str().substr((unsigned int)ss.tellg()+1); 
			ss.clear(); 
			ss.str(""); 
			
			if (1)
			{
				m_paser->ChunkMSG(chunkStr, tmpStr); 
				m_paser->ParseMSG(tempID, chunkStr); 

				if (tempID == -1)
				{
					cout << "Cannot find the template" << endl; 
					cout << "[ORI]  " << tmpStr << endl; 
					cout << "[TEMP] " << chunkStr << endl; 
				}

				sysLog.SetTemplateID(tempID); 
				sysLog.SetLogID(logID); 
				logID++; 
			}
			else 
			{
				sysLog.SetLogContent(tmpStr);
			}
			dbHandler->insert(strType+"."+sysLog.GetNodeName(),sysLog.GetBSONObj(),0);
		}
		cout<<"count:"<<count_of_out<<endl;
		fin.close(); 
	}
	delete dbHandler;
	fileNameVec.clear(); 
	delete m_paser; 
}

