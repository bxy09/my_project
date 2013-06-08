#include "LSFTermLog.h"
#include <fstream>
#include <iostream>

void CTermLog::Clear( void )
{
	m_bufLen = 0; 
	m_eventTime = 0; 
	m_jobID = 0; 
	m_userID = 0;
	m_submitTime = 0; 
	m_beginTime = 0; 
	m_termTime = 0; 
	m_startTime = 0; 
	m_numExHosts = 0; 
	m_jStatus = 0; 
	m_exitInfo = 0; 
	m_userName.clear(); 
	memset(m_dataBuf, 0, BUF_LENGTH); 
	//m_isParseLog = false; 
}

void CTermLog::Show( void )
{//TO-DO 
	string nodeName; 
	map<int, string> reasonName; 
	time_t eventT = (time_t)m_eventTime; 
	time_t startT = (time_t)m_startTime; 

	SetReasonNames(reasonName); 

	cout << "[Termination Reason Log] [Field List]\n" 
	<< "<EventTime> " << m_eventTime << " <ASCTIME> "  << asctime(localtime(&eventT))
	<< "<StartTime> " << m_startTime << " <ASCTIME> " << asctime(localtime(&startT))
	<< "<UserID> " << m_userID << endl
	<< "<JobID> " << m_jobID << endl 
	<< "<UserName> " << m_userName << endl 
	<< "<jStaus> " << m_jStatus << " <EXIT/DONE> "; 

	if (m_jStatus = LSF_JOB_STATUS_EXIT)
	{
		cout << "EXIT" << endl; 
	}
	else if (m_jStatus = LSF_JOB_STATUS_DONE)
	{
		cout << "DONE" << endl; 
	}
	else 
	{
		cout << "ERROR" << endl; 
	}

	cout << "<ExitInfo> " << m_exitInfo << " <Termination Reason> " << reasonName[m_exitInfo] <<endl
	<< "<numExHosts> " << m_numExHosts << endl;

	cout << endl; 
	reasonName.clear(); 
}

void CTermLog::SetReasonNames(map<int, string>& reasonNames)
{
	reasonNames.clear(); 

	ifstream fin("config/termReason.list"); 
	
	if (fin == NULL)
	{
		perror("Cannot open the file: termReason.list."); 
	}

	while (!fin.eof())
	{
		string reasonName; 
		int reasonID; 
		fin >> reasonName >> reasonID; 
		reasonNames[reasonID] = reasonName; 
	}

	fin.close(); 
}

BSONObj CTermLog::GetBSONObj(void)
{
	return BSON("eventTime"<<m_eventTime<<"jobID"<<m_jobID<<"userID"<<m_userID<<
			"submitTime"<<m_submitTime<<"beginTime"<<m_beginTime<<"termTime"<<m_termTime<<
			"startTime"<<m_startTime<<"numExHosts"<<m_numExHosts<<"jStatus"<<m_jStatus<<"exitInfo"<<m_exitInfo<<
			"userName"<<m_userName<<"execHosts"<<m_execHosts);
}
