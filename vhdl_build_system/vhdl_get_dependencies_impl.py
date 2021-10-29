
def isSubPath(sub, main):
    sub = sub[:sub.rfind("/")]

    return  main.startswith(sub)

def find_entity(d,Entity, currentFileName="."):
    for k in d.keys():
        if not isSubPath(currentFileName, k):
            continue
        for e in d[k]['entityDef']:
            
            if e.lower() == Entity.lower():
                return d[k]['FileName']



    currentFileName = currentFileName[:currentFileName.rfind("/")]
    if currentFileName:
        return find_entity(d,Entity, currentFileName)
    
    print("unable to find Entity " +Entity)
    return None
     





def find_used_entities(d,FileName):
    ret = list()
 
    e2 = d[FileName]['entityUSE']
    
    for r in e2:
        if "work." in r:
            r = r.replace("work.", "")
            ret.append(r)

    return ret


def find_component(d,component, currentFileName="."):

    for k in d.keys():
        if not isSubPath(currentFileName, k):
            continue
        for e in d[k]['entityDef']:
            if e.lower() == component.lower():
                return d[k]['FileName']

    

    currentFileName = currentFileName[:currentFileName.rfind("/")]
    if currentFileName:
        return find_component(d,component, currentFileName)


    print("unable to find component  " +component)
    return None

def find_used_components(d,FileName):
    ret = list()
 
    e2 = d[FileName]['ComponentUSE']
    
    for r in e2:
        r = r.replace("work.", "")
        ret.append(r)

    return ret



def find_PacketDef(d,Entity, currentFileName="."):
    #print(Entity)
    for k in d.keys():
        if not isSubPath(currentFileName, k):
            continue

        for e in d[k]['packageDef']:
            if e.lower() == Entity.lower():
                #print(Entity , d[k]['FileName'])
                return d[k]['FileName']
    
    currentFileName = currentFileName[:currentFileName.rfind("/")]
    if currentFileName:
        return find_PacketDef(d,Entity, currentFileName)

    print("unable to find package " +Entity)
    return None




def find_used_package(d,FileName):
    ret = list()
    e1 = d[FileName]['packageUSE']

    for r in e1:
        ret.append(r)
        

    return ret



def make_depency_list(d, eneties_used, find_used_func,find_def_func):
    old_length = 0
    new_length = 1
    while (new_length > old_length):
        old_length = new_length
        new_EntitesUsed = eneties_used.copy()
        for k in eneties_used:
        
            currentFileName = new_EntitesUsed[k]
            entites_in_file = find_used_func(d,currentFileName)
            
            for e in entites_in_file:
                FileName = find_def_func(d,e,currentFileName)
                
                if FileName and ".xco" not in FileName:
                    new_EntitesUsed[e] = FileName


        new_length = len(new_EntitesUsed)
        eneties_used = new_EntitesUsed.copy()
    
    return eneties_used


