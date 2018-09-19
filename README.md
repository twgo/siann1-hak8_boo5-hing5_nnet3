# 聲學模型nnet3訓練

### 走
```
time docker build --build-arg KUI=200 --build-arg CPU_CORE=32 .
```
```
time docker run --runtime=nvidia --name nnet3-twisas-tw12-8k nnet3:twisas-tw12 
```
