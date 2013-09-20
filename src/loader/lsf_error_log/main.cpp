#include"../lib/MyBasicTool.h"
#include <fstream>
#include"../lib/MyDataBaseHandler.h"
#include"../lib/LSFErrorLog.h"
#include"../lib/LogParser.h"
//#include"../lib/SIMToolbox.h"
using namespace std;
//hack code since the year is missing 
int MonthToYear[12] = {2013, 2013, 2013, 2013, 2013, 2012, 2012, 2012, 2012, 2012, 2012, 2012}; 
void LoadErrorLog(char *dbFName, char *fileListFilePath);
int main(int argc,char** argv) {
	if(argc!=3) {
		cout<<"para error!"<<endl;
		return -1;
	}
	LoadErrorLog(argv[1],argv[2]);
	return 0;
}

void LoadErrorLog(char *dbFName, char *fileListFilePath)
{
	vector<string> fileNameVec; 
	int nFiles = 0; 
	CLSFErrorLog errorLog; 
	CLogParser* m_paser = new CLogParser(); 
	m_paser->Initialize("errorlog"); 
	//errorLog.SetParseLog(m_isParseLog); 
	ifstream list_in;
	list_in.open(fileListFilePath);
	if(list_in==0) {perror("can't open file_list!!");}
	string line;
	while(!list_in.eof()) {
		getline(list_in,line);
		if(line.length()==0) continue;
		fileNameVec.push_back(line);
		//cout<<line<<endl;
	}
	list_in.close();
	nFiles = (int)fileNameVec.size(); 
	cout << "<#Loaded files> " << nFiles << endl; 
	NUMBER logID = 0;
	MyDataBaseHandler* dbHandler = new MyDataBaseHandler("localhost");
	if(dbHandler == 0) {perror("can't connect db!!");}
	FOR (f, nFiles)
	{
		string path = fileNameVec[f]; 
		ifstream fin(path.c_str());
		//fin.open(path.c_str()); 
		if (fin == NULL)
		{
			perror("Cannot load the LSF error log."); 
			cout<<"Cannot load the LSF error log:"<<path<<"#"<<endl;
			continue;
		}
		else 
		{
			cout << "Loading the user log " << fileNameVec[f] << endl;  
		}
		string fName = fileNameVec[f]; 
		int indexofslash = fName.find_last_of("/")+1;
		fName = fName.substr(indexofslash);
		string strType = fName.substr(0, fName.find("."));
		string nodeName = fName.substr(fName.find_last_of(".")+1); 
		if(nodeName.at(0) != 'c') {
			continue;
		}
		NUMBER tempID = 0; 
		string db_namespace = strType+"."+nodeName;
		m_paser->SetDBName("LsfError_"+strType);
		int line_index = 0;
		int count_of_out =0;
		while (!fin.eof())
		{
			line_index ++;
			if(line_index%40000 == 0) {
				printf("at line %d\n",line_index);
			}
			string line; 
			string tmpStr;
			string chunkStr; 
			tm* timep = new tm();

			errorLog.Clear(); 
			getline(fin, line); 
			
			if (line.empty()) 	
			{
				continue;
			}

			stringstream ss(line); 
			time_t t = 0; 
			ss >> tmpStr; 
			
			if (!CBasicTools::isValidTimeFormat(tmpStr))
			{
				continue; 
			}

			timep->tm_mon = CBasicTools::GetMonth(tmpStr); 
			ss >> tmpStr; 
			timep->tm_mday = atoi(tmpStr.c_str()); 
			ss >> tmpStr; 
			CBasicTools::GetDayTime(tmpStr, timep->tm_hour, timep->tm_min, timep->tm_sec); 
			ss >> tmpStr; 
			timep->tm_year = atoi(tmpStr.c_str())-1900; 
			if(!(timep->tm_year >= (2013-1900) && (timep->tm_mon >= 4 || (timep->tm_mon == 3 && timep->tm_mday>24)))) {
				continue;
			}
			++count_of_out;
			t = mktime(timep); //for what?
			delete timep;
			errorLog.SetLogTime((NUMBER)t); 
			errorLog.SetLogType(strType); 
			errorLog.SetNodeName(nodeName); 
			tmpStr = ss.str().substr((unsigned int)ss.tellg()+1); 
			if (1/*m_isParseLog*/)
			{
				m_paser->ChunkMSG(chunkStr, tmpStr); 
				m_paser->ParseMSG(tempID, chunkStr); 
				if (tempID == -1)
				{
					cout << "Cannot find the template.\n"; 
					cout << "[ORI]  " << tmpStr << endl; 
					cout << "[TEMP] " << chunkStr << endl; 
				}
				errorLog.SetTemplateID(tempID); 
				errorLog.SetLogID(logID); 
				logID++;
			}
			else 
			{
				errorLog.SetLogContent(tmpStr);
			}
			dbHandler->insert(db_namespace,errorLog.GetBSONObj(),0);
			ss.clear(); 
			ss.str(""); 
		}
		cout<<"count:"<<count_of_out<<endl;
		fin.close(); 
	}
	delete dbHandler;
	fileNameVec.clear(); 
	delete m_paser; 
}
