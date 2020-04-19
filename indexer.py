# -*- coding: utf-8 -*-

import os
import re
style = """
body{
	font-family:sans-serif;
	margin:20px;
}
table, th, td {
  	border: 1px solid black;
}
div{
	border: 1px solid black;
	padding:5px;
}
"""
print("indexing...")
for r,ds,fs in os.walk("./"):	
	if "." in r[1:]:
		continue
	if "index.html" in fs:
		continue
	print(r)
	html = "<html><style>"+style+"</style><h1>"+r+"</h1><table><tr><td>🔙</td><td><a href=\""+"/".join(r.split("/")[0:-1])+"\">../</a></td></tr>"

	for d in ds:
		html += "<tr><td>📁</td><td><a href=\""+r+"/"+d+"\">"+d+"/</a></td></tr>"
	for f in fs:
		if f[0] == ".":
			continue
		html += "<tr><td>📄</td><td><a href=\""+r+"/"+f+"\">"+f+"</a></td></tr>"
	html+="</table>"
	if "README.md" in fs:
		t = re.sub(r'\[(.*?)\]\((.*?)\)',r'<a href="\2">\1</a>',
			re.sub(r'!\[.*?\]\((.*?)\)',r'<img src="\1" width="300"></img>',
				open(r+"/"+"README.md",'r').read().replace("\n","<br>")))
		html+='<h2>📖 README.md</h2><div style="font-family:monospace">'+t+"</div>";
	html += "</html>"
	open(r+"/index.html",'w').write(html);
print("done.")