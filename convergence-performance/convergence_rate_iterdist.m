
clearvars; clc;
%% Basic setting
n = 1000;       %%%  n = the number of nodes
K = 2;             %%% K = the number of blocks
m = n/K;        %%% m = the block size

%% ground truth 
Xt =  kron(eye(K), ones(m)); 
Xt(Xt==0)=-1;                                    %%% Xt = the true cluster matrix
xt = [ones(m,1); -ones(m,1)];           %%%  xt = the true cluster vector

%% generate an adjacency matrix A by Binary SBM
a = 10; b = 2;        %%%  choose the constants alpha, beta in p, q, resp.
p = a*log(n)/n;     %%%  p = the within-cluster connecting probability; 
q=b*log(n)/n;       %%%  q = the across-cluster connecting probability.       
Ans11 = rand(m); Al11 = tril(Ans11,-1); 
As11 = Al11 + Al11'+diag(diag(Ans11)); clear Ans11 Al11
A11 = double(As11<=p); A11 = sparse(A11); clear As11
As12 = rand(m);
A12 = double(As12<=q); A12 = sparse(A12); clear As12
Ans22 = rand(m); Al22 = tril(Ans22,-1); 
As22 = Al22 + Al22' + diag(diag(Ans22)); clear Ans22 Al22
A22 = double(As22<=p); A22 = sparse(A22); clear As22
A = ([A11,A12;A12',A22]); clear A11 A12 A22
A = sparse(A);

%% choose the running algorithm
run_GPM = 1; %%% 1 = run GPM; 0 = don't run GPM;
run_MGD = 1;  %%% 1 = run MGD; 0 = don't run MGD;

%% total running time
[ttime_GPM, ttime_MGD] = deal(0);

for repeat = 1:1 %%%% 
            %% initial point generated by uniform distribution over the sphere
            x0 = randn(n,1); x0 = x0/norm(x0);
            
            %% PI + GPM for Regularized MLE
             if run_GPM == 1
                        rho = sum(sum(A))/n^2; %%% compute regularizer rho
                        opts = struct('rho', rho, 'T', 1e3, 'tol', 1e-4, 'report_interval', 1, 'total_time', 1000); %%% choose the parameters in GPM
                        tic; [x_GPM, iter_GPM, val_collector_GPM, itergap_GPM] = GPM(A, x0, xt, opts); time_GPM=toc; 
                        ttime_GPM = ttime_GPM + time_GPM;
                        dist_GPM = norm(x_GPM*x_GPM'-Xt, 'fro');
            end
                       
            %% Manifold Gradient Descent
            if run_MGD == 1
                        rho = (p+q)/2;
                        opts = struct('rho', rho, 'T', 1e3, 'tol', 1e-4,'report_interval', 10, 'total_time', 1000);
                        Q = randn(n,2); Q = normr(Q);                    
                        tic; [Q, iter_MGD, val_collector_MGD, itergap_MGD] = manifold_GD(A, Q, xt, opts); time_MGD=toc;
                        ttime_MGD = ttime_MGD + time_MGD;
                        dist_MGD =  norm(Q*Q'-Xt, 'fro');
            end
            
end 

%% plot convergence performance

if run_GPM == 1
     n1 = size(itergap_GPM, 2); 
     semilogy(itergap_GPM(1:n1-1)+1e-8, '-o', 'LineWidth', 2, 'MarkerSize', 6); hold on;
end

if run_MGD == 1
    n1 = size(itergap_MGD, 2); 
    semilogy(itergap_MGD(1:n1-1)+1e-8, '-*', 'LineWidth', 2, 'MarkerSize', 6); hold on;
end

xlim([0, round(iter_MGD*1.2)]); 

if n == 1000
    ylim([1e-8, 1e4]); title('n=1000, \alpha=10, \beta=2'); 
elseif n == 5000
    ylim([1e-8, 1e5]); title('n=5000, \alpha=10, \beta=2');
else
    ylim([1e-8, 1e5]); title('n=10000, \alpha=10, \beta=2');
end

legend('GPM', 'MGD'); xlabel('Iter num'); ylabel('distance to ground truth');


