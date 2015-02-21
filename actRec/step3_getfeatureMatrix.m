% ����weightMatrix�õ�featureMatrix

% param setting
track_length = 15;
track_num = 200;
size_origin = 32;
size_new = 16;

iterMax = 50;
numFeatures = 225;    % number of features to learn
batchNumPatches = 2000; %�ֳ�10��batch
patches_num = track_length*track_num; % 15*200=3000

isTopo = 0;
iterMax = 50;
numPatches = patches_ext_num*sample_total;   % number of patches
patchDim = 16;         % patch dimension
visibleSize = patchDim * patchDim; %��ͨ���Ҷ�ͼ��256ά��ѧϰ225������

lambda = 5e-5;  % L1-regularisation parameter (on features)
epsilon = 1e-5; % L1-regularisation epsilon |x| ~ sqrt(x^2 + epsilon)
gamma = 1e-2;   % L2-regularisation parameter (on basis)

% for sp
isTopo = 0;
% Initialize options for minFunc
%options.Method = 'lbfgs';
options.Method = 'cg';
options.display = 'off';
options.verbose = 0;
options.maxIter = 20;

poolDim = 3;


addpath('D:\\myproject\\data\\dataoriginrand200');
feaorigin = load('person01_boxing_d1_origin.txt');

patches_origin = zeros(size_new*size_new,patches_num);
pcnt = 0;
for pidx=1:patches_num %1:3000
    pcnt = pcnt+1;
    fixed_id = pidx-1;
    fixed_r = floor(fixed_id/track_length)+1;
    fixed_c = mod(fixed_id,track_length)+1;
    
    patch_row = feaorigin(fixed_r,:);
    patch_one = patch_row([size_origin*size_origin*(fixed_c-1)+1:size_origin*size_origin*fixed_c]);
    patch_one = reshape(patch_one,size_origin,size_origin); %����Ϊ32*32�ľ���
    patch_one = patch_one'; % ת�ã�����ҲҪ��Ӧ����һ��
    patch_one = imresize(patch_one,[size_new size_new]); % ���µ�����С
    patch_one = reshape(patch_one,1,size_new*size_new); %���µ���Ϊһ��
    
    patches_origin(:,pcnt) = patch_one'; %����Ϊ�в���ֵ���������
end;

% ZCA
patches_origin_normal = normalizeData(patches_origin);
figure(1);  display_network(patches_origin_normal);

x = patches_origin_normal;
x = x-repmat(mean(x,1),size(x,1),1); %��ÿһ�еľ�ֵ
% Implement PCA to obtain xRot
xRot = zeros(size(x)); % You need to compute this
[n m] = size(x);
sigma = (1.0/m)*x*x';
[u s v] = svd(sigma);
xRot = u'*x;

% Check your implementation of PCA
covar = zeros(size(x, 1)); % You need to compute this
covar = (1./m)*xRot*xRot';

% Visualise the covariance matrix. You should see a line across the
% diagonal against a blue background.
figure('name','Visualisation of covariance matrix');
imagesc(covar);

% Step 2: Find k, the number of components to retain
%  Write code to determine k, the number of components to retain in order
%  to retain at least 99% of the variance.

k = 0; % Set k accordingly
ss = diag(s);
% for k=1:m
%    if sum(s(1:k))./sum(ss) < 0.99
%        continue;
% end
% ����cumsum(ss)�������һ���ۻ�������Ҳ����˵ss����ֵ���ۼ�ֵ
% ����(cumsum(ss)/sum(ss))<=0.99��һ��������ֵΪ0����1��������Ϊ1��ʾ�����Ǹ�����
k = length(ss((cumsum(ss)/sum(ss))<=0.99));

