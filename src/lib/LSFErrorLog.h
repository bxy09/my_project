//////////////////////////////////////////////////////////////////////////
//Name		:	LSFErrorLog.h
//Function	:	manage the LSF error log (res.log.host_name, sbatchd.log.host_name, mbatchd.log.host_name, mbschd.log.host_name)
//Author	:	Jun-Yan Zhu, Tsinghua University
//////////////////////////////////////////////////////////////////////////
#ifndef ERRORLOG_H
#define ERRORLOG_H
#include "BasicTools.h"
//#define BUF_LENGTH 1000

class CLSFErrorLog
{
public:
	inline void SetLogType(string type) {m_logType = GetErrorLogType(type); }
	inline void SetLogTime(NUMBER time) {m_logTime = time; }
	inline void SetNodeName(string name) {m_nodeName = name; }
	inline void SetLogContent(string content) {m_logContent = content; }
	inline void SetTemplateID(NUMBER id) {m_tempID = id; }
	inline void SetLogID(NUMBER id) {m_logID = id; }

	inline NUMBER& GetLogType(void) {return m_logType; }
	inline NUMBER& GetLogTime(void) {return m_logTime; }
	inline string& GetNodeName(void) {return m_nodeName; }
	inline string& GetLogContent(void) {return m_logContent; }
	inline NUMBER& GetTemplateID(void) {return m_tempID; }
	inline NUMBER& GetLogID(void) {return m_logID; }

	CLSFErrorLog() {Clear(); }
	CLSFErrorLog(void* buffer, bool isParseLog); 
	~CLSFErrorLog() {Clear(); }
	void Show(void); 
	char* GetBuffer(void);
	int GetBufferSize(void){return m_bufLen;}  
	void Clear(void); 

	void SetParseLog(bool flag) {m_isParseLog = flag; }
	BSONObj GetBSONObj(void);
private: 
	int GetErrorLogType( string fName); 

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

#endif //ERRORLOG_H
