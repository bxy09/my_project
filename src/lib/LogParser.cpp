#include "LogParser.h"
#include <fstream>
#define TEMPLATE_NOT_FOUND -1

void CLogParser::Clear( void )
{
	m_nodeList.clear(); 
	m_configFName.clear(); 
	m_resultPath.clear(); 
	m_testMSG.clear(); 
	m_indexFPath.clear(); 
	m_templateFPath.clear(); 

	m_templateStrVec.clear(); 
	m_numTemplateVec.clear(); 

	FOR (i, (int)m_numTypeVec.size())
	{
		m_numTypeVec[i].clear(); 
	}

	m_numTypeVec.clear(); 
	
	m_simToolbox = NULL; 
	m_parseMode = PARSEMODE_PARSE; 
	m_isProcErrorLog = false; 
	m_isProcSysLog = false; 
	m_simThreshold = 0.95; 
}

CLogParser::CLogParser() 
{	
	Clear(); 
	//m_configFName = configFName;
	//ReadParameters(m_configFName); 
	CBasicTools::ReadNodeListFromFile("config/node.list", m_nodeList); 
}

void CLogParser::ChunkMSG( string& rstString, const string& oriString )
{
	assert(!oriString.empty()); 

	string line = oriString; 
	string word; 
	string tmp; 
	string term; 
	stringstream ss_tmp; 
	int nPath = 1; 
	int nNUM =  1; 
	int nIP  = 1; 
	int nNode = 1;
	int nSD = 1; 

	if (ExceptionCase(rstString, line))
	{
		return; 
	}

	term.clear(); 
	word.clear(); 
	rstString.clear(); 
	ss_tmp.clear(); 
	ss_tmp.str(""); 

	while (!line.empty())
	{
		rstString += term; 
		GetWord(line, word, term); 
	

		if (word.empty())
		{
			continue;
		}

		if (ChunkToNode(word))
		{
			ss_tmp << nNode; 
			rstString += "NODE" + ss_tmp.str();
			nNode++; 
		}
		else if (ChunkToIP(word))
		{
			ss_tmp << nIP; 
			rstString += "IP" +	ss_tmp.str(); 
			nIP++; 
		}
		else if (ChunkToPath(word))
		{
			ss_tmp << nPath; 
			rstString += "PATH" + ss_tmp.str();
			nPath++; 
		}
		else if (ChunkToNUM(word))
		{
			ss_tmp << nNUM; 
			rstString += "NUM" + ss_tmp.str(); 
			nNUM++; 
		}
		else if (ChunkToSD(word))
		{
			ss_tmp << nSD; 
			rstString += "SD" + ss_tmp.str(); 
			nSD++; 
		}
		else 
		{
			ChunkPartNUM(tmp, nNUM, word); 
			rstString += tmp; 
		}

		ss_tmp.clear(); 
		ss_tmp.str(""); 
	}
}

bool CLogParser::ChunkToPath(const string& word )
{
	int c = std::count(word.begin(), word.end(), '/'); 

	if (c >= 1)
	{
		return true; 
	}
	else 
	{
		return false; 
	}
}

bool CLogParser::ChunkToIP(const string& word )
{
	int c = std::count(word.begin(), word.end(), '.'); 
	
	if (c >= 2)
	{
		return true; 
	}
	else 
	{
		return false; 
	}
}

bool CLogParser::ChunkToNUM( const string& word )
{
	bool orFlag =  (word.find_first_of("0123456789abcdefABCDEF") == string::npos);
	bool allFlag = (word.find_first_not_of("0123456789xabcdefABCDEF.vk") == string::npos);

	return ((!orFlag) && allFlag); 
}

bool CLogParser::ChunkToNode( const string& word )
{
	if (m_nodeList.find(word) == m_nodeList.end())
	{
		return false; 
	}
	else 
	{
		return true; 
	}
	
	return false; 
}

void CLogParser::TestChunk( void )
{
	string rst; 
	ChunkMSG(rst, m_testMSG); 
	cout << "<TEST_MSG> " << m_testMSG << endl; 
	cout << "<RST_MST>  " << rst << endl; 
}

