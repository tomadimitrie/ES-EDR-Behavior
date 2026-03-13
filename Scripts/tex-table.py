from itertools import batched
import re

data = r"""
\hline
\cellcolor{yellow!20}T1005 & \cellcolor{green!20}T1016(1) & \cellcolor{green!20}T1016(2) & \cellcolor{red!20}T1016.001 & \cellcolor{green!20}T1018(1) \\
\hline
\cellcolor{green!20}T1018(2) & \cellcolor{yellow!20}T1021.005 & \cellcolor{green!20}T1027 & \cellcolor{green!20}T1027.001(1) & \cellcolor{green!20}T1027.001(2) \\
\hline
\cellcolor{red!20}T1027.004(1) & \cellcolor{red!20}T1027.004(2) & \cellcolor{red!20}T1027.004(3) & \cellcolor{green!20}T1030 & \cellcolor{green!20}T1033 \\
\hline
\cellcolor{red!20}T1036.005 & \cellcolor{green!20}T1036.006 & \cellcolor{red!20}T1037.004 & \cellcolor{red!20}T1037.005(1) & \cellcolor{green!20}T1037.005(2) \\
\hline
\cellcolor{green!20}T1037.005(3) & \cellcolor{green!20}T1040(1) & \cellcolor{red!20}T1040(2) & \cellcolor{red!20}T1040(3) & \cellcolor{red!20}T1046(1) \\ 
\hline
\cellcolor{green!20}T1046(2) & \cellcolor{green!20}T1046(3) & \cellcolor{red!20}T1048(1) & \cellcolor{red!20}T1048(2) & \cellcolor{red!20}T1048(3) \\
\hline
\cellcolor{red!20}T1048.002 & \cellcolor{green!20}T1049 & \cellcolor{green!20}T1053.003 & \cellcolor{yellow!20}T1056.002(1) & \cellcolor{yellow!20}T1056.002(2) \\
\hline
\cellcolor{red!20}T1057 & \cellcolor{green!20}T1059.002 & \cellcolor{red!20}T1059.004(1) & \cellcolor{red!20}T1059.004(2) & \cellcolor{red!20}T1059.004(3) \\
\hline
\cellcolor{green!20}T1069.001 & \cellcolor{green!20}T1070.002(1) & \cellcolor{red!20}T1070.002(2) & \cellcolor{red!20}T1070.002(3) & \cellcolor{green!20}T1070.002(4) \\
\hline
\cellcolor{green!20}T1070.002(5) & \cellcolor{red!20}T1070.002(6) & \cellcolor{green!20}T1070.002(7) & \cellcolor{red!20}T1070.002(8) & \cellcolor{red!20}T1070.002(9) \\
\hline
\cellcolor{green!20}T1070.002(10) & \cellcolor{red!20}T1070.002(11) & \cellcolor{green!20}T1070.003(1) & \cellcolor{red!20}T1070.003(2) & \cellcolor{green!20}T1070.003(3) \\
\hline
\cellcolor{red!20}T1070.003(4) & \cellcolor{red!20}T1070.003(5) & \cellcolor{red!20}T1070.003(6) & \cellcolor{red!20}T1070.004(1) & \cellcolor{red!20}T1070.004(2)  \\
\hline
\cellcolor{green!20}T1070.006(1) & \cellcolor{green!20}T1070.006(2) & \cellcolor{red!20}T1070.006(3) & \cellcolor{green!20}T1070.006(4) & \cellcolor{red!20}T1070.006(5) \\
\hline
\cellcolor{red!20}T1070.008(1) & \cellcolor{red!20}T1070.008(2) & \cellcolor{red!20}T1071.001 & \cellcolor{green!20}T1074.001 & \cellcolor{green!20}T1078.001 \\
\hline
\cellcolor{green!20}T1078.003(1) & \cellcolor{green!20}T1078.003(2) & \cellcolor{green!20}T1078.003(3) & \cellcolor{green!20}T1082(1) & \cellcolor{red!20}T1082(2) \\
\hline
\cellcolor{red!20}T1082(3) & \cellcolor{red!20}T1082(4) & \cellcolor{green!20}T1082(5) & \cellcolor{green!20}T1082(6) & \cellcolor{green!20}T1083(1) \\
\hline
\cellcolor{green!20}T1083(2) & \cellcolor{green!20}T1087.001(1) & \cellcolor{red!20}T1087.001(2) & \cellcolor{green!20}T1087.001(3) & \cellcolor{green!20}T1087.001(4) \\
\hline
\cellcolor{green!20}T1087.001(5) & \cellcolor{red!20}T1090.001(1) & \cellcolor{green!20}T1090.001(2) & \cellcolor{red!20}T1098.004 & \cellcolor{red!20}T1105(1) \\
\hline
\cellcolor{red!20}T1105(2) & \cellcolor{red!20}T1105(3) & \cellcolor{red!20}T1105(4) & \cellcolor{red!20}T1105(5) & \cellcolor{red!20}T1105(6) \\
\hline
\cellcolor{red!20}T1105(7) & \cellcolor{green!20}T1105(8) & \cellcolor{red!20}T1110.004 & \cellcolor{green!20}T1113(1) & \cellcolor{green!20}T1113(2)  \\
\hline
\cellcolor{red!20}T1115 & \cellcolor{yellow!20}T1123 & \cellcolor{red!20}T1124 & \cellcolor{red!20}T1132.001 & \cellcolor{red!20}T1135 \\
\hline
\cellcolor{green!20}T1136.001 & \cellcolor{red!20}T1140(1) & \cellcolor{red!20}T1140(2) & \cellcolor{green!20}T1140(3) & \cellcolor{red!20}T1140(4) \\
\hline
\cellcolor{green!20}T1140(5) & \cellcolor{red!20}T1140(6) & \cellcolor{red!20}T1201 & \cellcolor{green!20}T1217(1) & \cellcolor{green!20}T1217(2) & \cellcolor{green!20}T1217(3) & \cellcolor{red!20}T1222.002(1) & \cellcolor{red!20}T1222.002(2) \\
\hline
\cellcolor{red!20}T1222.002(3) & \cellcolor{red!20}T1222.002(4) & \cellcolor{red!20}T1222.002(5) & \cellcolor{red!20}T1222.002(6) & \cellcolor{red!20}T1222.002(7) \\
\hline
\cellcolor{red!20}T1222.002(8) & \cellcolor{red!20}T1222.002(9) & \cellcolor{red!20}T1222.002(10) & \cellcolor{red!20}T1222.002(11) & \cellcolor{green!20}T1485 \\
\hline
\cellcolor{red!20}T1486(1) & \cellcolor{red!20}T1486(2) & \cellcolor{green!20}T1490 & \cellcolor{red!20}T1497.001(1) & \cellcolor{red!20}T1497.001(2) \\
\hline
\cellcolor{red!20}T1497.001(3) & \cellcolor{green!20}T1497.001(4) & \cellcolor{red!20}T1497.003 & \cellcolor{red!20}T1518 &  \cellcolor{red!20}T1518.001 \\
\hline
\cellcolor{red!20}T1531(1) & \cellcolor{red!20}T1531(2) & \cellcolor{red!20}T1531(3) & \cellcolor{green!20}T1539 & \cellcolor{green!20}T1543.001(1) \\
\hline
\cellcolor{green!20}T1543.001(2) & \cellcolor{green!20}T1543.004 & \cellcolor{red!20}T1546.004(1) & \cellcolor{red!20}T1546.004(2) \\
\hline
\cellcolor{red!20}T1547.007(1) & \cellcolor{red!20}T1547.007(2) & \cellcolor{red!20}T1547.007(3) & \cellcolor{red!20}T1548.001(1) &
\cellcolor{red!20}T1548.001(2) \\
\hline
\cellcolor{red!20}T1548.001(3) & \cellcolor{green!20}T1548.003(1) & \cellcolor{red!20}T1548.003(2) & \cellcolor{red!20}T1552.004(1) &
\cellcolor{green!20}T1552.004(2) \\
\hline
\cellcolor{red!20}T1552.004(3) & \cellcolor{green!20}T1553.001 & \cellcolor{red!20}T1553.004 & \cellcolor{green!20}T1555.001(1) & \cellcolor{green!20}T1555.001(2) \\
\hline
\cellcolor{red!20}T1555.001(3) & \cellcolor{red!20}T1555.001(4) & \cellcolor{red!20}T1560.001(1) & \cellcolor{red!20}T1560.001(2) & \cellcolor{red!20}T1560.001(3) \\
\hline
\cellcolor{red!20}T1560.001(4) & \cellcolor{green!20}T1562.001(1) & \cellcolor{green!20}T1562.001(2) & \cellcolor{green!20}T1562.001(3) & \cellcolor{green!20}T1562.001(4) \\
\hline
\cellcolor{green!20}T1562.001(5) & \cellcolor{red!20}T1562.003 & \cellcolor{red!20}T1564.001(1) & \cellcolor{red!20}T1564.001(2) & \cellcolor{red!20}T1564.001(3) \\
\hline
\cellcolor{green!20}T1564.001(4) & \cellcolor{red!20}T1564.001(5) & \cellcolor{green!20}T1564.002(1) & \cellcolor{green!20}T1564.002(2) & \cellcolor{green!20}T1569.001 \\
\hline
\cellcolor{green!20}T1571 & \cellcolor{red!20}T1574.006 & \cellcolor{red!20}T1614 & & \\
\hline
"""

items = re.findall(r"(\\cellcolor[^ ]+)", data)
print(r"\hline")

for chunk in batched(items, n=5):
    print(" & ".join(chunk) + " \\\\")
    print(r"\hline")
