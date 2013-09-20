//////////////////////////////////////////////////////////////////////////
//Name		:	BasicTools.h
//Function	:	Implement some basic tools
//Author	:	Jun-Yan Zhu, Tsinghua University
//////////////////////////////////////////////////////////////////////////
#ifndef BASICTOOLS_H
#define BASICTOOLS_H
#include"MyBasicTool.h"
class CBasicTools
{
public:
	static NUMBER LoadNUMBER(char* buf, int& bufLen); 
	static string LoadString( char* buf, int& bufLen); 
	static void PackString( char* buf, string& theString, int& bufLen); 
	static string UpperCase(string str); 
	static void FindFoldersInFolder(string rootPath, vectorString& fNameVec); 
	static int GetMonth(string monStr); 
	static void GetDayTime(string str, int& h, int& m, int& s); 
	static bool isValidTimeFormat(string str); 
	static bool isRightString(string input, string ans); 
	static int GetNextNBlank( int n, string& theString, string& substring ); 
	static int GetNextBlank(string &theString, string &substring); 
	static int GetLastBlank(string& theString, string& substring); 
	static int GetLastNBlank(int n, string& theString, string& substring); 
	static void ReadNodeListFromFile(string nodeFName, vectorString& nodeList); 
	static void ReadNodeListFromFile(string nodeFName, set<string>& nodeList); 
	static time_t GetMonthBeginTime(int year, int month); 
	static time_t GetMonthEndTime(int year, int month); 
};


#endif //BASICTOOLS_H
