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
const int Option = 0; //0是训练，1是输出

//激活函数
inline double Sigmoid(double x) {
	return 1.0 / (1.0 + exp(-x));
}

//神经元
/*
所有神经元都应包含：
1. 阈值
2. 当前值
2. 激活函数
*/
class Neuron {
public:
	Neuron() { value = 0; }
public:
	double value; //节点当前值
};



//输入神经元
/*
应包含：
1. 到隐含层每一个节点的权值
*/
class InputNeuron : public Neuron {
public:
	vector<double> v;
};

//隐层神经元
/*
应包含：
1. 到输出层每一个节点的权值
2. 阈值
3. 输出值 b = sigmoid(v - theta);
4. e //一个中间量
*/
class HiddenNeuron : public Neuron {
public:
	vector<double> w;
	double gamma;
	double b;
	double e;
};

//输出神经元
/*
应包含：
1. 正确输出值
2. 实际输出值
3. 阈值
4. g //一个中间量
*/
class OutputNeuron : public Neuron {
public:
	int right;
	double y;
	double theta; 
	double g;
};

//单隐层BP神经网络
class BPNeuralNetwork {
public:
	BPNeuralNetwork(int in_num,int hidden_num,int out_num,string param_file =""); //初始化
	void Train(int num,  double data[][1024],  int labels[][4]); // 得到的结果保存到txt中,再次新建的时候直接读参数
	void Predict(double *data, double* result); //预测
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
	//如果有训练好的参数，直接用;如果没有就用随机值
	if (infile.is_open()) {

		for (auto& ele : input_layer) {
			//到隐层的权值数目
			ele.v.resize(hidden_nodes);
			//【param 1:当前输入神经元到隐层的权值】
			//共 in_nodes * hidden_nodes 个
			for (auto& e : ele.v) {
				infile >> e;  
			}
		}

		for (auto& ele : hidden_layer) {
			//【param 2:隐层阈值】
			//共 hidden_nodes 个
			infile >> ele.gamma;
			//到输出层的权值数目
			ele.w.resize(out_nodes);
			//【param 3:当前隐层神经元到输出层的权值】
			//共 hidden_nodes * out_nodes 个
			for (auto &e : ele.w) {
				infile >> e;
			}
		}

	}
	//没有现成的参数，那就随机初始化
	else {
		for (auto& ele : input_layer) {
			//到隐层的权值数目
			ele.v.resize(hidden_nodes);
			//【param 1:当前输入神经元到隐层的权值】
			//共 in_nodes * hidden_nodes 个
			for (auto& e : ele.v) {
				e = Random();
			}
		}

		for (auto& ele : hidden_layer) {
			//【param 2:隐层阈值】
			//共 hidden_nodes 个
			ele.gamma = Random();
			//到输出层的权值数目
			ele.w.resize(out_nodes);
			//【param 3:当前隐层神经元到输出层的权值】
			//共 hidden_nodes * out_nodes 个
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
	//最多迭代3k次
	while ( cnt < 3) {
		//每一行是一个样本,len是样本总数
		cout << cnt << endl;
		for (int i = 0; i < num; ++i) {
			
			//<-----------------------计算当前样本输出------------------------->
			//在输出层存入正确数据
			for (int l = 0; l < out_nodes; ++l) {
				output_layer[l].right = labels[i][l];
			}

			//初始化隐层
			for (int q = 0; q < hidden_nodes; ++q) {
				hidden_layer[q].value = 0;
			}
			//初始化输出层
			for (int l = 0; l < out_nodes; ++l) {
				output_layer[l].value = 0;
			}

			//数据->输入层->隐层
			for (int d = 0; d < in_nodes; ++d) {
				//数据 ->输入层
				input_layer[d].value = data[i][d];  //向量的一个值对应一个输入神经元
													//输入层 -> 隐层
				for (int q = 0; q < hidden_nodes; ++q) {
					//      隐层的值       +=    输入->隐层的权值  *    输入层的值
					hidden_layer[q].value += input_layer[d].v[q] * input_layer[d].value;
				}
			}

			//计算隐层的输出
			for (int q = 0; q < hidden_nodes; ++q) {
				//   隐层输出     =   sigmoid (      隐层的值      -   阈值              )
				hidden_layer[q].b = Sigmoid(hidden_layer[q].value - hidden_layer[q].gamma);
			}

			//隐层->输出层
			for (int q = 0; q < hidden_nodes; ++q) {
				for (int l = 0; l < out_nodes; ++l) {
					//    输出层的值       +=   隐层->输出层的权值  *    隐层的值
					output_layer[l].value += hidden_layer[q].w[l] * hidden_layer[q].b;
				}
			}

			//计算输出层的输出
			for (int l = 0; l < out_nodes; ++l) {
				//   输出层输出    =   sigmoid (      输出层的值    -   阈值              )
				output_layer[l].y = Sigmoid(output_layer[l].value - output_layer[l].theta);
			}

			//<-----------------------计算两个中间变量------------------------->
			//计算g值
			double y, y_;
			for (int l = 0; l < out_nodes; ++l) {
				y = output_layer[l].right;
				y_ = output_layer[l].y;
				output_layer[l].g = y_*(1 - y_)*(y - y_);
			}

			double tmp;
			//计算e值
			for (int q = 0; q < hidden_nodes; ++q) {
				tmp = 0;
				for (int l = 0; l < out_nodes; ++l) {
					tmp += hidden_layer[q].w[l] * output_layer[l].g;
				}
				hidden_layer[q].e = hidden_layer[q].b * (1 - hidden_layer[q].b) * tmp;
			}

			//<-----------------------更新参数（w,v,theta,gamma)------------------------->

			//更新 w  (隐层 -> 输出层 的权值)
			for (int q = 0; q < hidden_nodes; ++q) {
				for (int l = 0; l < out_nodes; ++l) {
					//更新值 =  学习速率 * g * 隐层输出值
					delta1 = yita*output_layer[l].g*hidden_layer[q].b;
					hidden_layer[q].w[l] += delta1;
				}
			}

			//更新 theta (输出层阈值)
			for (int l = 0; l < out_nodes; ++l) {
				//更新值 = - 学习速率 * g 
				delta2 = -yita*output_layer[l].g;
				output_layer[l].theta += delta2;
			}

			//更新 v (输入 -> 隐层 的权值)
			for (int d = 0; d < in_nodes; ++d) {
				for (int q = 0; q < hidden_nodes; ++q) {
					//更新值 =  学习速率 * e * 输出值
					delta3 = yita*hidden_layer[q].e*input_layer[d].value;
					input_layer[d].v[q] += delta3;
				}
			}

			//更新 gamma (隐层阈值)
			for (int q = 0; q < hidden_nodes; ++q) {
				//更新值 = - 学习速率 * e 
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
	cout << "错误率为:" << (double)cnt / num << endl;
}


void BPNeuralNetwork::Predict(double *data,double* result) {
	//<-----------------------计算当前样本输出------------------------->
	
	//初始化隐层
	for (int q = 0; q < hidden_nodes; ++q) {
		hidden_layer[q].value = 0;
	}
	//初始化输出层
	for (int l = 0; l < out_nodes; ++l) {
		output_layer[l].value = 0;
	}

	//数据->输入层->隐层
	for (int d = 0; d < in_nodes; ++d) {
		//数据 ->输入层
		input_layer[d].value = data[d];  //向量的一个值对应一个输入神经元
											//输入层 -> 隐层
		for (int q = 0; q < hidden_nodes; ++q) {
			//      隐层的值       +=    输入->隐层的权值  *    输入层的值
			hidden_layer[q].value += input_layer[d].v[q] * input_layer[d].value;
		}
	}

	//计算隐层的输出
	for (int q = 0; q < hidden_nodes; ++q) {
		//   隐层输出     =   sigmoid (      隐层的值      -   阈值              )
		hidden_layer[q].b = Sigmoid(hidden_layer[q].value - hidden_layer[q].gamma);
	}

	//隐层->输出层
	for (int q = 0; q < hidden_nodes; ++q) {
		for (int l = 0; l < out_nodes; ++l) {
			//    输出层的值       +=   隐层->输出层的权值  *    隐层的值
			output_layer[l].value += hidden_layer[q].w[l] * hidden_layer[q].b;
		}
	}

	//计算输出层的输出
	for (int l = 0; l < out_nodes; ++l) {
		//   输出层输出    =   sigmoid (      输出层的值    -   阈值              )
		output_layer[l].y = Sigmoid(output_layer[l].value - output_layer[l].theta);
		result[l] = output_layer[l].y;
	}


}

#if Option
//MATLAB调用格式：
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