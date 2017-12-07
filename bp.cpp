//#include"mex.h"
#include<iostream>
#include<cmath>
#include<vector>
#include<cstdlib>
#include<ctime>
#include<fstream>
#include<string>
#include<algorithm>
using namespace std;
const int Option = 0; //0��ѵ����1�����

//�����
inline double Sigmoid(double x) {
	return 1.0 / (1.0 + exp(-x));
}

//��Ԫ
/*
������Ԫ��Ӧ������
1. ��ֵ
2. ��ǰֵ
2. �����
*/
class Neuron {
public:
	Neuron() { value = 0; }
public:
	double value; //�ڵ㵱ǰֵ
};



//������Ԫ
/*
Ӧ������
1. ��������ÿһ���ڵ��Ȩֵ
*/
class InputNeuron : public Neuron {
public:
	vector<double> v;
};

//������Ԫ
/*
Ӧ������
1. �������ÿһ���ڵ��Ȩֵ
2. ��ֵ
3. ���ֵ b = sigmoid(v - theta);
4. e //һ���м���
*/
class HiddenNeuron : public Neuron {
public:
	vector<double> w;
	double gamma;
	double b;
	double e;
};

//�����Ԫ
/*
Ӧ������
1. ��ȷ���ֵ
2. ʵ�����ֵ
3. ��ֵ
4. g //һ���м���
*/
class OutputNeuron : public Neuron {
public:
	int right;
	double y;
	double theta; 
	double g;
};

//������BP������
class BPNeuralNetwork {
public:
	BPNeuralNetwork(int in_num,int hidden_num,int out_num,string param_file =""); //��ʼ��
	void Train(int num,  double data[][1024],  int labels[][4]); // �õ��Ľ�����浽txt��,�ٴ��½���ʱ��ֱ�Ӷ�����
	void Predict(double *data, double* result); //Ԥ��
public:
	const int in_nodes;
	const int hidden_nodes;
	const int out_nodes;
	vector<InputNeuron> input_layer;
	vector<HiddenNeuron> hidden_layer;
	vector<OutputNeuron> output_layer;
	double yita; //learning rate
private:
	double Random() {
		return (double(rand()) / RAND_MAX);
	}
};

BPNeuralNetwork::BPNeuralNetwork(int in_num, int hidden_num, int out_num, string param_file)
	:in_nodes(in_num),hidden_nodes(hidden_num),out_nodes(out_num){
	
	yita = 1;

	input_layer.resize(in_nodes);
	hidden_layer.resize(hidden_nodes);
	output_layer.resize(out_nodes);

	fstream infile(param_file);
	//�����ѵ���õĲ�����ֱ����;���û�о������ֵ
	if (infile.is_open()) {

		for (auto& ele : input_layer) {
			//�������Ȩֵ��Ŀ
			ele.v.resize(hidden_nodes);
			//��param 1:��ǰ������Ԫ�������Ȩֵ��
			//�� in_nodes * hidden_nodes ��
			for (auto& e : ele.v) {
				infile >> e;  
			}
		}

		for (auto& ele : hidden_layer) {
			//��param 2:������ֵ��
			//�� hidden_nodes ��
			infile >> ele.gamma;
			//��������Ȩֵ��Ŀ
			ele.w.resize(out_nodes);
			//��param 3:��ǰ������Ԫ��������Ȩֵ��
			//�� hidden_nodes * out_nodes ��
			for (auto &e : ele.w) {
				infile >> e;
			}
		}

	}
	//û���ֳɵĲ������Ǿ������ʼ��
	else {
		for (auto& ele : input_layer) {
			//�������Ȩֵ��Ŀ
			ele.v.resize(hidden_nodes);
			//��param 1:��ǰ������Ԫ�������Ȩֵ��
			//�� in_nodes * hidden_nodes ��
			for (auto& e : ele.v) {
				e = Random();
			}
		}

		for (auto& ele : hidden_layer) {
			//��param 2:������ֵ��
			//�� hidden_nodes ��
			ele.gamma = Random();
			//��������Ȩֵ��Ŀ
			ele.w.resize(out_nodes);
			//��param 3:��ǰ������Ԫ��������Ȩֵ��
			//�� hidden_nodes * out_nodes ��
			for (auto &e : ele.w) {
				e = Random();
			}
		}
	}

}

