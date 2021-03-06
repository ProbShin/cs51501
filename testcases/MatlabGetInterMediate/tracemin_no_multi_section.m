function [EigY, Thi] = tracemin_no_multi_section(A, B, k)
%% basic trace minimization alg.
% Alg 11.13 of book "Parallelism in Matrix Computations"
% 
% April 12th 2016 Project 3 of CS51501
%
% L1: Choose a block size s>=p and an n*s matrix V of full rank such that V'BV = I
% L2: do k=1,2,...until convergence
% L3:     Compute W=AK and the interaction matrix H=V'W
% L4:     Compute the eigenpaires (Y, Thi) of H. (Thi should be arranged asceding order, Y be orthogonal)
% L5:     Compute the corresponding Ritz vector X = V*Y   
% L6:     Compute the residuals R = WY - BXThi =(AX-BXThi)
% L7:     Test for convergence
% L8:     Solve the positive-semidefinite linear system(11.66) approximately via the CG scheme
% L9:     B-orthonormalize X-=delt 
%============================================================
%
% input:  A, B, k, ui, uj
% output: Thi, Y
% 
% A, B : n x n sparse mtx 
% k    : no. of eigenvalues we want (block size) (default s = 2k)
% ui,uj: region [ui,uj]             (used to form new A-=0.5*(ui+uj)*B)
% Thi  : s x s diag mtx             (eigenvalues  of H) (ascending order)
% Y    : s x s sparse? mtx          (eigenvectors of H)
% 
%===============================================================


if nargin~=3
    disp('       [Thi, Y] = tracemin_body(A, B, k)');
    return
end
disp('TraceMin body without region')

s = 2*k;
[n,n] = size(A);
THRESHOLD = 1e-6;           %threshold 
Z = zeros(n, s);
for i = 1:n
    Z(i,mod(i-1,s)+1) = 1.0;
end
cnt=1
while 1 && cnt<=2
  [Q,Sigma] = eig(Z'*B*Z);
  V = Z*Q/sqrt(Sigma);
  W=A*V;                     
  H=V'*W;                    
  [EigY,Thi] = eig(H);
  [S, idx] = sort(diag(Thi)); 
    fname = sprintf('Sig_step%d.mtx',cnt)
    mmwrite(fname, S);
  Thi = diag(S);
  EigY = EigY(:,idx);
    fname = sprintf('EigVec_step%d.mtx',cnt)
    mmwrite(fname, EigY);  
  Y=V*EigY;
    fname =sprintf('Y_step%d.mtx',cnt);
    mmwrite(fname, Y);  
    fname =sprintf('BY_step%d.mtx',cnt);
    mmwrite(fname, B*Y);  
    fname = sprintf('AY_step%d.mtx',cnt);
    mmwrite(fname, A*Y);  
  R=W*EigY-B*Y*Thi;  
    fname = sprintf('R_step%d.mtx',cnt);
    mmwrite(fname,  R);  
  bStop = 1;
  for col = 1 : k
    if norm(R(:,col),2) > Thi(col,col)*THRESHOLD 
        bStop=0; break;        %if any column does not meet threshold, then continue
    end
  end
  if bStop == 1
    break;  % break the while loop
  end
  Delta = mCG_solver(A,B,Y, Thi, cnt);    %Thi is used to determin step m within CG. refered from the 1982 PAPER         
  fname = sprintf('Dlt_step%d.mtx',cnt);
  mmwrite(fname, Delta);  

  Z = Y - Delta;    %
  cnt=cnt+1;
end 

Y = Y(:,1:k);           % only keep the k smallest eigenvectors
Thi = Thi(1:k,1:k);     % only keep the k smallest eigenvalues

end %end of function
