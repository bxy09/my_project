//Author: Junyan Zhu, CS83, 2008011372
#include "SIMToolbox.h"

unsigned g_dist[MAX_STR_LENGTH][MAX_STR_LENGTH];

CSIMToolbox::CSIMToolbox():dbHandler("localhost")
{
	Clear();
	templateCount = new int[1000];
}
CSIMToolbox::CSIMToolbox( string template_db_namespace):dbHandler("localhost")
{
	Clear();
	db_name = template_db_namespace;
	templateCount = new int[1000];
	//m_indexFPath = indexFPath; 
	//m_strFPath = strFPath; 
	//CreateIndex(m_index, m_strVec, m_strFPath.c_str(), m_q); 
}

CSIMToolbox::~CSIMToolbox()
{
	ClearIndex(m_index); 
	Clear();
	delete [] templateCount;
}

//Compute Edit Distance for two strings 
unsigned CSIMToolbox::ComputeEditDistance(const char* str1, const char* str2) 
{
	unsigned i = 0; 
	unsigned j = 0;
	unsigned len1 = 0; 
	unsigned len2 = 0; 

	for (i = 0; str1[i]; i++) 
	{	
		g_dist[i][0] = i;
	}

	len1 = i; 
	g_dist[i][0] = i; 

	for (j = 0; str2[j]; j++) 
	{
		g_dist[0][j] = j;
	}

	len2 = j;
	g_dist[0][j] = j; 

	for (i = 1; i <= len1; i++)
	{
		for (j = 1; j <= len2; j++) 
		{
			if (str1[i-1] == str2[j-1])
			{
				g_dist[i][j] = g_dist[i-1][j-1];
			}
			else
			{
				g_dist[i][j] = min(g_dist[i-1][j], min(g_dist[i-1][j-1], g_dist[i][j-1])) + 1;
			}
		}
	}

	return g_dist[i-1][j-1];
}

//Compute Edit Distance for two strings and use early termination 
unsigned CSIMToolbox::ComputeEditDistance(const char* str1, const char* str2, unsigned thres)
{
	unsigned i = 0; 
	unsigned j = 0;
	unsigned len1 = 0; 
	unsigned len2 = 0; 

	for (i = 0; str1[i]; i++) 
	{	
		g_dist[i][0] = i;
	}

	len1 = i; 
	g_dist[i][0] = i; 

	for (j = 0; str2[j]; j++) 
	{
		g_dist[0][j] = j;
	}

	len2 = j;
	g_dist[0][j] = j; 

	for (i = 1; i <= len1; i++)
	{
		bool isStop = true; 

		for (j = 1; j <= len2; j++) 
		{
			if (str1[i-1] == str2[j-1])
			{
				g_dist[i][j] = g_dist[i-1][j-1];
			}
			else
			{
				g_dist[i][j] = min(g_dist[i-1][j], min(g_dist[i-1][j-1], g_dist[i][j-1])) + 1;
			}

			if (isStop && g_dist[i][j] <= thres)
			{
				isStop = false; 
			}
		}

		if (isStop)
		{
			return MAX_UNSIGNED; 
		}

	}

	return g_dist[i-1][j-1];
}

//Compute Jaccard similarity for two strings 
double CSIMToolbox::ComputeJaccardSim(map<string, unsigned>* str1, map<string, unsigned>* str2) 
{
	map<string, unsigned>::iterator p1 = str1->begin();
	map<string, unsigned>::iterator p2 = str2->begin();
	int insertGram = 0; 
	int unionGram = 0;
	double jacc = 0; 

	while (p1 != str1->end() && p2 != str2->end()) 
	{
		if (p1->first == p2->first) 
		{
			p1++; 
			p2++;
			insertGram++; 
			unionGram++;
		} 
		else if (p1->first < p2->first) 
		{
			p1++;
			unionGram++;
		} 
		else 
		{
			p2++;
			unionGram++;
		}
	}

	while (p1 != str1->end()) 
	{
		unionGram++;
		p1++; 
	}

	while (p2 != str2->end())
	{
		unionGram++;
		p2++;
	}

	jacc = (double)insertGram / unionGram; 
	return jacc; 
}

