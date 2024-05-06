# ----------------------------------------------------------------
#	mnemo.py
# ----------------------------------------------------------------
#	240211 - DamnedAngel
# ----------------------------------------------------------------
#	Data file builder for MnemoSyne-X.
# ----------------------------------------------------------------

import os
import sys

from mnemoresource import MnemoResource
from mnemosegment import MnemoSegment
from mnemobank import MnemoBank
from mnemoexception import MnemoException
from mnemologger import MnemoLogger

def assertParameters (tokens, numParams:int):
    l=len(tokens)
    if l <= numParams:
        raise MnemoException (f"Too few arguments for command {tokens[0].upper()} ({numParams} expected, {l-1} found).")
    if l > (numParams + 1):
        extraParams = 0
        for token in tokens[numParams + 1:]:
            if token[0] == ';':
                break
            else:
                extraParams+=1
        if extraParams > 0:
            raise MnemoException (f"Too many arguments for command {tokens[0].upper()} ({numParams} expected, {numParams+extraParams} found).")

def assertInteger (sNumber:str) -> int:
    result=None
    if len(sNumber) >= 2:
        if (sNumber[:2].upper() == "0X"):
            try:
                result = int (sNumber[2:], 16)
            except Exception as error:
                raise MnemoException (f"Invalid hexadecimal value {sNumber}.")
        if (sNumber[:2].upper() == "0B"):
            try:
                result = int (sNumber[2:], 2)
            except Exception as error:
                raise MnemoException (f"Invalid binary value {sNumber}.")
    if result is None:
        try:
            result = int (sNumber)
        except Exception as error:
            raise MnemoException (f"Invalid value {sNumber}.")
    return result

def setFileName(name:str):
    global outputFileName
    outputFileName=name

def setBank(sNumber:str):
    number = assertInteger (sNumber)
    global banks
    global currentBank
    if not number in banks.keys():
        bank=MnemoBank(number)
        banks[number]=bank
    currentBank=banks[number]

def setSegment(sNumber:str):
    number = assertInteger (sNumber)
    global currentSegment
    global currentBank
    setBank(str(number // 256))
    currentSegment=currentBank.getSegment(number)

def setRelativeSegment(sNumber:str):
    number = assertInteger (sNumber)
    setSegment(str(currentFile*256 + number))

def setNextSegment():
    global currentSegment
    nextSeg=currentSegment.number + 1
    setSegment(str(nextSeg))

def setSegmentByName(name:str):
    global currentSegment
    currentSegment=currentFile.getSegmentByName(name)

def setSegmentName(name:str):
    global currentSegment
    currentSegment.setName(name)

def addResource(name:str, fileName:str):
    global currentSegment
    currentSegment.addResource(MnemoResource.fromFile(name, fileName))

def addSplitResource(name:str, fileName:str, alignment:int):
    global currentSegment
    res=MnemoResource.fromFile(name, fileName)
    while res is not None:
        res=currentSegment.addSplitResource(res, alignment)
        if res is not None:
            setNextSegment()

def process (tokens):
    command=tokens[0].upper()

    if command == "FILENAME":
        assertParameters (tokens, 1)
        setFileName(tokens[1])
    elif command == "BANK":
        assertParameters (tokens, 1)
        setBank(tokens[1])
    elif command == "SEGMENT":
        assertParameters (tokens, 1)
        setSegment(tokens[1])
    elif command == "RELATIVESEGMENT":
        assertParameters (tokens, 1)
        setRelativeSegment(tokens[1])
    elif command == "NEXTSEGMENT":
        assertParameters (tokens, 0)
        setNextSegment()
    elif command == "SEGMENTNAME":
        assertParameters (tokens, 1)
        setSegmentName(tokens[1])
    elif command == "SEGMENTBYNAME":
        assertParameters (tokens, 1)
        setSegmentByName(tokens[1])
    elif command == "RESOURCE":
        assertParameters (tokens, 2)
        addResource(tokens[1], tokens[2])
    elif command == "SPLITRESOURCE":
        assertParameters (tokens, 3)
        addSplitResource(tokens[1], tokens[2], int(tokens[3]))
    else:
        raise MnemoException(f"Unsupported command {command}.")

# -------
# PROGRAM
# -------
print("MnemoSyne-X: a virtual memory system for MSX.")
print("Data file builder")
print("---------------------------------------------")

if (len(sys.argv) < 3) or (len(sys.argv) > 4):
    print ("Usage: python mnemo.py <MAP FILE> <MSX PAGE>")
    exit(0)

if len(sys.argv) == 4:
    MnemoBank.outputDir = sys.argv[3]

memoryMapFile = sys.argv[1]
try:
    msxPage = int (sys.argv[2])
    if (msxPage < 1) or (msxPage > 2):
        raise Exception ();
    MnemoSegment.page = msxPage
except:
    print (f"Invalid MSX page ({sys.argv[2]}). Must be either 1 or 2.")
    exit(1)

MnemoLogger.init(2)
banks = {}
currentBank:MnemoBank
currentSegment:MnemoSegment=None
outputFileName:str = "DATA"

MnemoLogger.log (f"Parsing {memoryMapFile} and loading resources... ")
MnemoLogger.incIdentLevel()

lineNumber = 0
with open(memoryMapFile, 'r') as f1:
    for line in f1:
        lineNumber+=1
        line1 = line.strip()
        if len(line1) > 0:
            if not line1[0] == ";": 
                tokens = line1.split()
                try:
                    process (tokens)
                except MnemoException as error:
                    print ("")
                    print (f"Error in file '{memoryMapFile}', line {lineNumber}:")
                    print (f"Message: {error}")
                    exit(1)
MnemoLogger.decIdentLevel()

MnemoLogger.log (f"Generating Memory Bank files... ")
MnemoLogger.incIdentLevel()
for bank in banks.values():
    bank.build(outputFileName)
MnemoLogger.decIdentLevel()

MnemoLogger.log (f"Generating C Headers... ")
MnemoLogger.incIdentLevel()
for bank in banks.values():
    bank.buildCHeader(outputFileName)
MnemoLogger.decIdentLevel()

MnemoLogger.log (f"Generating ASM Headers... ")
MnemoLogger.incIdentLevel()
for bank in banks.values():
    bank.buildASMHeader(outputFileName)
MnemoLogger.decIdentLevel()

print ("")
print ("MnemoSyne-X memory files generated! Happy MSX'ing!")

exit(0)