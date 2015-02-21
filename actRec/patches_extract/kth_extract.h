#pragma once

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <list>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv/cv.h>

using namespace cv;
using namespace std;

/*
	dataһ��32�У�
	1��֡����ĩ֡����0��ʼ��
	2�����ű���
	3������30�ֱ���15֡��center��x,y��size��32*32��
*/

#define CNUM 30 
	//data���ݺ���30�����ݣ���ʾcenter��x,y
#define TROW 200
	//test row��ȡǰ���200��
#define PATCHSIZE 32
	//patch��С��32*32
#define FNUM 15 
	//֡����15֡
#define SHOW 0

int extract(const char* videopath,char* datapath,char* outpath)
{
	char c;
    int fcnt = 0;          // Frame counter
	int tcnt = 0;

	VideoCapture video(videopath);

    if (!video.isOpened())
    {
        cout  << "Could not open video!!check out if you had installed Xvid !"  << endl;
        return -1;
    }

    Size capsize = Size((int) video.get(CV_CAP_PROP_FRAME_WIDTH),
                     (int) video.get(CV_CAP_PROP_FRAME_HEIGHT));

	//��ȡǰ��200��������
	float endFrame[TROW];
	float scale[TROW];
	float center[TROW][CNUM];
	//������
	ifstream fin;
	fin.open(datapath);
	for(int row=0;row<TROW;row++)
	{
		fin>>endFrame[row];
		fin>>scale[row];
		for(int col=0;col<CNUM;col++)
		{
			fin>>center[row][col];
		}
	}
	fin.close();

	int maxfcnt = (int)endFrame[TROW-1]; //���֡��

	/*
	cout<<endFrame[0]<<" "<<scale[0]<<" ";
	for(int col=0;col<CNUM;col++)
	{
		cout<<center[0][col]<<" ";
	}
	cout<<endl;
	*/

	ofstream fout;
	fout.open(outpath);

	std::list<Mat> mat_list;
	std::list<int> fcnt_list;
    for(;;) //Show the image captured in the window and repeat
    {
        Mat frame,fgray;
		Mat fresize;
		
		video >> frame;
 
        if (frame.empty() )
        {
            cout << "Play over!";
            break;
        }

		if(fcnt>(maxfcnt+1))
			break;

		cvtColor(frame,fgray,CV_BGR2GRAY);
		//�ӵ�һ֡��ʼ��push��list��
		mat_list.push_back(fgray);
		fcnt_list.push_back(fcnt);
		if(mat_list.size() >=  (FNUM+1)  )
		{
			mat_list.pop_front();
			fcnt_list.pop_front();
		}
		

		for(int row=0;row<TROW;row++)
		{
			/*
			if(row%10 == 0)
			{
				cout<<row<<" ";
			}*/
			int subcnt = 0;
			if(fcnt == ((int)endFrame[row]-1))	//15: 0--14
			{         
				//cout<<++tcnt<<" ";
				++tcnt;
				if(tcnt%20 == 0)
				{
					cout<<tcnt<<" ";
				}

				//cout<<"scale:"<<scale[row]<<" ";
				//for (std::list<int>::iterator it = fcnt_list.begin(); it != fcnt_list.end();it++) 
				//{
				//	cout<<*it<<" ";
				//}
				//cout<<endl;
				//��������15֡������ȡ
				int a=0;
				char path[100];
				for (std::list<Mat>::iterator it = mat_list.begin(); it != mat_list.end();it++) 
				{
					Mat tmp = *it;
					
					//if(0 == row)
					//{
						//sprintf(path,"img_%d.bmp",a);
						//imwrite(path,tmp);
						//imshow("tp",tmp);
						//waitKey(0);
					//}

					//��15֡�ֱ���ȡ��ͼ������
					//ÿ���켣��Χ����ά����32*32*15=15360
					//1���ȼ���Rect��x,yֵ
					int center_x,center_y;
					//center[200][30]
					center_x = (int)(center[row][a*2]/scale[row]);
					center_y = (int)(center[row][a*2+1]/scale[row]);

					Mat fres;
					Size sz;
					//cout<<"****scale[row]:"<<scale[row]<<" "<<endl; 
					//cout<<1/scale[row]<<" "<<1/scale[row];
					resize(tmp,fres,sz,1/scale[row],1/scale[row]);
					//cout<<fres.rows<<" "<<fres.cols<<endl;
					Rect rc;
					rc.width = PATCHSIZE;
					rc.height = PATCHSIZE;

					int x,y;
					x = center_x-PATCHSIZE/2;
					if(x<0)
					{
						x = 0;
					}
					if( (center_x+PATCHSIZE/2) > fres.cols)
					{
						x = fres.cols-PATCHSIZE;
					}

					y = center_y-PATCHSIZE/2;
					if(y<0)
					{
						y=0;
					}
					if( (center_y+PATCHSIZE/2) >fres.rows)
					{
						y = fres.rows-PATCHSIZE;
					}
					rc.x = x;
					rc.y = y;

					Mat imsub = fres(rc);
					
					for(int row=0; row<imsub.rows; row++)
					{
						unsigned char *pdata = imsub.ptr<unsigned char>(row);
						for(int col=0; col<imsub.cols; col++)
						{
							//cout<<(int)pdata[col]<<" ";
							fout<<(int)pdata[col]<<" ";
						}
						//cout<<endl;
					}
					//imshow("imsub",imsub);
					//waitKey(40);
					a++;		
					//cout<<".";
				}
				fout<<endl;
				subcnt++;		
			}
			//cout<<endl<<"subcnt:"<<subcnt;
		}	
        ++fcnt;

#if SHOW==1
		imshow("frame", frame);
		c = (char)cvWaitKey(33);
		if (c == 27) break;
#endif

    }
	fout.close();

	cout<<"finished: "<<videopath<<endl;

	return 0;
}