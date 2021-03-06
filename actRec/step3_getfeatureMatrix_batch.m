% 根据weightMatrix得到featureMatrix（batch）
% param setting
track_length = 15;
track_num = 200;
size_origin = 32;
size_new = 16;

iterMax = 50;
numFeatures = 225;    % number of features to learn
batchNumPatches = 2000; %分成10个batch
patches_num = track_length*track_num; % 15*200=3000

isTopo = 0;
patchDim = 16;         % patch dimension
visibleSize = patchDim * patchDim; %单通道灰度图，256维，学习225个特征

% for sp
poolDim = 3;
lambda = 5e-5;  % L1-regularisation parameter (on features)
epsilon = 1e-5; % L1-regularisation epsilon |x| ~ sqrt(x^2 + epsilon)
gamma = 1e-2;   % L2-regularisation parameter (on basis)

% Initialize options for minFunc
%options.Method = 'lbfgs';
options.Method = 'cg';
options.display = 'off';
options.verbose = 0;
options.maxIter = 20;

% 加载weightMatrix
loadpath = sprintf('data\\weightMatrix_NF%d_BN%d_iter%d.mat',numFeatures,batchNumPatches,iterMax);
weightMatrix = load(loadpath);
weightMatrix = weightMatrix.weightMatrix;

% for batch
sample_class_num = 6;
dnum = 4;
sample_num = 25;
sample_total = sample_num*dnum*sample_class_num;
act_name = {'boxing','handclapping','handwaving','jogging','running','walking'};

% for test
sample_class_num = 3;
dnum = 1;
sample_num = 2;
sample_total = sample_num*dnum*sample_class_num;

pool_max_batch = zeros(numFeatures,track_num*sample_total); % 225 200*600
pool_mean_batch = zeros(numFeatures,track_num*sample_total); % 225 200*600
addpath('D:\\myproject\\data\\dataoriginrand200');

spcnt = 0;
for acti = 1:sample_class_num %1:6
    for peri = 1:sample_num % 1:25
        shi = floor(peri/10);
        ge = mod(peri,10);
        for di = 1:dnum % 1:4
            spcnt = spcnt+1;
            path = sprintf('person%d%d_%s_d%d_origin.txt',shi,ge,act_name{acti},di);
            disp(path);
            feaorigin = load(path);
            
            % resize
            patches_origin = zeros(size_new*size_new,patches_num);
            pcnt = 0;
            for pidx=1:patches_num %1:3000
                pcnt = pcnt+1;
                fixed_id = pidx-1;
                fixed_r = floor(fixed_id/track_length)+1;
                fixed_c = mod(fixed_id,track_length)+1;

                patch_row = feaorigin(fixed_r,:);
                patch_one = patch_row([size_origin*size_origin*(fixed_c-1)+1:size_origin*size_origin*fixed_c]);
                patch_one = reshape(patch_one,size_origin,size_origin); %调整为32*32的矩阵
                patch_one = patch_one'; % 转置，后面也要对应保持一致
                patch_one = imresize(patch_one,[size_new size_new]); % 重新调整大小
                patch_one = reshape(patch_one,1,size_new*size_new); %重新调整为一行

                patches_origin(:,pcnt) = patch_one'; %调整为列并赋值给大的数组
            end;
            
            % ZCA
            x = normalizeData(patches_origin);
            x = x-repmat(mean(x,1),size(x,1),1); %求每一列的均值
            % Implement PCA to obtain xRot
            xRot = zeros(size(x)); % You need to compute this
            [n m] = size(x);
            sigma = (1.0/m)*x*x';
            [u s v] = svd(sigma);
            xRot = u'*x;
            % Step 2: Find k
            k = 0; % Set k accordingly
            ss = diag(s);
            k = length(ss((cumsum(ss)/sum(ss))<=0.99));
            % Step 3: Implement PCA with dimension reduction
            xHat = zeros(size(x));  % You need to compute this
            xHat = u*[u(:,1:k)'*x;zeros(n-k,m)];
            % Step 4: Implement PCA with whitening and regularisation
            epsilon = 0.1;
            xPCAWhite = zeros(size(x));
            xPCAWhite = diag(1./sqrt(diag(s)+epsilon))*u'*x;
            % Step 5: Implement ZCA whitening
            xZCAWhite = zeros(size(x));
            xZCAWhite = u*xPCAWhite;
            
            % get featureMatrix
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
            %     groupMatrix = eye(numFeatures); %非拓扑结构时的groupMatrix矩阵
            % end
            if(0 == isTopo)
                groupMatrix = eye(numFeatures); % 非拓扑结构时的groupMatrix矩阵
            end;
            
            % 初始化featureMatrix
            batchPatches = xZCAWhite;
            featureMatrix = weightMatrix' * batchPatches;
            normWM = sum(weightMatrix .^ 2)';
            featureMatrix = bsxfun(@rdivide, featureMatrix, normWM); 
            % Optimize for feature matrix    
            [featureMatrix, cost] = minFunc( @(x) sparseCodingFeatureCost(weightMatrix, x, visibleSize, numFeatures, batchPatches, gamma, lambda, epsilon, groupMatrix), ...
                                                   featureMatrix(:), options);
            featureMatrix = reshape(featureMatrix, numFeatures, patches_num);  
            
            % 池化降维 featureMatrix 225*3000
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
            
            % 放到大的数组中 pool_max_batch pool_mean_batch
            pool_max_batch(:,[track_num*(spcnt-1)+1:track_num*spcnt]) = pool_max;
            pool_mean_batch(:,[track_num*(spcnt-1)+1:track_num*spcnt]) = pool_sum;
        end;
    end;
end;

savepath = sprintf('data\\pool_max_NF%d_BN%d_iter%d.mat',numFeatures,batchNumPatches,iterMax);
save(savepath,'pool_max_batch');
savepath = sprintf('data\\pool_mean_NF%d_BN%d_iter%d.mat',numFeatures,batchNumPatches,iterMax);
save(savepath,'pool_mean_batch');

