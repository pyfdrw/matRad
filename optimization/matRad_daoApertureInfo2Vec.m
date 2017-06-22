function [apertureInfoVec, mappingMx, limMx] = matRad_daoApertureInfo2Vec(apertureInfo)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matRad function to generate a vector respresentation of the aperture
% weights and shapes and (optional) some meta information needed during
% optimization
%
% call
%   [apertureInfoVec, mappingMx, limMx] = matRad_daoApertureInfo2Vec(apertureInfo)
%
% input
%   apertureInfo:    aperture weight and shape info struct
%
% output
%   apertureInfoVec: vector respresentation of the apertue weights and shapes
%   mappingMx:       mapping of vector components to beams, shapes and leaves
%   limMx:           bounds on vector components, i.e., minimum and maximum
%                    aperture weights (0/inf) and leav positions (custom)
%
% References
%   
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function to create a single vector for the direct aperature optimization
% first: aperature weights
% second: left leaf positions
% third: right leaf positions

% initializing variables

if apertureInfo.VMAT
    apertureInfoVec = NaN * ones(apertureInfo.totalNumOfShapes*2+apertureInfo.totalNumOfLeafPairs*2,1); %Extra set of (apertureInfo.totalNumOfShapes) number of elements, allowing arc sector times to be optimized
    %IandFapertureInfoVec = NaN * ones(apertureInfo.totalNumOfShapes*2+apertureInfo.IandFtotalNumOfLeafPairs*2,1);
else
    apertureInfoVec = NaN * ones(apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs*2,1);
    %IandFapertureInfoVec = NaN * ones(apertureInfo.totalNumOfShapes*2+apertureInfo.totalNumOfLeafPairs*2,1);
end

offset = 0;
%IandFoffset = 0;

%% 1. aperture weights
for i = 1:size(apertureInfo.beam,2)
    for j = 1:apertureInfo.beam(i).numOfShapes
        apertureInfoVec(offset+j) = apertureInfo.beam(i).shape(j).weight;   %In VMAT, this weight is "spread" over unoptimized beams (assume constant dose rate over sector)  
        %IandFapertureInfoVec(offset+j) = apertureInfo.beam(i).shape(j).weight;
    end
    offset = offset + apertureInfo.beam(i).numOfShapes;
    %IandFoffset = IandFoffset + apertureInfo.beam(i).numOfShapes;
end

% 2. left and right leaf positions
%% fill the vector for all shapes of all beams
for i = 1:size(apertureInfo.beam,2)
    for j = 1:apertureInfo.beam(i).numOfShapes
        
        if ~apertureInfo.dynamic
            apertureInfoVec(offset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]) = apertureInfo.beam(i).shape(j).leftLeafPos;
            apertureInfoVec(offset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]+apertureInfo.totalNumOfLeafPairs) = apertureInfo.beam(i).shape(j).rightLeafPos;
            
            offset = offset + apertureInfo.beam(i).numOfActiveLeafPairs;
        end
        
        if apertureInfo.VMAT
            if apertureInfo.dynamic
                %IandFapertureInfoVec(IandFoffset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]) = apertureInfo.beam(i).shape(j).leftLeafPos_I;
                %IandFapertureInfoVec(IandFoffset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]+apertureInfo.totalNumOfLeafPairs) = apertureInfo.beam(i).shape(j).rightLeafPos_I;
                
                %IandFoffset = IandFoffset + apertureInfo.beam(i).numOfActiveLeafPairs;
                
                if apertureInfo.beam(i).doseAngleOpt(1)
                    apertureInfoVec(offset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]) = apertureInfo.beam(i).shape(j).leftLeafPos_I;
                    apertureInfoVec(offset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]+apertureInfo.totalNumOfLeafPairs) = apertureInfo.beam(i).shape(j).rightLeafPos_I;
                    
                    offset = offset + apertureInfo.beam(i).numOfActiveLeafPairs;
                end
                %IandFapertureInfoVec(IandFoffset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]) = apertureInfo.beam(i).shape(j).leftLeafPos_F;
                %IandFapertureInfoVec(IandFoffset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]+apertureInfo.totalNumOfLeafPairs) = apertureInfo.beam(i).shape(j).rightLeafPos_F;
                
                %IandFoffset = IandFoffset + apertureInfo.beam(i).numOfActiveLeafPairs;
                
                if apertureInfo.beam(i).doseAngleOpt(2)
                    apertureInfoVec(offset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]) = apertureInfo.beam(i).shape(j).leftLeafPos_F;
                    apertureInfoVec(offset+[1:apertureInfo.beam(i).numOfActiveLeafPairs]+apertureInfo.totalNumOfLeafPairs) = apertureInfo.beam(i).shape(j).rightLeafPos_F;
                    
                    offset = offset + apertureInfo.beam(i).numOfActiveLeafPairs;
                end
            end
        end
    end
