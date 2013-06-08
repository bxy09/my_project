#include "SystemLog.h"

string str_SYSType[7] = {"BOOT", "CRON", "MAIL", "MESSAGE", "OPENSM", "SECURE", "SPOOLER"}; 

void CSystemLog::Clear( void )
{
	m_logType = 0; 
	m_logTime = 0; 
	m_nodeName.clear();
	m_logContent.clear(); 
	m_bufLen = 0; 
	memset(m_dataBuf, 0, BUF_LENGTH); 

	m_tempID = 0; 
	m_logID = 0; 
	//m_isParseLog = false; 
}

void CSystemLog::Show( void )
{
	time_t t = (time_t)m_logTime; 

	cout << "[SystemLog] [Field List]" << endl 
		 << "<LogType> " << str_SYSType[(int)m_logType] << endl
		 << "<LogTime> " << m_logTime << " <ASCTIME> " << asctime(localtime(&t))
		 << "<NodeName> " << m_nodeName << endl; 

	if (m_isParseLog)
	{
		cout <<"<TemplateID> " << m_tempID << endl; 
	}
	else 
	{
		cout << "<Content> " << m_logContent << endl; 
		cout << "<LogID> " << m_logID << endl; 
	}
}

NUMBER CSystemLog::GetSysLogType( string fName )
{
	int pos = fName.find("."); 
	string strType = fName.substr(0, pos); 
	string str_SYSType[7] = {"BOOT", "CRON", "MAILLOG", "MESSAGES", "OPENSM", "SECURE", "SPOOLER"}; 

	FOR (i, 7)
	{
		if (str_SYSType[i] == CBasicTools::UpperCase(strType))
		{
			return i; 
		}
	}
	return -1; 
}

BSONObj CSystemLog::GetBSONObj(void) {
	return BSON("logTime"<<m_logTime<<"tempID"<<m_tempID<<"logID"<<m_logID);
}
