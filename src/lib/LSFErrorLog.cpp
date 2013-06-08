#include "LSFErrorLog.h"
string str_LSFERRORType[7] = {"LIM", "PIM", "RES", "SBATCHD", "MBATCHD", "MBSCHD", "LSF"}; 

void CLSFErrorLog::Clear(void)
{
	m_logType = 0; 
	m_logTime = 0; 
	m_nodeName.clear(); 
	m_logContent.clear(); 
	m_bufLen = 0; 
	memset(m_dataBuf, 0, BUF_LENGTH); 

	m_tempID = 0; 
	m_logID = 0; 
}

CLSFErrorLog::CLSFErrorLog( void* buffer, bool isParseLog)
{
	Clear(); 
	m_isParseLog = isParseLog; 

	char* buf = (char*)buffer; 
	m_logType = CBasicTools::LoadNUMBER(buf, m_bufLen); 
	m_logTime = CBasicTools::LoadNUMBER(buf, m_bufLen);
	m_nodeName = CBasicTools::LoadString(buf, m_bufLen);

	if (m_isParseLog)
	{
		m_tempID = CBasicTools::LoadNUMBER(buf, m_bufLen); 
		m_logID  = CBasicTools::LoadNUMBER(buf, m_bufLen); 
		//cout << "m_tempID: " << m_tempID << endl; 
	}
	else 
	{
		m_logContent = CBasicTools::LoadString(buf, m_bufLen); 
		//cout << "m_logContent: " << endl; 
	}

}

void CLSFErrorLog::Show( void )
{
	time_t t = (time_t)m_logTime; 
	cout << "[LSF Error Log] [Field List]" << endl 
		<< "<LogType> " << str_LSFERRORType[(int)m_logType] << endl 
		<< "<LogTime> " << m_logTime << " <ASCTIME> " << asctime(localtime(&t))
		<< "<NodeName> " << m_nodeName << endl; 

	if (m_isParseLog)
	{
		cout << "<TemplateID> " << m_tempID << endl; 
		cout << "<LogID> " << m_logID << endl; 
	}
	else 
	{
		cout << "<Content>" << m_logContent << endl; 
	}
}

char* CLSFErrorLog::GetBuffer( void )
{
	memset(m_dataBuf, 0, BUF_LENGTH); 
	m_bufLen = 0; 
	int NUMLen = sizeof(NUMBER); 
	memcpy(m_dataBuf+m_bufLen, &m_logType, NUMLen); 
	m_bufLen += NUMLen; 
	memcpy(m_dataBuf+m_bufLen, &m_logTime, NUMLen); 
	m_bufLen += NUMLen; 
	CBasicTools::PackString(m_dataBuf, m_nodeName, m_bufLen); 

	if (m_isParseLog)
	{
		memcpy(m_dataBuf+m_bufLen, &m_tempID, NUMLen); 
		m_bufLen += NUMLen; 
		memcpy(m_dataBuf+m_bufLen, &m_logID, NUMLen); 
		m_bufLen += NUMLen; 
	}
	else 
	{
		CBasicTools::PackString(m_dataBuf, m_logContent, m_bufLen); 
	}

	return m_dataBuf; 
}

int CLSFErrorLog::GetErrorLogType( string fName )
{
	FOR (i, 7)
	{
		if (str_LSFERRORType[i] == CBasicTools::UpperCase(fName))
		{
			return i; 
		}
	}
	cout << "-1: " << fName << endl; 
	return -1; 
}
BSONObj CLSFErrorLog::GetBSONObj(void)
{
	return BSON("logType"<<m_logType<<"logTime"<<m_logTime<<
			"nodeName"<<m_nodeName<<"tempID"<<m_tempID<<"logID"<<m_logID);
}