void BPNeuralNetwork::Train(int num, double data[][1024], int labels[][4]) {

	double delta1 = 1, delta2 = 1, delta3 = 1, delta4 = 1;
	const double eps = 1e-6;
	int cnt = 0;
	//������3k��
	while ( cnt < 3) {
		//ÿһ����һ������,len����������
		cout << cnt << endl;
		for (int i = 0; i < num; ++i) {
			
			//<-----------------------���㵱ǰ�������------------------------->
			//������������ȷ����
			for (int l = 0; l < out_nodes; ++l) {
				output_layer[l].right = labels[i][l];
			}

			//��ʼ������
			for (int q = 0; q < hidden_nodes; ++q) {
				hidden_layer[q].value = 0;
			}
			//��ʼ�������
			for (int l = 0; l < out_nodes; ++l) {
				output_layer[l].value = 0;
			}

			//����->�����->����
			for (int d = 0; d < in_nodes; ++d) {
				//���� ->�����
				input_layer[d].value = data[i][d];  //������һ��ֵ��Ӧһ��������Ԫ
													//����� -> ����
				for (int q = 0; q < hidden_nodes; ++q) {
					//      �����ֵ       +=    ����->�����Ȩֵ  *    ������ֵ
					hidden_layer[q].value += input_layer[d].v[q] * input_layer[d].value;
				}
			}

			//������������
			for (int q = 0; q < hidden_nodes; ++q) {
				//   �������     =   sigmoid (      �����ֵ      -   ��ֵ              )
				hidden_layer[q].b = Sigmoid(hidden_layer[q].value - hidden_layer[q].gamma);
			}

			//����->�����
			for (int q = 0; q < hidden_nodes; ++q) {
				for (int l = 0; l < out_nodes; ++l) {
					//    ������ֵ       +=   ����->������Ȩֵ  *    �����ֵ
					output_layer[l].value += hidden_layer[q].w[l] * hidden_layer[q].b;
				}
			}

			//�������������
			for (int l = 0; l < out_nodes; ++l) {
				//   ��������    =   sigmoid (      ������ֵ    -   ��ֵ              )
				output_layer[l].y = Sigmoid(output_layer[l].value - output_layer[l].theta);
			}

			//<-----------------------���������м����------------------------->
			//����gֵ
			double y, y_;
			for (int l = 0; l < out_nodes; ++l) {
				y = output_layer[l].right;
				y_ = output_layer[l].y;
				output_layer[l].g = y_*(1 - y_)*(y - y_);
			}

			double tmp;
			//����eֵ
			for (int q = 0; q < hidden_nodes; ++q) {
				tmp = 0;
				for (int l = 0; l < out_nodes; ++l) {
					tmp += hidden_layer[q].w[l] * output_layer[l].g;
				}
				hidden_layer[q].e = hidden_layer[q].b * (1 - hidden_layer[q].b) * tmp;
			}

			//<-----------------------���²�����w,v,theta,gamma)------------------------->

			//���� w  (���� -> ����� ��Ȩֵ)
			for (int q = 0; q < hidden_nodes; ++q) {
				for (int l = 0; l < out_nodes; ++l) {
					//����ֵ =  ѧϰ���� * g * �������ֵ
					delta1 = yita*output_layer[l].g*hidden_layer[q].b;
					hidden_layer[q].w[l] += delta1;
				}
			}

			//���� theta (�������ֵ)
			for (int l = 0; l < out_nodes; ++l) {
				//����ֵ = - ѧϰ���� * g 
				delta2 = -yita*output_layer[l].g;
				output_layer[l].theta += delta2;
			}

			//���� v (���� -> ���� ��Ȩֵ)
			for (int d = 0; d < in_nodes; ++d) {
				for (int q = 0; q < hidden_nodes; ++q) {
					//����ֵ =  ѧϰ���� * e * ���ֵ
					delta3 = yita*hidden_layer[q].e*input_layer[d].value;
					input_layer[d].v[q] += delta3;
				}
			}

			//���� gamma (������ֵ)
			for (int q = 0; q < hidden_nodes; ++q) {
				//����ֵ = - ѧϰ���� * e 
				delta4 = -yita*hidden_layer[q].e;
				hidden_layer[q].gamma += delta4;
			}

		}

		++cnt;
	}
	
	cout << cnt << endl;
	cnt = 0;
	double Max = -1;
	int pos;
	int pos2;
	double *result = new double[4];
	for (int i = 0; i < num; ++i) {
		Predict(data[i], result);
		Max = -1;
		for (int j = 0; j < 4; ++j) {
			if (labels[i][j] == 1)
				pos2 = j;
			if (result[j] > Max) {
				Max = result[j];
				pos = j;
			}
		}
		if (pos != pos2)
			++cnt;
	}
	cout << "������Ϊ:" << (double)cnt / num << endl;
}


