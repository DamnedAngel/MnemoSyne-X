# ---------------- ------------------------------------------------
#	mnemosegment.py
# ----------------------------------------------------------------
#	240211 - DamnedAngel
# ----------------------------------------------------------------
#	Segment for Data file builder
# ----------------------------------------------------------------

#import io

from mnemoresource import MnemoResource
from mnemoexception import MnemoException

class MnemoSegment:
    page = 2
    segHeader = 256*4
    headerSize = 8
    maxSize = 16*1024

    def __init__(self, name:str, number: int):
        self.name=name
        self.number=number
        self.resources = []

    def getSize(self) -> int:
        size = 0
        for resource in self.resources:
            size += resource.getSize()
        return size

    def free(self) -> int:
        return MnemoSegment.maxSize - self.getSize() - MnemoSegment.headerSize

    def setName(self, name:str):
        self.name=name

    def getRelativeSegmentNumber(self) -> int:
        return self.number % 256
  
    def addResource(self, resource:MnemoResource):
        if resource.getSize() > self.free():
            raise MnemoException(f"Not enough room in segment {self.name} to fit resource {resource.name}.")
        self.resources.append (resource)

    def addSplitResource(self, resource:MnemoResource, alignment) -> MnemoResource:
        free = self.free()
        if resource.getSize > free:
            if resource.instance is None:
                myInstance=0
            else:
                myInstance=resource.instance
            mySize = free - (free % alignment)
            myResource=MnemoResource.fromBuffer(resource.name, resource.content[:mySize], myInstance)
            self.resources.append (myResource)
            retResource=MnemoResource.fromBuffer(resource.name, resource.content[mySize:], myInstance + 1)
            return retResource 
        else:
            self.addResource(resource)
            return None

    def getData(self) -> bytearray:
        data = bytearray(0)
        for resource in self.resources:
            data=data+resource.content
        data=data+bytearray(self.free())
        return data

    def writeCHeader(self, file):
        if len(self.resources) > 0:
            addr = (MnemoSegment.page << 14) + MnemoSegment.segHeader
            sNumber = str(self.number).zfill(5)
            if self.name == sNumber:
                n = self.name
            else:
                n = f"{self.name} ({sNumber})"
            file.write (f"// --------------------------------\n")
            file.write (f"// Segment {self.number} ({self.number:#06x})\n")
            file.write (f"// --------------------------------\n")
            file.write (f"#define MNEMO_SEG_{self.name.upper()}".ljust(40) + f" {self.number}\n")

            for resource in self.resources:
                file.write (f"#define MNEMO_RES_{resource.getFullName().upper()}_SEG".ljust(40) + f" MNEMO_SEG_{self.name.upper()}\n")
                file.write (f"#define MNEMO_RES_{resource.getFullName().upper()}".ljust(40) + f" {hex(addr)}\n")
                addr += resource.getSize()
            file.write ("\n")

    def writeASMHeader(self, file):
        if len(self.resources) > 0:
            addr = (MnemoSegment.page << 14) + MnemoSegment.segHeader
            sNumber = str(self.number).zfill(5)
            if self.name == sNumber:
                n = self.name
            else:
                n = f"{self.name} ({sNumber})"
            file.write (f"; --------------------------------\n")
            file.write (f"; Segment {self.number} ({self.number:#06x})\n")
            file.write (f"; --------------------------------\n")
            file.write (f"MNEMO_SEG_{self.name.upper()}".ljust(40) + f" .equ".ljust(10) + f"{self.number}\n")

            for resource in self.resources:
                file.write (f"MNEMO_RES_{resource.getFullName().upper()}_SEG".ljust(40) + f" .equ".ljust(10) + f"MNEMO_SEG_{self.name.upper()}\n")
                file.write (f"MNEMO_RES_{resource.getFullName().upper()}".ljust(40) + f" .equ".ljust(10) + f"{hex(addr)}\n")
                addr += resource.getSize()
            file.write ("\n")
        