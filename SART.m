%% Author: Rodrigo de Barros Vimieiro
% Date: May, 2018
% rodrigo.vimieiro@gmail.com
% =========================================================================
%{
---------------------------------------------------------------------------
                SART(proj,nIter,parameter,showinfo)
---------------------------------------------------------------------------
    DESCRIPTION:
    This function reconstruct iteratively the volume through 
    Simultaneous Algebraic Reconstruction Technique (SART) method.
    
    The geometry is for DBT with half cone-beam. All parameters are set in 
    "ParameterSettings" code. 
 
    INPUT:

    - proj  = 2D projection images 
    - nIter = Specific iterations to save volume data 
    - parameter = Parameter of all geometry
    - showinfo = Show information on Command Window

    OUTPUT:

    - allreconData3d = Cell with Volumes of each specific iteration.
    - allIterTime = time of all iterations

    Reference: Three-Dimensional Digital Tomosynthesis - Yulia Levakhina (2014)

    -----------------------------------------------------------------------
    Copyright (C) <2018>  <Rodrigo de Barros Vimieiro>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
% =========================================================================
%% Recon Code -  Iterative reconstruction: SART
function [allreconData3d,allIterTime] = SART(proj,nIter,parameter,showinfo)

highestValue = (2^parameter.bitDepth) - 1;

allIterTime = zeros(nIter(end),1);   % Time data for each iteration
allreconData3d = cell(1,size(nIter,2)); % Recon data for each iteration

% Initial estimated data 
reconData3d = zeros(parameter.ny, parameter.nx, parameter.nz,'single');

% Pre calculation of Projection normalization
proj_norm = projection(ones(parameter.ny, parameter.nx, parameter.nz, 'single'),parameter,0);

% Pre calculation of Backprojection normalization
vol_norm = backprojection(ones(parameter.nv, parameter.nu, parameter.nProj, 'single'), parameter);

if(showinfo)
    fprintf('Starting SART Iterations... \n\n')
end

% Start Iterations
for iter = 1:nIter(end)
    tStart = tic;
    
    proj_diff = projection(reconData3d,parameter,0) - proj; % Error between raw data and projection of estimated data  
    
    proj_diff = proj_diff ./ proj_norm; % Projection normalization
    proj_diff(isnan(proj_diff)) = 0;
    proj_diff(isinf(proj_diff)) = 0;
    
    upt_term = backprojection(proj_diff, parameter);
    upt_term = upt_term ./ vol_norm; % Volume normalization
    upt_term(isnan(upt_term)) = 0;
    upt_term(isinf(upt_term)) = 0;

    reconData3d = reconData3d - upt_term; % Updates the previous estimation 
    
    allIterTime(iter,1) = toc(tStart);
    
    % Truncate to highest value
    reconData3d(reconData3d>highestValue) = highestValue;
    
    % Save data 
    indIter = find(nIter == iter);
    if(indIter~=0)
        allreconData3d{1,indIter} = reconData3d;
    end
    
    if(showinfo) 
        fprintf('Itaration %d Time: %.2f\n\n',iter,toc(tStart));  
    end
    
end
end