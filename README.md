# 聲學模型nnet3訓練

### 走
#### CPU server
```
time docker build --build-arg KUI=200 --build-arg CPU_CORE=32 .
```
#### GPU server
```
# time docker run --runtime=nvidia --name nnet3-twisas-tw12-8k nnet3:twisas-tw12 
time docker run --runtime=nvidia --name nnet3-205 dockerhub.iis.sinica.edu.tw/nnet3:205
```
