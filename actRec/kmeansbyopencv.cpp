#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <string>
#include <fstream>


using namespace cv;
using namespace std;

/*
	kmeans����
	mykmeans input.txt output.txt rows cols nClusters eps

*/


int main( int argc, char** argv )
{
	//1����������
	//const int ROWS = 120000;
	//const int COLS = 225;
	int rows = atoi(argv[3]);
	int cols = atoi(argv[4]);
	int nClusters = atoi(argv[5]);
	double eps = atof(argv[6]);

	Mat p = Mat::zeros(rows,cols,CV_32F);
	ifstream fin;	//�ļ���ر���
	float a;		//�����ʱ����

	
	cout<<"���������С�����"<<endl;
	fin.open(argv[1]);
	//fin.open("data\\poolmax_nF225_bN5000_iter100.txt");
	if(!fin)
	{
		cout<<"�޷����ļ�"<<endl;
		return -1;
	}

	for(int row=0;row<rows;row++)
	{
		float* pdata = p.ptr<float>(row);
		for(int col=0;col<cols;col++)
		{
			fin>>a;
			pdata[col] = a;
		}
	}
	fin.close();
	cout<<"����������ϣ�"<<endl;
	cout<<"��ʾ��һ�����ݣ�"<<endl;
	for(int i=0;i<1;i++)
	{
		for(int j=0;j<cols;j++)
		{
			cout<<p.at<float>(i,j)<<" ";
		}
		cout<<endl;
	}
	cout<<"*****************************************************"<<endl;

	cout<<"kmeans�����С�����"<<endl;
	//const int nClusters = 4000;
	Mat bestLabels, centers;
	//eps:0.5
	kmeans(p, nClusters, bestLabels,
        TermCriteria( CV_TERMCRIT_EPS+CV_TERMCRIT_ITER, 1000, eps),
        3, KMEANS_PP_CENTERS, centers);

	cout<<"kmeans�������������bestLabels���顣����"<<endl;
	cout<<"eps:"<<eps<<endl;

	ofstream fout;
	//fout.open("data\\poolmax_nF225_bN5000_iter100_bestLabels_c4000_EPS0_5.txt");
	fout.open(argv[2]);

	//fout<<bestLabels;
	//bestLabels��60000��һ�е�int����
	for(int row=0;row<rows;row++)
	{
		fout<<bestLabels.at<int>(row,0)<<endl;
	}
	fout << flush; 
	fout.close();
	cout<<"����bestLabels��ϣ�"<<endl;

	cout<<"ǰ60��bestLabels��"<<endl;
	for(int row=0;row<60;row++)
	{
		cout<<bestLabels.at<int>(row,0)<<" ";
	}
	cout<<endl;
	cout<<"����bestLabels������ϣ�"<<endl;

	
	return 0;
}