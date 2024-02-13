# ----------------------------------------------------------------
#	mnemologger.py
# ----------------------------------------------------------------
#	240211 - DamnedAngel
# ----------------------------------------------------------------
#	Logger for Data file builder.
# ----------------------------------------------------------------

from datetime import datetime

class MnemoLogger:
    identLevel=0
    tabSize=2

    @classmethod
    def init(cls, tab):
        cls.identLevel=0
        cls.tabSize=tab

    @classmethod
    def incIdentLevel(cls):
        cls.identLevel+=1

    @classmethod
    def decIdentLevel(cls):
        if cls.identLevel > 0:
            cls.identLevel-=1

    @classmethod
    def log(cls, msg, ident=True, time=True, end=None):
        if time:
            t = f"[{datetime.now().strftime('%H:%M:%S')}] "
        else:
            t = ""

        if ident:
            i = ' '*(cls.identLevel*cls.tabSize)
        else:
            i = ""

        print ('{}{}{}'.format(i, t, msg), end=end)

