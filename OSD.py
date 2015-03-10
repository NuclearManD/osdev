import sys
try:
    f=open(sys.argv[1]+".osd",'r')
except:
    f=open(input("file name>")+".osd",'r')
prog=f.read()
f.close()
tmp=""
tokens=[]
prg=True
for i in prog:
    if(i=='\n' or i==' ')and prg:
        tokens.append(tmp)
        tmp=""
    elif i=='"':
        prg=not prg
    elif (i=='='or i=='/' or i=='*' or i=='+' or i=='-' or i=='.')and prg:
        tokens.append(tmp)
        tokens.append(i)
        tmp=""
    elif (i==')' or i=='(')and prg:
        tokens.append(tmp)
        tmp=""
    elif i=='\t' and prg:
        pass
    else:
        tmp+=i
tokens.append(tmp)
var=["ret"]
vty=["dword"]
functions=[]
asm="bits 16\norg 6000h\njmp main\n"# the fromt will be the program and the end will be the data.
data=""
i=0
e=False
whn=0
while i<len(tokens):
    if tokens[i]=="func":
        i+=1
        functions.append(tokens[i])
    i+=1
i=0
while i<len(tokens):
    if tokens[i]=="int":#int <new varname> [= <value>]
        i+=1
        var.append(tokens[i])
        vty.append("dword")
        if tokens[i+1]=="=":
            i+=2
            if tokens[i] in var:
                vl=str(var.index(tokens[i])+10)
                asm+="\nMOV eax,["+str(var.index(tokens[i])+10)+"]\nMOV ["+vl+"],eax\n\n"
            else:
                asm+="MOV ["+str(var.index(tokens[i-2])+10)+"],dword "+tokens[i]+"\n"
    elif tokens[i]=="String":#String, a constant. you must set it to a value.
        if not tokens[i+2]=='=':
            print("constant strings must be set to a value.")
            e=True
        else:
            i+=1
            data+=tokens[i]+' db "'+tokens[i+2]+'",0\n'
            var.append(tokens[i])
            vty.append("const")
            i+=2
    elif tokens[i]=="byte":#byte
        i+=1
        var.append(tokens[i])
        vty.append("byte")
        if tokens[i+1]=="=":
            i+=2
            if tokens[i] in var:
                vl=str(var.index(tokens[i-2])+10)
                asm+="\nMOV eax,["+str(var.index(tokens[i])+10)+"]\nMOV ["+vl+"],eax\n\n"
            else:
                asm+="MOV ["+str(var.index(tokens[i-2])+10)+"],byte "+tokens[i]+"\n"
    elif tokens[i]=="point":#byte
        i+=1
        var.append(tokens[i])
        vty.append("*")
        if tokens[i+1]=="=":
            i+=2
            if tokens[i] in var:
                print("pointer location must be a constant int of base 16, not a variable")
            else:
                vty[len(vty)-1]+=str(int(tokens[i],16))
        else:
            print("must define location of a pointer.")
            e=True
    elif tokens[i]=="ASM":#ASM "<assembly source>"
        i+=1
        asm+=tokens[i]+"\n\n"
    elif tokens[i]=="in":
        i+=1
        if vty[var.index(tokens[i])]=="const":
            print("cannot modify a constant value.")
            e=True
        else:
            asm+="\nlodsb\nmov ["+str(var.index(tokens[i])+10)+"], al\n"
    elif tokens[i] in var:#<var varname> = <value>
        if tokens[i+1]=="=":
            if vty[var.index(tokens[i])]=="const":
                print("cannot modify a constant value.")
                e=True
            elif vty[var.index(tokens[i])][0]=='*':
                vl=vty[var.index(tokens[i])][1:]
                i+=2
                if tokens[i] in var:
                    asm+="\nMOV ax,["+str(var.index(tokens[i])+10)+"]\nMOV ["+vl+"],ax\n\n"
                else:
                    asm+="MOV ["+vl+"],dword "+tokens[i]+"\n"
            else:
                vl=str(var.index(tokens[i])+10)
                i+=2
                if tokens[i] in var:
                    if vty[var.index(tokens[i])][0]=='*':
                        asm+="\nMOV ax,["+vty[var.index(tokens[i])][1:]+"]\nMOV ["+vl+"],ax\n\n"
                    else:
                        asm+="\nMOV ax,["+str(var.index(tokens[i])+10)+"]\nMOV ["+vl+"],ax\n\n"
                else:
                    asm+="MOV ["+vl+"],"+vty[int(vl)]+' '+tokens[i]+"\n"
        else:
            print("what to do with "+tokens[i]+"?")
            e=True
    elif tokens[i]=="if":
        i+=1
        if tokens[i+1]=="=":
            asm+="\ncmp ["+str(var.index(tokens[i])+10)+"],"+vty[var.index(tokens[i])]+" "+tokens[i+2]+"\nje "+tokens[i+3]+"\n"
        elif tokens[i+1]=="!=":
            asm+="\ncmp "+tokens[i]+", "+tokens[i+2]+"\njne "+tokens[i+3]+"\n"
        else:
            print("invalid operator")
            e=True
        i+=3
    elif tokens[i]=="import":
        i+=1
        fd=open("imports/data-"+tokens[i]+".asm",'r')
        data+=fd.read()+'\n'
        fd.close()
        fa=open("imports/asm-"+tokens[i]+".asm",'r')
        data=fa.read()+'\n'+data
        fa.close()
        ff=open("imports/func-"+tokens[i]+".asm",'r')
        funcn=ff.read()
        tmp=""
        for t in funcn:
            if t=='\n':
                if not tmp=='':
                    functions.append(tmp)
                    tmp=""
            else:
                tmp+=t
        functions.append(tmp)
        ff.close()
    elif tokens[i]in functions:
        if tokens[i+1]=='*':
            asm+="\nmov si,"+tokens[i+2]+"   ;si args func access\ncall "+tokens[i]+'\n\n'
            i+=2
        else:
            asm+="call "+tokens[i]+"   ;void args func access\n"
    elif tokens[i]=="N":
        i+=1
        if tokens[i] in functions:
            if tokens[i+1]=='*':
                asm+="\nmov si,"+tokens[i+2]+"   ;si args func access\njmp "+tokens[i]+'\n\n'
                i+=2
            else:
                asm+="jmp "+tokens[i]+"   ;void args func access\n"
        else:
            print("'N' must have valid function.")
            e=True
    elif tokens[i]=="func":
        i+=1
        asm+="\n        "+tokens[i]+":\n"
        i+=1
    elif tokens[i]=="halt":
        asm+="hlt\n"
    elif tokens[i]=="return":
        asm+="ret\n"
    elif tokens[i]=="bits":
        i+=1
        asm+="bits "+tokens[i]+"\n"
    elif tokens[i]=='':
        pass
    else:
        print(tokens[i]+" is not an identifier.")
        print("token "+str(i) )
        e=True
    i+=1
if not "main" in functions:
    print("function 'main' was not defined. please insert 'func main()' before your main code.")
    e=True
if not e:
    try:
        f=open(sys.argv[2]+".asm",'w')
    except:
        f=open(input("output file name>")+".asm",'w')
    f.write(asm+"\n\n"+data)
    f.close()
