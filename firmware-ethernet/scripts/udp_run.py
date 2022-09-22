#!/usr/bin/python3
import socket
import select
import array
import csv
import argparse
import time
import os

parser = argparse.ArgumentParser(description='Send CSV data to SCROD')
parser.add_argument('--InputFile', help='Path to where the test bench should be created',default="/home/belle2/Documents/tmp/simplearithmetictest_tb_csv.csv")
parser.add_argument('--OutputFile', help='Name of the entity Test bench',default="data_out.csv")
parser.add_argument('--Verbose', help='Name of the entity Test bench',default="false")
parser.add_argument('--IpAddress', help='Ip Address of the Scrod',default="192.168.1.33")
parser.add_argument('--port', help='Port of the Scrod',default=2001)
parser.add_argument('--OutputHeader', help='Header File for the output csv file',default="")

args = parser.parse_args()

def get_header(HeaderFile):
    if not HeaderFile:
        return "\n"
    try :
        with open(HeaderFile) as f:
            ret = f.readlines()
    except:
        return "\n"

    ret = ret[0]
    return ret

Header = get_header(args.OutputHeader)

def debug_print(text):
    if args.Verbose != "false":
        print(text)    

class SCROD_ethernet:
    def __ToEventNumber(self, Data, Index):
        ret_h = 0
    
        ret_h += (Data[Index])
        ret_h += 0x100*(Data[Index+1])
        ret_h += 0x10000*(Data[Index+2])
        ret_h += 0x1000000*(Data[Index+3])
        return ret_h

    def __ArrayToHex(self,Data):
        ret = list()
        for j in range(0,len(Data),4):
            ret.append(hex(self.__ToEventNumber(Data,j)))
        
        return ret


    def __init__(self,IpAddress,PortNumber):
        self.IpAddress = IpAddress
        self.PortNumber = int(PortNumber)
        self.clientSock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    def send(self,Data):
        message = []
        for x in Data:
            message+=(x.to_bytes(4,'little'))
        #print("UDP Target Address:", self.IpAddress)
        #print("UDP Target Port:", self.PortNumber)
        #print("Sent message...")
        #print("")

        str1=array.array('B', message).tobytes()
        #print(self.__ArrayToHex(str1))
        self.clientSock.sendto(str1, ( self.IpAddress, self.PortNumber))

    def receive(self):
        data, addr = self.clientSock.recvfrom(4096)

        #print("\n\nrecv message from ",addr)
        data = self.__ArrayToHex(data)
        #print (data)
        return data
    def hasData(self):
         rdy_read, rdy_write, sock_err = select.select([self.clientSock,], [], [],0.1)
         #print (rdy_read, rdy_write, sock_err)
         return len(rdy_read) > 0


def get_index():
    with open("index.txt") as indexFile:
        index = indexFile.readline()
    print ( "'" + index +"'")
    index = int(index)
    with open("index.txt","w") as indexFile:
        indexFile.write(str(index+1))

    return index

class CsvLoader:
    def __init__(self,FileName):
        with open(FileName, newline='') as csvfile:
            
            self.contentLines = csvfile.readlines()
            self.numberOfRows = len(self.contentLines)-3
            print(self.numberOfRows)
         
        self.reader = csv.DictReader(FileName)
        self.fieldNames = self.reader.fieldnames 
   
        
        
        self.content = list()
        index = get_index()
        #message = list()
        #message.append(self.numberOfRows)
        #message.append(get_index())
        #self.content.append(message)
        
        lineCount = 0
        for row in self.contentLines:
            if lineCount > 1000:
                break

            lineCount+=1
            if lineCount < 3:
                continue
        
            message = list()
            #message.append(2)
            message.append(0)
            message.append(index)
            row=row.strip()
            row = row.replace("\r\n","")
            rowsp = row.split(" ")
            for coll in rowsp:
                if coll:
                    message.append(int(coll))




            self.content.append(message)

        message = list()
        message.append(1)
        message.append(index)
        message.append(0)
        message.append(0)
        message.append(0)
        message.append(0)    
        self.content.append(message)    







try:
    os.remove(args.OutputFile)
except:
    print ( "output file not found")

    
scrod1 = SCROD_ethernet(args.IpAddress,args.port)
scrod1.hasData()
csv = CsvLoader(args.InputFile)

print("send data")
i = 0 
for row in csv.content:
        scrod1.send(row)
        debug_print([i,row])
        
        #time.sleep(1)
        i+= 1
print("receive data")
i = 0 
startTime = time.time()
print(startTime)
with open(args.OutputFile,"w",newline="") as f:
    f.write(Header)
    while scrod1.hasData():
        data = scrod1.receive()
        line = ""
        start = ""
        for d in data:
            line += start + str(int(d,16)) 
            start = "; "
        f.write(line+"\n")
        debug_print([i,line])
        i+= 1

endTime = time.time()
print(endTime, endTime -startTime )
print("number of received packages: ",i)
print("----end udp_run script----")


