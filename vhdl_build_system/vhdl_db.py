import pickle
import os



def LoadDB(FileName,NewDB=False):
  if NewDB:    
    try:
      os.remove(FileName)
    except OSError:  
      print ("removing of DBfile  %s failed" % FileName)
    else:  
      print ("Successfully removed DB file %s " % FileName)
    finally:
      data={}
      return data

  
  with open(FileName, 'rb') as f:
      # The protocol version used is detected automatically, so we do not
      # have to specify it.
      data = pickle.load(f) 
  
  return data


def saveDB(FileName,Data):



  with open(FileName, 'wb') as f:
      # Pickle the 'data' dictionary using the highest protocol available.
      pickle.dump(Data, f, pickle.HIGHEST_PROTOCOL)
  
  