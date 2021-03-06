function MPS = sweep_right(MPS, N, d, g, J, tau, pbc)


for ii = 1: N-1
    
    %% Hamiltonian 
        
    if ii ==1
        g_prime = g*(1-pbc);
    else
        g_prime = 0;
    end
    
    H = Ising_Hamiltonian(J, g, g_prime); 
    
    exp_operator = expm(-tau*H);
    
    %% Sweep
    
        A = MPS{ii};
        B = MPS{ii+1};
        C = exp_operator;
    
    % Dimensions of the tensors
    d1 = size(A, 2);
    d2 = size(A, 3); % = size(B, 2)
    d3 = size(B, 3);
    [~, min_AB] = min([d2 d3]);
        
    % Contraction of the two sites
    AB = ncon({A, B}, {[-1 -3 1], [-2 1 -4]}, 1);
    
    AB_r = reshape(AB, d^2, size(AB, 3), size(AB, 4)); % The first number is the leg you want to contract with H

    % Contraction with Hamiltonian
    D = ncon({AB_r, C},{[1 -2 -3], [1 -1]}, 1);
    
    D_r = reshape(D, d, d, size(D, 2), size(D, 3));
    D_r = permute(D_r, [1, 3, 2, 4]);
    D_r = reshape(D_r, d*size(D, 2), d*size(D, 3));
    
    % SVD
    [u, s, v] = svd(D_r);
    v = v';   
    s = s/norm(s(:)); % normalizing lambda
    
    u = reshape(u, d, size(u, 1)/d, size(u, 2));
    u = u(:, :, 1:d2);
    
    v = reshape(v, size(v, 1), d, size(v, 2)/d);
    v = permute(v, [2, 1, 3]);
    
    % Truncation
    s = s(1:d2, 1:d2);
    v = v(:, 1:d2, :);
    
    % Contraction for normalization
    new_v = ncon({s, v}, {[-2 1], [-1 1 -3]}, 1);
    
    % Updating results
    if ii < N
        MPS{ii} = u;
        MPS{ii+1} = new_v;
    else
        MPS{ii} = u;
    end
    
end