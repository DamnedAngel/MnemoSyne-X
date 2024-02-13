# ---------------- ------------------------------------------------
#	mnemobank.py
# ----------------------------------------------------------------
#	240211 - DamnedAngel
# ----------------------------------------------------------------
#	MnemoSyne-X Bank class
# ----------------------------------------------------------------

import io

from mnemosegment import MnemoSegment
from mnemologger import MnemoLogger


class MnemoBank:
    outputDir = "."

    def __init__(self, number: int):
        self.number=number
        self.segments = []
        for i in range(256):
            segNumber=self.number*256 + i
            self.segments.append (MnemoSegment (str(segNumber).zfill(5), segNumber))

    def getSegment (self, number:int) -> MnemoSegment:
        return self.segments[number % 256]

    def getRelativeSegment (self, number:int) -> MnemoSegment:
        return self.segments[number]

    def getSegmentByName (self, name:str) -> MnemoSegment:
        for segment in self.segments:
            if (segment.name == name):
                return segment
        raise Exception(f"Undefined segment name {name}.")

    def build (self, name:str):
        hexNumber=hex(self.number)[2:].upper().zfill(2)
        ext=f"_{hexNumber}"
        fileName=f"{name}.{ext}"
        MnemoLogger.log (f"Building {fileName}... ", end="")
        index = bytearray(0)
        data = bytearray(0)
        for i in range(256):
            segment=self.segments[i]
            segSize=segment.getSize()
            if segSize == 0:
                index=index+segSize.to_bytes(4, "little")
            else:
                pos = len(data)+1024
                bPos = pos.to_bytes(4, "little")
                index=index+bPos
                data=data+segment.getData()

        data=index+data

        MnemoLogger.log(f"Saving {fileName}... ", ident=False, time=False, end="")
        with open(MnemoBank.outputDir + "\\" + fileName, "wb") as file:
            file.write(data)
        MnemoLogger.log(f"Done!", ident=False, time=False)

    def buildCHeader (self, name:str):
        hexNumber=hex(self.number)[2:].upper().zfill(2)
        ext=f"_{hexNumber}"
        fileName=f"{name}.{ext}.h"

        MnemoLogger.log (f"Saving {fileName}... ", end="")
        with open(MnemoBank.outputDir + "\\" + fileName, "w", encoding="ascii") as file:
            file.write(f"// --------------------------------\n")
            file.write(f"// MnemoSyne-X Memory Bank {self.number}\n")
            file.write(f"// --------------------------------\n")
            file.write(f"\n")

            for segment in self.segments:
                segment.writeCHeader(file)

        MnemoLogger.log(f"Done!", ident=False, time=False)

    def buildASMHeader (self, name:str):
        hexNumber=hex(self.number)[2:].upper().zfill(2)
        ext=f"_{hexNumber}"
        fileName=f"{name}.{ext}_h.s"

        MnemoLogger.log (f"Saving {fileName}... ", end="")
        with open(MnemoBank.outputDir + "\\" + fileName, "w", encoding="ascii") as file:
            file.write(f"; --------------------------------\n")
            file.write(f"; MnemoSyne-X Memory Bank {self.number}\n")
            file.write(f"; --------------------------------\n")
            file.write(f"\n")

            for segment in self.segments:
                segment.writeASMHeader(file)

        MnemoLogger.log(f"Done!", ident=False, time=False)
