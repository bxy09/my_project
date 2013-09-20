//////////////////////////////////////////////////////////////////////////
//Name		:	SystemLog.h
//Function	:	manage the system log
//Author	:	Jun-Yan Zhu, Tsinghua University
//////////////////////////////////////////////////////////////////////////
#ifndef SYSTEMLOG_H
#define SYSTEMLOG_H
#include "BasicTools.h"

enum ESystemType
{
	SYSTYPE_BOOT = 0, 
	SYSTYPE_CRON = 1, 
	SYSTYPE_MAIL = 2, 
	SYSTYPE_MSG = 3, 
	SYSTYPE_OPENSM = 4, 
	SYSTYPE_SECURE = 5, 
	SYSTYPE_SPOOLER = 6,
};

class CSystemLog
{
public: 
	CSystemLog() {Clear(); }
	CSystemLog(void* buffer, bool isParseLog); 
	~CSystemLog() {Clear(); }
	void Show(void); 
	char* GetBuffer(void);
	void Clear(void); 
	int GetBufferSize(void){return m_bufLen;}  

	inline void SetLogTime(NUMBER t) {m_logTime = t;}
	inline void SetNodeName(string name) {m_nodeName = name; }
	inline void SetLogContent(string c) {m_logContent = c; }
	inline void SetLogType(string type) {m_logType = GetSysLogType(type); }
	inline void SetTemplateID(NUMBER id) {m_tempID = id; }
	inline void SetLogID(NUMBER id) {m_logID = id; }

	inline NUMBER& GetLogTime(void) {return m_logTime; }
	inline string& GetNodeName(void) {return m_nodeName; }
	inline string& GetLogContent(void) {return m_logContent; }
	inline NUMBER& GetLogType(void) {return m_logType; }
	inline NUMBER& GetTemplateID(void) {return m_tempID; }
	inline NUMBER& GetLogID(void) {return m_logID; }

	void SetParseLog(bool flag) {m_isParseLog = flag; }
	BSONObj GetBSONObj(void);

private: 
	NUMBER GetSysLogType(string fName); 

private: 
	//Data 
	NUMBER m_logType; 
	NUMBER m_logTime; 
	string m_nodeName; 
	string m_logContent; 

	int m_bufLen; 
	char m_dataBuf[BUF_LENGTH]; 

	bool m_isParseLog; 
	NUMBER m_tempID; 
	NUMBER m_logID; 
};
#endif //SYSTEMLOG_H
