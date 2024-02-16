# ---------------- ------------------------------------------------
#	mnemo.py
# ----------------------------------------------------------------
#	240211 - DamnedAngel
# ----------------------------------------------------------------
#	Resource for Data file builder
# ----------------------------------------------------------------

import io
from mnemoexception import MnemoException

class MnemoResource:

    def __init__(self, name:str, content:bytes, instance:int):
        self.name=name
        self.content=content
        self.instance=instance

    @classmethod
    def fromFile (cls, name:str, fileName: str):
        try:
            with open(fileName, mode='rb') as file: # b is important -> binary
                return MnemoResource(name, file.read(), None)
        except Exception as error:
            raise MnemoException (f"Could not read data from file '{fileName}'.")

    @classmethod
    def fromBuffer (cls, name:str, content:bytes, instance:int):
        return MnemoResource(name, content, instance)

    def getSize(self) -> int:
        return len(self.content)

    def getFullName(self) -> str:
        if self.instance is None:
            return self.name
        else:
            return f"{self.name}_{str(self.instance)}"

