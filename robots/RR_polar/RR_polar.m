%%  RR polar robot dynamics
%   Developed by Giuseppe Sensolini (github: @giusenso)

%{
This script can be adapted to any robot manipulator.
Variables to be adjusted:
    - N (number of joints)
    - sigma vector (0=revolute joint, 1=prismatic joint)
    - r{i} (vector going from the from joint i to i+1 in the world reference frame)
    - gravity vector
    - eventually add other inertial symbolic terms if needed
%}

close all
clear all
clc

%% Symbolic parameters

N   = 2; % number of joints ### ROBOT DATA ###
q   = sym('q',[N,1]); assume(q,'real');    	% joints symbolic variables
l   = sym('l',[N,1]); assume(l,'real');   	% joints symbolic variables
d   = sym('d',[N,1]); assume(d,'real'); % distance of the CoM from the joint axes
dq  = sym('dq',[N,1]); assume(dq,'real');   % first derivative of joint varaibles
ddq = sym('ddq',[N,1]); assume(ddq,'real'); % second derivative of joint varaibles
m   = sym('m',[N,1]); assume(m,'real');     % masses of CoM
u   = sym('u',[N,1]); assume(u,'real');     % external forces
r = cell(1,N);  % vector going from frame i-1 to frame i expressed in frame 0
syms g0 real;

% inertia matrices
I = cell(1,N);
syms I1xx I1xy I1xz I1yx I1yy I1yz I1zx I1zy I1zz
syms I2xx I2xy I2xz I2yx I2yy I2yz I2zx I2zy I2zz
I{1} = [I1xx I1xy I1xz; I1yx I1yy I1yz; I1zx I1zy I1zz];
I{2} = [I2xx I2xy I2xz; I2yx I2yy I2yz; I2zx I2zy I2zz];

%% ROBOT DATA
sigma = [0 0];           % 0 if revolute, 1 if prismatic     
r{1} = [0; l(1); 0];
r{2} = [l(2)*sin(q(1))*cos(q(2)); l(2)*sin(q(2)); l(2)*cos(q(1))*cos(q(2))];
gravity = [0; -g0; 0];

%% MOVING FRAME ALGORITHM
rcm = cell(1,N);
rcm0 = cell(1,N);
w = cell(1,N);
v = cell(1,N);
vcm = cell(1,N);

% iteration 1
rcm{1} = [0; d(1); 0];
rcm0{1} = rcm{1};
w{1} = [0; dq(1); 0];
v{1} = cross(w{1},r{1});
vcm{1} = cross(w{1},rcm{1});

% iteration 2
rcm{2} = [d(2)*sin(q(1))*cos(q(2)); d(2)*sin(q(2)); d(2)*cos(q(1))*cos(q(2))];
rcm0{2} = r{1} + rcm{2};
w{2} = w{1} + [0; 0; dq(2)];
vcm{2} = vcm{1} + cross(w{2},rcm{2});

%% DYNAMICS COMPUTATION
Tcm = kinetic_energy(dq, m, I, vcm, w);
T = sum(Tcm);
M = inertia_matrix(T, q, dq);
[c,christoff,S,X] = centrifugal_coriolis(M, q, dq);
Ucm = potential_energy(m, gravity, rcm0);
U = sum(Ucm);
g = simplify(jacobian(U,q).');


%% Print Dynamics
print_dynamics(sigma, vcm, w, rcm0, Tcm, M, c, christoff, S, Ucm, g)


%