//Get q-grams
map<string, unsigned>* CSIMToolbox::GetGrams(const char* s, unsigned q) 
{
	map<string, unsigned>* gram = new map<string, unsigned>();
	while (*(s+q-1)) 
	{
		(*gram)[string(s, q)]++;
		s++; 
	}

	return gram;
}

//Load data from file and create index 
bool CSIMToolbox::CreateIndex(Index*& index, vector<string>& strVec, const char* fileName, unsigned q)
{
	FILE* file = fopen(fileName, "r");
	
	if (file == NULL)
	{
		printf("Cannot open the file <%s>.\n", fileName); 
		return FAILURE; 
	}

	//printf("Load data from file <%s>.\n", fileName); 

	index = new Index();
	char str[MAX_STR_LENGTH];
	unsigned nCount = 0; 

	while (!feof(file)) 
	{
		char* p = fgets(str, MAX_STR_LENGTH, file); 

		if (!p) 
		{
			break;
		}

		while (*p != '\r' && *p != '\0' && *p != '\n' ) 
		{
			p++; 
		}
	
		*p = 0;
	
		map<string, unsigned>* g = GetGrams(str, q);
		map<string, unsigned>::iterator iter; 

		for (iter = g->begin(); iter != g->end(); iter++) 
		{
			(*index)[iter->first].push_back(nCount);
		}
		strVec.push_back(string(str));
		delete g;
		nCount ++;
	}

	fclose(file); 
	return SUCCESS; 
}

//Clear index 
void CSIMToolbox::ClearIndex(Index*& index) 
{
	//printf("Clear index.\n"); 

	if (index == NULL)
	{
		return; 
	}
	map<string, vector<unsigned> >::iterator iter; 

	for (iter = index->begin(); iter != index->end(); iter++) 
	{
		(*index)[iter->first].clear();
	}

	index->clear(); 
	index = NULL; 
}

void CSIMToolbox::VerifyAndAddToResults(vector< triple<unsigned, unsigned, double> > &results, int k, string query, vector<string>& strVec, vector<int>& candidates, double thres )
{
	int nCandidates = candidates.size(); 

	switch (m_simType)
	{
	case SIMTYPE_ED: 

		for (int i = 0; i < nCandidates; i++)
		{
			unsigned ed = ComputeEditDistance(query.c_str(), strVec[candidates[i]].c_str(), unsigned(m_threshold)); //m_q);
			
			if (ed <= (unsigned)thres) 
			{
				triple<unsigned, unsigned, double> t;
				t.id1 = k;
				t.id2 = i;
				t.sim = ed;
				results.push_back(t); 
			}
		}

		break; 

	case SIMTYPE_JA: 

		for (int i = 0; i < nCandidates; i++)
		{
			map<string, unsigned>* gram1 = GetGrams(query.c_str(), m_q);
			map<string, unsigned>* gram2 = GetGrams(strVec[candidates[i]].c_str(), m_q);
			double jaccard = ComputeJaccardSim(gram1, gram2);

			if (jaccard <= thres) 
			{
				triple<unsigned, unsigned, double> t;
				t.id1 = k;
				t.id2 = i;
				t.sim = jaccard;
				results.push_back(t); 
			}
		}

		break;

	default:
		printf("Wrong similarity type input.\n");
		exit(-1); 
	}
}

void CSIMToolbox::GetCandidates(vector<int>& candidates, string str, Index* index, vector<string>& strVec)
{
	candidates.clear(); 

	switch (m_workType)
	{
	case WORKTYPE_NAIVE: 
		NaiveSolution(candidates, str, index, strVec); 
		break; 
	case WORKTYPE_INDEX: 
		PruningAlgorithms(candidates, str, index, strVec); 
		break; 
	default:
		printf("Wrong work type input.\n"); 
		exit(-1); 
		break; 
	}
}

