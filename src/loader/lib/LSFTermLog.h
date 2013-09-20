//////////////////////////////////////////////////////////////////////////
//Name		:	LSFTermLog.h
//Function	:	manage the lsf termination reason log (lsb.acct)
//Author	:	Jun-Yan Zhu, Tsinghua University
//Note		: 
//Key: job id
//Data: acct information
//////////////////////////////////////////////////////////////////////////
#ifndef TERMLOG_H
#define TERMLOG_H
#include "MyBasicTool.h"
#include "BasicTools.h"
#define MAX_LARGE_FIELD 512
#define MAX_MID_FIELD 20


class CTermLog
{
public: 
	inline NUMBER& GetEventTime(void) {return m_eventTime; }
	inline NUMBER& GetJobID(void) {return m_jobID; }
	inline NUMBER& GetUserID(void) {return m_userID; }
	inline NUMBER& GetSubmitTime(void) {return m_submitTime; } 
	inline NUMBER& GetBeginTime(void) {return m_beginTime; }
	inline NUMBER& GetTermTime(void) {return m_termTime; }
	inline NUMBER& GetStartTime(void) {return m_startTime; }
	inline NUMBER& GetNumExHosts(void) {return m_numExHosts; }
	inline NUMBER& GetFinishStatus(void) {return m_jStatus; }
	inline NUMBER& GetExitInfo(void) {return m_exitInfo; }
	inline string& GetUserName(void) {return m_userName; }

	inline void SetEventTime(NUMBER time) {m_eventTime = time;}
	inline void SetJobID(NUMBER id) {m_jobID = id;}
	inline void SetUserID(NUMBER id) {m_userID = id; }
	inline void SetSubmitTime(NUMBER t) {m_submitTime = t; }
	inline void SetBeginTime(NUMBER t) {m_beginTime = t; }
	inline void SetTermTime(NUMBER t) {m_termTime = t; }
	inline void SetStartTime(NUMBER t) {m_startTime = t; }
	inline void SetNumExHosts(NUMBER num) {m_numExHosts  = num; }
	inline void SetFinishStatus(NUMBER s) {m_jStatus = s; }
	inline void SetExitInfo(NUMBER e) {m_exitInfo = e; }
	inline void SetUserName(string name) {m_userName = name; }
	inline void SetExecHosts(mongo::BSONArray hosts){m_execHosts = hosts; }

	CTermLog() {Clear(); }
	CTermLog(void* buffer); 
	~CTermLog() {Clear(); }
	void Show(void); 
	char* GetBuffer(void);
	void Clear(void); 
	int GetBufferSize(void){return m_bufLen; } 
	static void SetReasonNames(map<int, string>& reasonNames); 
	inline string GetTermReason(int exitInfo){return m_termReasonNames[exitInfo]; } 
	static map<int, string> m_termReasonNames; 
	//void EnableParseLog(void) {m_isParseLog = true; }
	BSONObj GetBSONObj(void);
private:
	//Data 
	NUMBER m_eventTime, m_jobID, m_userID; 						
	NUMBER m_submitTime, m_beginTime, m_termTime, m_startTime; 
	NUMBER m_numExHosts; 
	NUMBER m_jStatus; 
	NUMBER m_exitInfo; 
	//NUMBER m_tempID; 

	string m_userName;

	int m_bufLen; 
	char m_dataBuf[BUF_LENGTH]; 
	mongo::BSONArray m_execHosts;
	//bool m_isParseLog; 
};
#endif //TERMLOG_H