void CLogParser::GetWord( string& line, string& word, string& term)
{
	assert(!line.empty()); 
	size_t pos = line.find_first_of(" =+-()_<>{}[]:,@#$%*|"); 

	if (pos == string::npos)
	{
		word.assign(line); 
		term.assign(""); 
		line.assign(""); 
	}
	else 
	{
		word.assign(line, 0, pos);
		term.assign(line, pos, 1); 
		line.assign(line, pos+1, line.size());
	}
}

void CLogParser::ParseMSG( NUMBER& tempID, const string& oriString )
{
	assert(!oriString.empty()); 
	int id = 0; 
	GetTemplateID(id, oriString); 
	tempID = (NUMBER)id; 
}

void CLogParser::GetTemplateID(int& tempID, const string& MSG )
{//use CSIMToolbox
	assert(!MSG.empty()); 
	tempID = m_simToolbox->GetStringID(MSG); 
	//tempID = TEMPLATE_NOT_FOUND;
}

void CLogParser::UpdateTempalteList(void)
{//use CSIMToolbox
	m_simToolbox->UpdateIndex(); 
}

int CLogParser::InitializeTemplate(string template_db_name)
{//use CSIMToolbox
	m_simToolbox = new CSIMToolbox(template_db_name); 
	m_simToolbox->SetThreshold(m_simThreshold); 
	return m_simToolbox->GetStrings(m_templateStrVec); 
}

CLogParser::~CLogParser( void )
{
	if (m_simToolbox != NULL)
	{
		delete m_simToolbox; 
	}

	Clear(); 
}

void CLogParser::PrintTemplateList(string saveFName)
{
	ofstream fout(saveFName.c_str()); 
	
	if (fout == NULL)
	{
		perror("Cannot open/create the template statistics file."); 
	}

	fout << "Template List:" << endl; 

	FOR (i, (int)m_templateStrVec.size())
	{
		fout << "[IDX] " << i << " [NUM]" << m_numTemplateVec[i] << " [TEMP] " << m_templateStrVec[i] << endl; 
	}

	fout << "Type List: " << endl; 

	FOR (i, (int)m_numTypeVec.size())
	{
		if (!m_numTypeVec[i].empty())
		{
			fout << "[TYPE] " << i << " [TEMPLIST]:" << endl;
			
			for (set<int>::iterator pos = m_numTypeVec[i].begin(); pos != m_numTypeVec[i].end(); pos++)
			{
				fout << "[IDX] " << *pos << " [TEMP] " << m_templateStrVec[*pos] << endl; 
			}

			fout << endl; 
		}
	}

	fout.close(); 
}

void CLogParser::Initialize(string template_db_namespace)
{
	InitializeTemplate(template_db_namespace); 
}

void CLogParser::ChunkPartNUM( string& rst, int& nNUM, const string& word)
{
	assert(!word.empty()); 
	rst.clear(); 
	bool isBegin = false; 
	stringstream ss; 

	FOR (i, (int)word.length())
	{
		if (isdigit(word[i]))
		{
			if (!isBegin)
			{
				isBegin = true; 
			}
		}
		else if (word[i] == '.')
		{
			if (!isBegin)
			{
				rst += word[i]; 
			}
		}
		else 
		{
			if (isBegin)
			{
				ss << nNUM; 
				nNUM++; 
				rst += "NUM" + ss.str(); 
				ss.clear(); 
				ss.str(""); 
				isBegin = false; 
			}
			else 
			{
				rst += word[i]; 
			}
		}
	}

	if (isBegin)
	{
		ss << nNUM; 
		nNUM++; 
		rst += "NUM" + ss.str(); 
		ss.clear(); 
		ss.str(""); 
		isBegin = false; 
	}
}

bool CLogParser::ChunkToSD( const string& word )
{
	if (word.length() == 3 && word[0] == 's'  && word[1] == 'd' && isalpha(word[2]))
	{
		return true; 
	}
	else 
	{
		return false; 
	}
}

bool CLogParser::ExceptionCase( string& rst, const string& ori )
{
	if (ori.substr(0, 4) == "rshd")
	{
		rst = "rshd[NUM1]: root@NODE1 as root: cmd='CMD1'"; 
		return true; 
	}
	else 
	{
		rst = ""; 
		return false; 
	}
}