% Step 3: Implement PCA with dimension reduction
xHat = zeros(size(x));  % You need to compute this
xHat = u*[u(:,1:k)'*x;zeros(n-k,m)];

% Visualise the data, and compare it to the raw data
% You should observe that the raw and processed data are of comparable quality.
% For comparison, you may wish to generate a PCA reduced image which
% retains only 90% of the variance.

figure('name',['PCA processed images ',sprintf('(%d / %d dimensions)', k, size(x, 1)),'']);
display_network(xHat);
figure('name','Raw images');
display_network(x);

% Step 4a: Implement PCA with whitening and regularisation
%  Implement PCA with whitening and regularisation to produce the matrix
%  xPCAWhite. 

epsilon = 0.1;
xPCAWhite = zeros(size(x));
xPCAWhite = diag(1./sqrt(diag(s)+epsilon))*u'*x;
figure('name','PCA whitened images');
display_network(xPCAWhite);

% Step 4b: Check your implementation of PCA whitening 
covar = (1./m)*xPCAWhite*xPCAWhite';

% Visualise the covariance matrix. You should see a red line across the
% diagonal against a blue background.
figure('name','Visualisation of covariance matrix');
imagesc(covar);

% Step 5: Implement ZCA whitening
%  Now implement ZCA whitening to produce the matrix xZCAWhite. 
%  Visualise the data and compare it to the raw data. You should observe
%  that whitening results in, among other things, enhanced edges.
xZCAWhite = zeros(size(x));
xZCAWhite = u*xPCAWhite;

% Visualise the data, and compare it to the raw data.
% You should observe that the whitened images have enhanced edges.
figure('name','ZCA whitened images');
display_network(xZCAWhite(:,[1:100]));
figure('name','Raw images');
display_network(x);

%% get featureMatrix
% xZCAWhite
groupMatrix = zeros(numFeatures, donutDim, donutDim); % 225*15*15
groupNum = 1;
for row = 1:donutDim
    for col = 1:donutDim 
        groupMatrix(groupNum, 1:poolDim, 1:poolDim) = 1; % poolDim=3
        groupNum = groupNum + 1;
        groupMatrix = circshift(groupMatrix, [0 0 -1]);
    end
    groupMatrix = circshift(groupMatrix, [0 -1, 0]);
end
groupMatrix = reshape(groupMatrix, numFeatures, numFeatures);%121*121

% if isequal(questdlg('Initialize grouping matrix for topographic or non-topographic sparse coding?', 'Topographic/non-topographic?', 'Non-topographic', 'Topographic', 'Non-topographic'), 'Non-topographic')
%     groupMatrix = eye(numFeatures); %�����˽ṹʱ��groupMatrix����
% end
if(0 == isTopo)
    groupMatrix = eye(numFeatures); % �����˽ṹʱ��groupMatrix����
end;


batchPatches = xZCAWhite;
% ����weightMatrix
loadpath = sprintf('data\\weightMatrix_NF%d_BN%d_iter%d.mat',numFeatures,batchNumPatches,iterMax);
weightMatrix = load(loadpath);
weightMatrix = weightMatrix.weightMatrix;

% ��featureMatrix���³�ʼ����������ҳ�̳��Ͻ��ܵķ�������
featureMatrix = weightMatrix' * batchPatches;
normWM = sum(weightMatrix .^ 2)';
featureMatrix = bsxfun(@rdivide, featureMatrix, normWM); 

% Optimize for feature matrix    
%����Ȩֵ��ʼֵ���Ż�����ֵ����
[featureMatrix, cost] = minFunc( @(x) sparseCodingFeatureCost(weightMatrix, x, visibleSize, numFeatures, batchPatches, gamma, lambda, epsilon, groupMatrix), ...
                                       featureMatrix(:), options);
featureMatrix = reshape(featureMatrix, numFeatures, patches_num);  
savepath = sprintf('data\\featureMatrix_NF%d_BN%d_iter%d.mat',numFeatures,batchNumPatches,iterMax);
save(savepath,'featureMatrix');


%% ���гػ���ά
% featureMatrix 225*3000
% ÿ������15��patches��һ��200������
% �ػ�֮��õ�225�У�200�е���������
% ����ÿ��15������һ��
% track_length = 15;
% track_num = 200;


pool_sum=zeros(numFeatures,track_num);
pool_max=-1*ones(numFeatures,track_num);
pool_tmp = zeros(numFeatures,track_length);
for track_id = 1:track_num % 1:200
    pool_tmp = featureMatrix(:,[track_length*(track_id-1)+1:track_length*track_id]);
    pool_sum(:,track_id) = sum(pool_tmp,2)./track_length;
    for col = 1:track_length %1:15
        pool_one = pool_tmp(:,col);
        for feaid = 1:numFeatures
            if pool_one(feaid) > pool_max(feaid,track_id)
                pool_max(feaid,track_id) = pool_one(feaid);
            end;
        end;
    end;   
end;

figure(1);  display_network(pool_max);
figure(2);  display_network(pool_sum);

save pool_max pool_max
save pool_sum pool_sum


