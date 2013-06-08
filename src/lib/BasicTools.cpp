#include "BasicTools.h"
#include <fstream>

NUMBER CBasicTools::LoadNUMBER( char* buf, int& bufLen )
{
	NUMBER tmp = *((NUMBER*)(buf+bufLen)); 
	bufLen += sizeof(NUMBER); 
	return tmp; 
}

string CBasicTools::LoadString( char* buf, int& bufLen )
{
	string tmp = buf+ bufLen; 
	bufLen += tmp.size() + 1; 
	return tmp; 
}

void CBasicTools::PackString( char* buffer, string& theString, int& bufLen)
{
	int string_size = theString.size() + 1;
	memcpy(buffer+bufLen, theString.c_str(), string_size);
	bufLen += string_size;
}

string CBasicTools::UpperCase( string str )
{
	assert(!str.empty()); 

	transform(str.begin(), str.end(), str.begin(), (int (*)(int))toupper); 
	return str; 
}

int CBasicTools::GetMonth( string monStr )
{
	map<string, int> monMap;
	string monArray[12] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}; 

	FOR (i, 12)
	{
		monMap[monArray[i]] = i; 
	}

	int monNum = monMap[monStr]; 
	monMap.clear(); 
	return monNum; 
}

void CBasicTools::GetDayTime( string str, int& h, int& m, int& s )
{
	h = atoi(str.substr(0, 2).c_str());
	m = atoi(str.substr(3, 5).c_str()); 
	s = atoi(str.substr(6, 8).c_str()); 
}

bool CBasicTools::isValidTimeFormat( string str )
{
	string monArray[12] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}; 
	bool flag = false; 

	FOR (i, 12)
	{
		if (str == monArray[i])
		{
			flag = true; 
			break; 
		}
	}

	return flag; 
}

bool CBasicTools::isRightString( string input, string ans )
{
	if (UpperCase(input) == UpperCase(ans))
	{
		return true; 
	}
	else 
	{
		return false; 
	}
}


int CBasicTools::GetNextNBlank( int n, string& theString, string& substring )
{
	assert(n >= 0); 
	int pos = 0; 
	FOR (i, n)
	{
		pos = GetNextBlank(theString, substring); 
	}
	return pos; 
}

int CBasicTools::GetNextBlank(string &theString, string &substring)
{
	int pos_first_quot = theString.find("\""); 

	if (pos_first_quot == string::npos)
	{
		pos_first_quot = -1; 
	}
	int pos_second_quot = theString.find("\"", pos_first_quot+1); 
	if (pos_second_quot == string::npos)
	{
		pos_second_quot = -1; 
	}
	int pos = theString.find(" ");
	if (pos > pos_first_quot)
	{
		pos = theString.find(" ", pos_second_quot+1); 
	}

	substring.assign(theString, 0, pos);
	theString.assign(theString, pos + 1, theString.size());
	return (pos);
}

void CBasicTools::ReadNodeListFromFile( string nodeFName, vectorString& nodeList )
{
	ifstream fin(nodeFName.c_str()); 
	if (fin == NULL)
	{
		perror("Cannot read the node list file."); 
	}

	nodeList.clear(); 

	while (!fin.eof())
	{
		string nodeName; 
		fin >> nodeName; 
		nodeList.push_back(nodeName); 
	}
}

void CBasicTools::ReadNodeListFromFile( string nodeFName, set<string>& nodeList )
{
	ifstream fin(nodeFName.c_str()); 

	if (fin == NULL)
	{
		perror("Cannot read the node list file."); 
	}

	nodeList.clear(); 

	while (!fin.eof())
	{
		string nodeName; 
		fin >> nodeName; 
		nodeList.insert(nodeName); 
	}
}

time_t CBasicTools::GetMonthBeginTime(int year, int month )
{
	tm* timep = new tm();
	timep->tm_mon = month-1; 
	timep->tm_mday = 1; 
	timep->tm_year = year -1900; 
	delete timep;
	return mktime(timep); 
}

time_t CBasicTools::GetMonthEndTime(int year, int month )
{
	if (month == 11)
	{
		return GetMonthBeginTime(year+1, 0)-1; 
	}
	else 
	{
		return GetMonthBeginTime(year, month+1)-1; 
	}
}

int CBasicTools::GetLastBlank( string& theString, string& substring )
{
	int pos = theString.find_last_of(" "); 
	substring.assign(theString, pos+1, theString.size());
	theString.assign(theString, 0, pos); 
	return (pos);
}

int CBasicTools::GetLastNBlank(int n, string& theString, string& substring )
{
	assert(n >= 0); 
	int pos = 0; 
	FOR (i, n)
	{
		pos = GetLastBlank(theString, substring); 
	}
	return pos; 
}

