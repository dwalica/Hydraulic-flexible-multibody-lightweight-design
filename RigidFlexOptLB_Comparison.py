#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Original code (https://github.com/qkhadim22/Exudyn-hydraulically-actuated-industrial-systems) authored by Qasim Khadim and Johannes Gerstmayr
# This version of code was adjusted for the purpose of the study Effect of Lightweight Design on Structural Dynamics and Energy Efficiency in Hydraulically Actuated Flexible Systems
# Author of edited version: Dominik Walica
# Date: 31. 10. 2025
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

from Models.Container import *

Patu            = False
timeStep        = 5e-3                  #Simulation time step: Change it as desired.
T               = 16                   #Time period
ns              = int(T/timeStep)       
angleInit1      = np.deg2rad(14.6)      #LiftBoom anglee              
angleInit2      = np.deg2rad(-58.8)     #TiltBoom angle 
LiftLoad        = 200                  #469.1387
Plotting        = True
loadFromSavedNPY= False

#in this section we create or load data
if  Patu:
    dataFile1        = 'solution/TwoArms/'+str(T) + '-' + 's' + str(ns) + 'Steps' + str(LiftLoad)+'Load'
else:
    
    dataFile1        = 'solution/OneArm/'+str(T) + '-Default' + 's' + str(ns) + 'Steps' + str(LiftLoad)+'Load'
    dataFile2        = 'solution/OneArm/'+str(T) + '-Optimised' + 's' + str(ns) + 'Steps' + str(LiftLoad)+'Load'

    
model_rigid       = NNHydraulics(nStepsTotal=ns, endTime=T,  mL    = LiftLoad,Flexible=False, 
                           nModes=30, loadFromSavedNPY=loadFromSavedNPY, system=Patu, verboseMode=1)
model_flexible       = NNHydraulics(nStepsTotal=ns, endTime=T,  mL    = LiftLoad,Flexible=True, 
                           nModes=30, loadFromSavedNPY=loadFromSavedNPY, system=Patu, verboseMode=1)

inputVec_rigid    = model_rigid.CreateInputVector( ns,  angleInit1,angleInit2,system=Patu)
inputVec_flexible   = model_flexible.CreateInputVector( ns,  angleInit1,angleInit2,system=Patu)

data1 = model_rigid.ComputeModel(inputVec_rigid,system=Patu,  solutionViewer = True, OptimisedLB = True) #solutionViewer: for visualization
data2 = model_flexible.ComputeModel(inputVec_flexible,system=Patu,  solutionViewer = True, OptimisedLB = True) #solutionViewer: for visualization
    
data_array1 = np.array(data1, dtype=object)
data_array2 = np.array(data2, dtype=object)

np.save(dataFile1, data_array1)
np.save(dataFile2, data_array2)
    
model_flexible.PlottingLB_OptRigidFlexComparison(data_array1,data_array2)   
         
