import sys
try:
    f=open(sys.argv[1]+".osd",'r')
except:
    f=open(input("file name>")+".osd",'r')
prog=f.read()
f.close()
reserved={'func':"FUNC",'return':"RET",'int':'INTT', 'String':'STRT', 'float':'FLOATT', 'N/A':'FLOAT', "byte":"BYTET", "N/A":"REGISTER", "print":"PRINT", "clear":"CLEAR", "in":"IN", "pointer":"POINT"}
tokens = list(reserved.values())+[
    'NAME','NUMBER','EQU','STR'
    ]
t_STR    = r'"[\n-ÿ]*"'
t_EQU    = r'\='
registers=["ax","bx","cx","dx","si","di","al","ah","bl","bh","cl","ch","dl","dh"]
def t_NAME(t):
    r'[a-zA-Z_][a-zA-Z0-9_]*'
    if t.value in registers:
        t.type="REGISTER"
    if t.value in reserved:
        t.type=reserved.get(t.value)
    return t
def t_NUMBER(t):
    r'[0-9][0-9.-.]*'
    if '.' in t.value:
        t.type='FLOAT'
        try:
            t.value = float(t.value)
        except:
            print("invalid float "+t.value)
            t.value = 0
    else:
        try:
            t.value = int(t.value)
        except ValueError:
            print("Integer value too large %d", t.value)
            t.value = 0
    return t
t_ignore = " \t\n"

def t_newline(t):
    r'\n+'
    t.lexer.lineno += t.value.count("\n")
    
def t_error(t):
    print("Illegal character '%s'" % t.value[0])
    t.lexer.skip(1)
    
# Build the lexer
import ply.lex as lex
lexer = lex.lex()

# Parsing rules
# dictionary of names
names = {}
functions=[]
tempnames={}
program=""
data=""
def p_func_start(t):
    '''func : FUNC NAME
            | FUNC NAME NAME
            | FUNC NAME NAME NAME
            | FUNC NAME NAME NAME NAME'''
    tempnames={}
    if len(t)==3:
        program+=t[2]+":\npusha\n"
    elif len(t)==4:
        program+=t[2]+":\npusha\n"
        tempnames[t[3]]="ax"
    elif len(t)==5:
        program+=t[2]+":\npusha\n"
        tempnames[t[3]]="ax"
        tempnames[t[3]]="bx"
    elif len(t)==6:
        program+=t[2]+":\npusha\n"
        tempnames[t[3]]="ax"
        tempnames[t[3]]="bx"
        tempnames[t[3]]="cx"
def p_func_end(t):
    '''func : RET
            | RET expression'''
    if len(t)==2:
        program+='popa\nret\n'
    else:
        program+='popa\nmov ax, '+t[2]+'\nret\n'
def p_raw_set(t):
    '''raw : INTT NAME
           | INTT NAME EQU expression
           | FLOATT NAME
           | FLOATT NAME EQU expression
           | STRT NAME EQU STR
           | POINT NAME EQU NUMBER'''
    if t[1]=="String":
        data+=t[2]+" db "+str(t[4])+",0\n"
        names[t[2]]="String"
    elif t[1]=="point":
        data+=t[2]+" equ "+str(4)+"\n"
        names[t[2]]="multi"
    else:
        if len(t)>3:
            data+=t[2]+" dw 0\n"
            names[t[2]]="int"
            program+="mov word ["+t[2]+"],"+str(t[4])+"\n"
        else:
            data+=t[2]+" dw 0\n"
            names[t[2]]="int"
def p_register_set(t):
    'register : REGISTER EQU expression'
    program+="mov "+t[1]+", "+t[3]+'\n'
def p_expression_var(t):
    'expression : NAME'
    if t[1] in names:
        t[0] = '['+t[1]+']'
    else:
        print("Undefined name '%s'" % t[1])
        t[0] = "0"
def p_expression_int(t):
    'expression : NUMBER'
    t[0]=int(t[1])
#def p_expression_float(t):
#    'expression : NUMBER'
#    t[0]=float(t[1])
def p_error(t):
    if t!=None:
        print("invalid token '"+str(t.value)+"'")
import ply.yacc as yacc
parser = yacc.yacc()
parser.parse(prog)

if not "main" in functions:
    print("function 'main' was not defined. please insert 'func main' before your main code.")
    e=True
if not e:
    try:
        f=open(sys.argv[2]+".asm",'w')
    except:
        f=open(input("output file name>")+".asm",'w')
    f.write(asm+"\n\n"+data)
    f.close()
