//////////////////////////////////////////////////////////////////////////
//Name		:	LogParser.h
//Function	:	parse the log 
//Author	:	Jun-Yan Zhu, Tsinghua University
//////////////////////////////////////////////////////////////////////////
#ifndef LOGPARSER_H
#define LOGPARSER_H
#include "BasicTools.h"
#include "LSFErrorLog.h"
#include "SystemLog.h"
#include "SIMToolbox.h"

class CLogParser
{

enum ParseMode
{
	PARSEMODE_TEMPLATE, 
	PARSEMODE_PARSE, 
	PARSEMODE_TEST, 
}; 

public: 
	CLogParser(void); 
	~CLogParser(void);
	int ParseLog(void); 
	void ParseMSG(NUMBER& tempID, const string& oriString); 
	void ChunkMSG(string& rstString, const string& oriString); 
	void Initialize(string template_db_namespace);

	inline void SetDBName(string template_db_name){
		m_simToolbox->SetDBName(template_db_name);
	}
private: 
	void Clear(void); 
	//void ExactAllTemplates(CDatabase& db, string tempFPath, string indexFPath); 
	void ParseAllLogs(void); 

	void GetWord(string& line, string& word, string& term); 
	bool ChunkToPath(const string& word); 
	bool ChunkToIP(const string& word); 
	bool ChunkToNUM(const string& word); 
	bool ChunkToNode(const string& word); 
	void ChunkPartNUM(string& rst, int& nNUM, const string& word); 
	bool ChunkToSD(const string& word); 
	bool ExceptionCase(string& rst, const string& ori); 

	int InitializeTemplate(string template_db_name); 
	void PrintTemplateList(string saveFPath);
	void UpdateTempalteList(void); 
	void GetTemplateID(int&  tempID, const string& MSG);

	void TestChunk(void); 

	void ReadParameters(string configFName);

private: 
	string m_configFName; 
	string m_resultPath;
	string m_templateFPath; 
	string m_indexFPath; 
	string m_testMSG; 
	vector<string> m_templateStrVec;
	vector<int> m_numTemplateVec; 
	vector< set<int> > m_numTypeVec; 
	set<string> m_nodeList; 
	ParseMode m_parseMode;
	bool m_isProcErrorLog;
	bool m_isProcSysLog; 
	CSIMToolbox* m_simToolbox; 

	double m_simThreshold; 
};
#endif //LOGPARSER_H
