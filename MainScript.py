#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Original code (https://github.com/qkhadim22/Exudyn-hydraulically-actuated-industrial-systems) authored by Qasim Khadim and Johannes Gerstmayr
# This version of code was adjusted for the purpose of the study Effect of Lightweight Design on Structural Dynamics and Energy Efficiency in Hydraulically Actuated Flexible Systems
# Author of edited version: Dominik Walica
# Date: 31. 10. 2025
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

from Models.Container import *

###############################


Patu            = False
timeStep        = 5e-3                  #Simulation time step: Change it as desired.
T               = 16                   #Time period
ns              = int(T/timeStep)       
angleInit1      = np.deg2rad(14.6)      #LiftBoom anglee              
angleInit2      = np.deg2rad(-58.8)     #TiltBoom angle 
LiftLoad        = 200                  
OptimisedLB     = True
Flexible        = True
Plotting        = True
loadFromSavedNPY= True
solutionViewer  = True


if OptimisedLB:
    dataFile1        = 'solution/OneArm/'+str(T) + '-Default' + 's' + str(ns) + 'Steps' + str(LiftLoad)+'Load'
    dataFile2        = 'solution/OneArm/'+str(T) + '-Optimised' + 's' + str(ns) + 'Steps' + str(LiftLoad)+'Load'
else:
    dataFile1        = 'solution/OneArm/'+str(T) + '-' + 's' + str(ns) + 'Steps' + str(LiftLoad)+'Load'
    

model       = NNHydraulics(nStepsTotal=ns, endTime=T,  mL    = LiftLoad,Flexible=Flexible, 
                           nModes=4, loadFromSavedNPY=loadFromSavedNPY, system=Patu, verboseMode=1)

inputVec    = model.CreateInputVector( ns,  angleInit1,angleInit2,system=Patu)

if OptimisedLB:
    
    data1 = model.ComputeModel(inputVec,system=Patu,  solutionViewer = solutionViewer, OptimisedLB = False) #solutionViewer: for visualization
    data2 = model.ComputeModel(inputVec,system=Patu,  solutionViewer = solutionViewer, OptimisedLB = True) #solutionViewer: for visualization
    
    data_array1 = np.array(data1, dtype=object)
    data_array2 = np.array(data2, dtype=object)

    np.save(dataFile1, data_array1)
    np.save(dataFile2, data_array2)
    
    if Plotting:
        model.PlottingLB(data_array1,data_array2)   
         
else:
    data1 = model.ComputeModel(inputVec,system=Patu,  solutionViewer = True, OptimisedLB = False) #solutionViewer: for visualization
    data_array1 = np.array(data1, dtype=object)
    np.save(dataFile1, data_array1)
    
    if Plotting:
        model.Plotting(data_array1)


