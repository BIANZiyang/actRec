/*
	��ȡ���ܹ����켣��HOF��HOF��MBH��trajectory��ԭʼͼ���������� 

*/

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <string>
#include <time.h>
#include "DenseTrack.h"
#include "Initialize.h"
#include "Descriptors.h"
#include "OpticalFlow.h"

#include "densefeature.h"
#include "densetest.h"
#include "videotest.h"

using namespace cv;
using namespace std;



int main()
{
	//videotest2("H:\\action_recognition\\dataset\\youtube3\\v_biking_01_03_Xvid.avi");
	//test_youtube();
	//densetest("data\\person01_boxing_d1_uncomp.avi"); //���ڴ�й©

	//step1:������ȡ����
	//feature_extract_batch();
	feature_extract_batch_youtube();

	return 0;
}