void CSIMToolbox::NaiveSolution(vector<int>& candidates, string str, Index* index, vector<string>& strVec )
{
	int dbSize = dbHandler.count(db_name,"str");
	int i = 0; 

	for (i = 0; i < dbSize; i++)
	{
		candidates.push_back(i); 
	}
}

void CSIMToolbox::PruningAlgorithms(vector<int>& candidates,  string str, Index* index, vector<string>& strVec)
{
	unsigned len = str.size();
	map<string, unsigned>* gram = GetGrams(str.c_str(), m_q);
	if (gram->empty())
	{
		return; 
	}
	int templateInTotal = dbHandler.count(db_name,"str");
	assert(templateInTotal<=1000);
	memset(templateCount,0,4*1000);
	for (map<string, unsigned>::iterator it = gram->begin(); it != gram->end(); it++)
	{
		BSONObj column = BSON("tempID"<<1);
		aptr_dbc cursor = dbHandler.query(db_name+".index",
				QUERY("_id"<<it->first),0,0,&column);
		if(cursor->more()){
			vector<mongo::BSONElement> temp = cursor->next()["tempID"].Array();
			for(vector<mongo::BSONElement>::iterator i = temp.begin(); i != temp.end();i++) {
				templateCount[i->Int()]+=it->second;
			}
			assert(cursor->more()==0);
		}
	}
	double thres = 0; 
	int nGram = gram->size(); 

	switch (m_simType)
	{
	case SIMTYPE_ED: 
		thres = len + 1 - m_q * (m_threshold + 1);
		break; 
	case SIMTYPE_JA:
		thres = max(m_threshold * nGram, m_threshold / (1 + m_threshold) * (nGram + 1));
		break; 
	default:
		printf("Wrong similarity type input.\n"); 
		exit(-1); 
	}

	for (unsigned i = 0; i < templateInTotal; i++) 
	{
		if (templateCount[i] >= thres)
		{
			candidates.push_back(i); 
		}
	}
	gram->clear(); 
	delete gram; 
}

void CSIMToolbox::Clear()
{
	m_indexFPath.clear(); 
	m_strFPath.clear(); 
	m_strVec.clear(); 
	m_simType = SIMTYPE_JA; 
	m_workType = WORKTYPE_INDEX; 
	m_q = 3; 
	m_threshold = 0.95; 
	m_index = NULL; 
}

bool CSIMToolbox::DestroyIndex()
{
	printf("Destroy the index and delete the index file.\n"); 
	ClearIndex(m_index); 

	FILE* test = fopen(m_indexFPath.c_str(), "rt"); 

	if (test != NULL)
	{
		fclose(test); 
		remove(m_indexFPath.c_str()); 
	}

	return SUCCESS;
}

bool CSIMToolbox::LoadIndex()
{
	ClearIndex(m_index); 
	m_index = new Index(); 
	FILE* indexFile = fopen(m_indexFPath.c_str(), "rt"); 

	if (indexFile == NULL)
	{
		printf("Cannot load the index file <%s>.\n", m_indexFPath.c_str()); 
		return FAILURE; 
	}

	long unsigned nIndex = 0; 
	fscanf(indexFile, "%lu\n", &nIndex); 

	for (long unsigned i = 0; i < nIndex; i++)
	{
		char str[MAX_STR_LENGTH];
		char* p = fgets(str, MAX_STR_LENGTH, indexFile); 

		if (p == NULL) 
		{
			break;
		}

		while (*p != '\r' && *p != '\n' && *p != '\0') 
		{
			p++;
		}

		*p = 0;

		string indexKey = string(str);
		unsigned count;
		fscanf(indexFile, "%u\n", &count);

		while (count > 0) 
		{
			unsigned p;
			fscanf(indexFile, "%u", &p);
			(*m_index)[indexKey].push_back(p);
			count--; 
		}

		fgets(str, MAX_STR_LENGTH, indexFile);
	}

	printf("Load the index file.\n"); 
	fclose(indexFile); 
	return SUCCESS;
}

