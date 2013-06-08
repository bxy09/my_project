//////////////////////////////////////////////////////////////////////////
//Name		:	SIMToolbox.h
//Function	:	a toolbox to provide database and language processing
//Author	:	Jun-Yan Zhu, Tsinghua University
//Note		: 
//Key: job id
//Data: acct information
//////////////////////////////////////////////////////////////////////////
#ifndef SIMTOOLBOX_H
#define SIMTOOLBOX_H
#include"MyBasicTool.h"
#include "MyDataBaseHandler.h"
#define MAX_STR_LENGTH 1000
#define MAX_UNSIGNED 10000

using namespace std;
typedef map<string, vector<unsigned> > Index; 

template<typename T1, typename T2, typename T3>
struct triple{
  T1 id1;
  T2 id2;
  T3 sim;
};

const int SUCCESS = 1;
const int FAILURE = 0; 

enum SimType 
{
	SIMTYPE_JA, 
	SIMTYPE_ED, 
};

enum WorkType 
{
	WORKTYPE_NAIVE, 
	WORKTYPE_INDEX, 
};

class CSIMToolbox {
public:
	CSIMToolbox   () ;
	~CSIMToolbox  (); 
	CSIMToolbox   (string template_db_namespace); 
	void UpdateIndex(void); 
	//Get the string ID
	int GetStringID(const string& str); 
	//Get the number of strings 
	int GetStrings(vector<string>& strVec); 
	//Set the threshold
	inline void SetThreshold(double th) {m_threshold = th; }
	inline void SetDBName(string &db_name) {this->db_name = db_name;}
	inline int getmq(){return m_q;}

private: 
	void Clear(); 
	  //Similarity Join using edit distance 
	  //bool SimilarityJoinED(const char * firstDataFilename, const char * secondDataFilename, unsigned q, unsigned threshold, vector< triple<unsigned, unsigned, unsigned> > &results);
  
	  //Similarity Join using Jaccard Similarity
	  //bool SimilarityJoinJaccard(const char * firstDataFilename, const char * secondDataFilename, unsigned q, double threshold, vector< triple<unsigned, unsigned, double> > &results);

	  //Similarity Join 
	  //bool SimilarityJoin(const char * firstDataFilename, const char * secondDataFilename, unsigned q, double threshold, vector< triple<unsigned, unsigned, double> > &results);

	
	int VerifyDuplicatedString(const string& query, vector<string>& strVec, vector<int>& candidates);

	//Compute Edit Distance for two strings 
	unsigned ComputeEditDistance(const char* str1, const char* str2); 

	//Compute Edit Distance for two strings and use early termination 
	unsigned ComputeEditDistance(const char* str1, const char* str2, unsigned thres); 

	//Compute Jaccard similarity for two strings (token-based)  
	double ComputeJaccardSim(map<string, unsigned> *a, map<string, unsigned> *b); 

	//Load data from file and create index 
	bool CreateIndex(Index*& index, vector<string>& strVec, const char* fileName, unsigned q); 

	//Clear data 
	void ClearIndex(Index*& index);  

	 // Load the index from disk if it's not in memory
	bool LoadIndex();

	// destroy the index file on disk
	bool DestroyIndex(); 

	//Get candidates 
	void GetCandidates(vector<int>& candidates, string str, Index* index, vector<string>& strVec); 

	//Get candidates using naive solution
	void NaiveSolution(vector<int>& candidates, string str, Index* index, vector<string>& strVec); 

	//Get candidates using pruning for edit distance 
	void PruningAlgorithms(vector<int>& candidates, string str, Index* index, vector<string>& strVec);  

	//Verify and add to the results 
	void VerifyAndAddToResults(vector< triple<unsigned, unsigned, double> > &results, int k, string query, vector<string>& strVec, vector<int>& candidates, double thres ); 

	//Get q-grams
	map<string, unsigned>* GetGrams(const char* s, unsigned q);

private:
	MyDataBaseHandler dbHandler;
	string db_name;
	int *templateCount;

	string m_indexFPath; 
	string m_strFPath; 
	SimType m_simType; 
	WorkType m_workType; 
	unsigned int m_q; 
	double m_threshold; 
	Index* m_index; 
	vectorString m_strVec; 
}; 

#endif //SIMTOOLBOX_H