void BPNeuralNetwork::Predict(double *data,double* result) {
	//<-----------------------���㵱ǰ�������------------------------->
	
	//��ʼ������
	for (int q = 0; q < hidden_nodes; ++q) {
		hidden_layer[q].value = 0;
	}
	//��ʼ�������
	for (int l = 0; l < out_nodes; ++l) {
		output_layer[l].value = 0;
	}

	//����->�����->����
	for (int d = 0; d < in_nodes; ++d) {
		//���� ->�����
		input_layer[d].value = data[d];  //������һ��ֵ��Ӧһ��������Ԫ
											//����� -> ����
		for (int q = 0; q < hidden_nodes; ++q) {
			//      �����ֵ       +=    ����->�����Ȩֵ  *    ������ֵ
			hidden_layer[q].value += input_layer[d].v[q] * input_layer[d].value;
		}
	}

	//������������
	for (int q = 0; q < hidden_nodes; ++q) {
		//   �������     =   sigmoid (      �����ֵ      -   ��ֵ              )
		hidden_layer[q].b = Sigmoid(hidden_layer[q].value - hidden_layer[q].gamma);
	}

	//����->�����
	for (int q = 0; q < hidden_nodes; ++q) {
		for (int l = 0; l < out_nodes; ++l) {
			//    ������ֵ       +=   ����->������Ȩֵ  *    �����ֵ
			output_layer[l].value += hidden_layer[q].w[l] * hidden_layer[q].b;
		}
	}

	//�������������
	for (int l = 0; l < out_nodes; ++l) {
		//   ��������    =   sigmoid (      ������ֵ    -   ��ֵ              )
		output_layer[l].y = Sigmoid(output_layer[l].value - output_layer[l].theta);
		result[l] = output_layer[l].y;
	}


}

#if Option
//MATLAB���ø�ʽ��
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]) {

}
#endif

#if !Option
int main()
{
	
	int sample_num = 96;
	int in_nodes = 1024;
	int hidden_nodes = 10;
	int out_nodes = 4;
	BPNeuralNetwork net(in_nodes, hidden_nodes, out_nodes);
	
	double data[96][1024];
	int labels[96][4];
	fstream infile("data.txt");
	for (int i = 0; i < sample_num; ++i) {
		for (int j = 0; j < in_nodes; ++j) {
			infile >> data[i][j];
		}
	}

	infile.close();

	
	infile.open("labels.txt");
	for (int i = 0; i < sample_num; ++i) {
		for (int j = 0; j < out_nodes; ++j) {
			infile >> labels[i][j];
			
		}
		
	}
	
	
	infile.close();

	net.Train(sample_num, data, labels);

	system("pause");
	return 0;
}

#endif