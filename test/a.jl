
a = r"TEXT .*?(!|;)|.(param)[ ]+([A-Z0-9]*)[= ]*([0-9.e+-]*)(.*?)(?:\\n|$)"im
b = r".(measure|meas)[ ]+(?:ac|dc|op|tran|tf|noise)[ ]+(\S+)[ ]+"im
c = r".(step)[ ]+(oct|param|[])[ ]+([a-z0-9]*)[ ]+(list|[])[ ]+([0-9.e+-]*)[ ]+([0-9.e+-]*)[ ]+([0-9.e+-]*)"im


match_tags = r"(
              TEXT .*?(!|;)|
              .(param)[ ]+([A-Z0-9]*)[= ]*([0-9.e+-]*)(.*?)(?:\\n|$)|
              .(measure|meas)[ ]+(?:ac|dc|op|tran|tf|noise)[ ]+(\S+)[ ]+|
              .(step)[ ]+(oct|param|[])[ ]+([a-z0-9]*)[ ]+(list|[])[ ]+([0-9.e+-]*)[ ]+([0-9.e+-]*)[ ]+([0-9.e+-]*)
              )"imx


d = r".(step)[ ]+(oct |param ){0,1}[ ]*([a-z0-9]*)[ ]+(list ){0,1}[ ]*([0-9.e+-]*[ ]*)*"im