end
%% 3. time of arc sector/beam
if apertureInfo.VMAT
    offset = offset + apertureInfo.totalNumOfLeafPairs;
    %IandFoffset = IandFoffset + apertureInfo.IandFtotalNumOfLeafPairs;
    
    %this gives a vector of the arc lengths belonging to each optimized CP
    %unique gets rid of double-counted angles (which is every interior
    %angle)
    optInd = [apertureInfo.beam.optimizeBeam];
    optAngleLengths = [apertureInfo.beam(optInd).optAngleBordersDiff];
    optGantryRot = [apertureInfo.beam(optInd).gantryRot];
    apertureInfoVec((offset+1):end) = optAngleLengths./optGantryRot; %entries are the times until the next opt gantry angle is reached
    %IandFapertureInfoVec((IandFoffset+1):end) = optAngleLengths./optGantryRot;
    
end

%% 4. create additional information for later use
if nargout > 1
    %FIX MAPPINGMX AND LIMMX
    if apertureInfo.VMAT
        mappingMx =  NaN * ones(apertureInfo.totalNumOfShapes*2+apertureInfo.totalNumOfLeafPairs*2,4);
        limMx     =  NaN * ones(apertureInfo.totalNumOfShapes*2+apertureInfo.totalNumOfLeafPairs*2,2);
    else
        mappingMx =  NaN * ones(apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs*2,4);
        limMx     =  NaN * ones(apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs*2,2);
    end
    
    limMx(1:apertureInfo.totalNumOfShapes,:) = ones(apertureInfo.totalNumOfShapes,1)*[0 inf];
    
    counter = 1;
    for i = 1:numel(apertureInfo.beam)
        for j = 1:apertureInfo.beam(i).numOfShapes
            mappingMx(counter,1) = i;
            if apertureInfo.VMAT
                timeLimL = diff(apertureInfo.beam(i).optAngleBorders)/apertureInfo.gantryRotCst(2); %Minimum time interval between two optimized beams/gantry angles
                timeLimU = diff(apertureInfo.beam(i).optAngleBorders)/apertureInfo.gantryRotCst(1); %Maximum time interval between two optimized beams/gantry angles
                
                mappingMx(counter+apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs*2,1) = i;
                limMx(counter+apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs*2,:) = [timeLimL timeLimU];
            else
                
            end
            counter = counter + 1;
        end
    end
    
    shapeOffset = 0;
    for i = 1:numel(apertureInfo.beam)
        for j = 1:apertureInfo.beam(i).numOfShapes
            for k = 1:apertureInfo.beam(i).numOfActiveLeafPairs
                mappingMx(counter,1) = i;
                mappingMx(counter,2) = j + shapeOffset; % store global shape number for grad calc
                mappingMx(counter,3) = j; % store local shape number
                mappingMx(counter,4) = k; % store local leaf number
                
                limMx(counter,1)     = apertureInfo.beam(i).lim_l(k);
                limMx(counter,2)     = apertureInfo.beam(i).lim_r(k);
                counter = counter + 1;
                
                if apertureInfo.VMAT && apertureInfo.dynamic
                    %redo for initial and final leaf positions
                    %might have to revisit this after looking at gradient,
                    %esp. mappingMx(counter,2)
                    %only an issue for non-interpolated deliveries
                    mappingMx(counter,1) = i;
                    mappingMx(counter,2) = j + shapeOffset; % store global shape number for grad calc
                    mappingMx(counter,3) = j; % store local shape number
                    mappingMx(counter,4) = k; % store local leaf number
                    
                    limMx(counter,1)     = apertureInfo.beam(i).lim_l(k);
                    limMx(counter,2)     = apertureInfo.beam(i).lim_r(k);
                    counter = counter + 1;
                end
            end
        end
        shapeOffset = shapeOffset + apertureInfo.beam(i).numOfShapes;
    end
    
    mappingMx(counter:(apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs*2),:) = mappingMx(apertureInfo.totalNumOfShapes+1:counter-1,:);
    limMx(counter:(apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs*2),:)     = limMx(apertureInfo.totalNumOfShapes+1:counter-1,:);
    
end
