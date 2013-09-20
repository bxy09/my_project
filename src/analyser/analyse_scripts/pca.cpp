#include<iostream>
#include<fstream>
#include<assert.h>
#include <mlpack/core.hpp>
#include <mlpack/methods/pca/pca.hpp>
using namespace std;
using namespace arma;
using namespace mlpack;
using namespace mlpack::pca;
int main(int argc,char **argv) {
	if(argc != 4) {
		cout<<"parament error!!"<<endl;
		return -1;
	}
	char *input_file_name = argv[1];
	char *output_file_name = argv[2];
	char *output_cov_name = argv[3];
	ifstream file_in(input_file_name);
	if(!file_in) {
		cout<<"can\'t open file:"<<input_file_name<<endl;
		return -1;
	}
	int feature_num, record_num;
	file_in>>feature_num>>record_num;
	mat data = mat(record_num,feature_num);
	running_stat_vec<double> stats;
	for(int i = 0; i< record_num; i++) {
		for(int j = 0; j< feature_num; j++) {
			file_in>>data(i,j);
		}
		stats(data.row(i));
	}
	mat mean = stats.mean();
	mat stddev = stats.stddev(1);
	running_stat_vec<double> stats3(1);
	for(int i = 0; i< record_num; i++) {
		for(int j = 0; j < feature_num; j++) {
			data(i,j) = (data(i,j) - mean(j))/stddev(j);
		}
		stats3(data.row(i));
	}
	file_in.close();
	mat cov = stats3.cov(1);
	ofstream cov_out(output_cov_name);
	cov.save(cov_out,csv_ascii);
	cout<<cov.n_rows<<endl;
	
	PCA p;
	mat coeff, coeff1;
	vec eigVal, eigVal1;
	mat score, score1;
	p.Apply(trans(data), score, eigVal, coeff);
	score = trans(score);
	running_stat_vec<double> stats2;
	for(int i = 0; i< record_num; i++) {
		stats2(score.row(i));
	}
	mat new_eigVla = stats2.var(1);
	cout<<new_eigVla.n_rows<<endl;
	cout<<new_eigVla<<endl;
	ofstream file_out(output_file_name);
	coeff = trans(coeff);
	coeff.save(file_out,csv_ascii);
	double all = 0;
	double over_one = 0;
	int num_over_one = 0;
	double top_10 = 0;
	double top_20 = 0;
	for(int i = 0; i < new_eigVla.n_elem;i++) {
		double cur = new_eigVla(i);
		all += cur;
		if(cur>=1) {
			over_one += cur;
			num_over_one ++;
		}
		if(i<20) {
			top_20 += cur;
			if(i < 10) {
				top_10 += cur;
			}
		}
	}
	cout<<"row*row"<<dot(coeff.row(0),trans(coeff.row(0)))<<endl;
	cout<<"col*col"<<dot(coeff.col(0),trans(coeff.col(0)))<<endl;
	cout<<"all:"<<all<<endl;
	cout<<"over one:"<<over_one<<endl;
	cout<<"num over one:"<<num_over_one<<endl;
	cout<<"top 20:"<<top_20<<endl;
	cout<<"top 10:"<<top_10<<endl;
	return 0;
}