void CSIMToolbox::UpdateIndex( void )
{
	ClearIndex(m_index); 
	m_strVec.clear(); 
	CreateIndex(m_index, m_strVec, m_strFPath.c_str(), m_q); 
}

int CSIMToolbox::GetStringID( const string& str )
{
	static string last_string[3] = {"","",""};
	static int update_index = 0;
	static int buffer_id[3] = {-1,-1,-1};
	for(int i = 0;i < 3; i++) {
		if(str == last_string[i]) {
			return buffer_id[i];
		}
	}
	string tempstr = str; 
	vector<int> candidates; 
	GetCandidates(candidates, tempstr, m_index, m_strVec); 
	int id = VerifyDuplicatedString(tempstr, m_strVec, candidates); 
	int stringID = -1; 
	if (id == -1)
	{
		stringID = -1;
		int extnum = dbHandler.count(db_name,"str");
		dbHandler.insert(db_name+".str",BSON("_id"<<extnum<<"str"<<str),0);
		stringID = extnum;
		map<string, unsigned>* gram = GetGrams(str.c_str(), m_q);
		for (map<string, unsigned>::iterator it = gram->begin(); it != gram->end(); it++)
		{
			dbHandler.update(db_name+".index",QUERY("_id"<<it->first),
					BSON("$push"<<BSON("tempID"<<stringID)),1);
		}
		gram->clear();
		delete gram;
	}
	else 
	{
		stringID = candidates[id]; 
	}
	candidates.clear();
	last_string[update_index] = str;
	buffer_id[update_index] = stringID;
	update_index ++;
	if(update_index >= 3) update_index-=3;
	return stringID; 
}

int CSIMToolbox::VerifyDuplicatedString( const string& query, vector<string>& strVec, vector<int>& candidates )
{
	int nCandidates = candidates.size(); 
	#undef max

	unsigned min_ed = numeric_limits<unsigned>::max(); 
	double min_jaccard = numeric_limits<double>::max(); 
	int select_i = -1; 
	map<string, unsigned>* gram1 = NULL; 
	switch (m_simType)
	{
	case SIMTYPE_ED: 

		for (int i = 0; i < nCandidates; i++)
		{
			aptr_dbc cursor = dbHandler.query(db_name+".str",QUERY("_id"<<candidates[i]));
			string template_str = (cursor->next())["str"].String();
			assert(!cursor->more());
			unsigned ed = ComputeEditDistance(query.c_str(), template_str.c_str(), unsigned(m_threshold)); //m_q);

			if (ed < min_ed)
			{
				min_ed = ed; 
				select_i = i; 
			}
		}

		break; 

	case SIMTYPE_JA: 

		gram1 = GetGrams(query.c_str(), m_q);

		for (int i = 0; i < nCandidates; i++)
		{
			aptr_dbc cursor = dbHandler.query(db_name+".str",QUERY("_id"<<candidates[i]));
			string template_str = (cursor->next())["str"].String();
			assert(!cursor->more());
			map<string, unsigned>* gram2 = GetGrams(template_str.c_str(), m_q);
			double jaccard = ComputeJaccardSim(gram1, gram2);
			if (jaccard < min_jaccard)
			{
				min_jaccard = jaccard; 
				select_i = i; 
			}

			gram2->clear(); 
			delete gram2; 
		}

		gram1->clear(); 
		delete gram1; 

		break;

	default:
		perror("Wrong similarity type input");
		break; 
	}

	return select_i; 
}

int CSIMToolbox::GetStrings( vector<string>& strVec )
{
	//strVec.assign(m_strVec.begin(), m_strVec.end());
	return 0;
	//return (int)m_strVec.size(); 
}

