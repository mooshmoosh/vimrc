"Preliminiaries. Set up core vim settings
"{{{
" Set up Vundle
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" end vundle setup

syntax enable
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
set foldmethod=marker
set number
set wrap
set linebreak
set iskeyword=@,48-57,_,192-255,#
colorscheme desert
filetype plugin on
let mapleader = ","

"}}}
"Python set up. Mainly my wrapper around Vim API
"{{{
python << endpython
import vim

# This contains a list of functions that each check if the file being edited is a particular type
# If it is a certain type, then the unit tests will be run, and the function returns true, other wise
# the function returns false. When the keyboard shortcut is triggered, a function itterates over this list
# looking for the first function that returns true
RunUnitTestListeners = []

def setCursor( line, col ):
    vim.current.window.cursor = ( line + 1, col )

def getFileType():
    filename = vim.current.buffer.name
    return filename.split('.')[-1]

def getTab():
    return vim.current.tabpage.number - 1

def getRow():
    (x,y) = vim.current.window.cursor
    return x-1

def getCol():
    (x,y) = vim.current.window.cursor
    return y

def getLine(i):
    return vim.current.buffer[i]

def getFilename():
    return vim.current.buffer.name

def getChar(i,j):
    return vim.current.buffer[i][j]

def insertLine ( i, newLine ):
    vim.current.buffer.append(newLine, i)

def setLine ( i, newLine ):
    vim.current.buffer[i] = newLine

def deleteLine ( i ):
    vim.current.buffer[i] = None

def tabCount():
    return len ( vim.tabpages )

def switchToTab ( i ):
    vim.current.tabpage = vim.tabpages[i]

def bufferNumberOfTab ( i ):
    return vim.tabpages[i].window.buffer.number

def filenameOfTab ( i ):
    return vim.tabpages[i].window.buffer.name

def findLine(lineContent):
    for (i, l) in enumerate(vim.current.buffer):
        if l == lineContent:
            return i

def writeStringToFile ( filename, output ):
    with open(filename, "w") as file:
        file.write(output)

def splitIndentFromText ( line ):
    if not line:
        return ( '', '' )
    i = 0
    while i < len(line) and line[i].isspace():
        i+=1
    return ( line[0:i], line[i:] )

def getCurrentFileList():
    result = [];
    for i in range(0, tabCount()):
        result.append(filenameOfTab(i))
    return " ".join(result)

def appendToCurrentFile(content):
    content = content.splitlines()
    for l in content:
        vim.current.buffer.append(l)

def addLineToSection(sectionMarker, newline):
    sectionEnd = findLine(sectionMarker)
    if sectionEnd != None:
        insertLine(sectionEnd, newline)

def getInput(message = "? "):
    vim.command("call inputsave()")
    vim.command("let python_user_input = input('" + message + "')")
    vim.command("call inputrestore()")
    return vim.eval("python_user_input")

endpython
"}}}
"simple remappings
"{{{

"Navigation shortcuts
inoremap kj <ESC>
nnoremap <leader>, :tabN<CR>
nnoremap <leader>/ :tabn<CR>
nnoremap <leader>q :q<CR>

"Moving tabs left and right
nnoremap <leader>? :tabm +1<CR>
nnoremap <leader><LT> :tabm -1<CR>

"Make d, x delete and forget, make s cut
vnoremap s d
vnoremap d "_d
vnoremap x "_x

nnoremap ss dd
nnoremap s d
nnoremap d "_d
nnoremap x "_x

"Shortcuts for opening and loading vimrc
nnoremap <leader>ve :tabe ~/.vimrc<CR>
nnoremap <leader>vs :source ~/.vimrc<CR>

"execute the current file as a script
nnoremap <leader>r :w<CR>:!./%:t<CR>
nnoremap ; @

"remove all whitespace errors when saving
autocmd BufWritePre * :silent! %s/\(\.*\)\s\+$/\1

"}}}
"Organisational mappings
"{{{
"open a file from the current directory
nnoremap <leader>oi :tabe %:p:h/

"create a new vimproject file with the currently open tabs
nnoremap <leader>op :python writeStringToFile("vimproject.sh", "#!/bin/bash\nvim -p " + getCurrentFileList())<CR>
"}}}
"Remappings specifically for python code
"{{{
python << endpython

def runPythonUnitTests():
    filetype = getFileType()
    if filetype == 'py':
        vim.command("!python test.py")
        return True
    return False
RunUnitTestListeners.append(runPythonUnitTests)

endpython
"}}}
"Remappings specifically for C code
"{{{

python << endpython
def runCPPUnitTests():
    filetype = getFileType()
    if filetype == 'cpp' or filetype == 'hpp':
        vim.command("!make check")
        return True
    return False
RunUnitTestListeners.append(runCPPUnitTests)

def runCheckMemoryTests():
    filetype = getFileType()
    if filetype == 'cpp' or filetype == 'hpp':
        vim.command("!make check_memory")

def createTestFunction():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return
    currentLineNumber = getRow()
    (indent, functionCall) = splitIndentFromText(getLine(currentLineNumber))
    functionDeclaration = "void " + functionCall
    functionBody = "\n" + functionDeclaration.replace(';', '') + "\n{\n    \n}\n"
    addLineToSection("//End Test Declarations", functionDeclaration)
    appendToCurrentFile(functionBody)
    setCursor(currentLineNumber + 1, getCol())

def addFileToIncludes():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return
    currentLineNumber = getRow()
    filename = getInput("Filename to include (including \"\" or <>): ")
    if filename.startswith("\"") and filename.endswith("\""):
        addLineToSection("//End Include Section", "#include " + filename)
    elif filename.startswith("<") and filename.endswith(">"):
        addLineToSection("//End Include Section", "#include " + filename)
    else:
        return
    setCursor(currentLineNumber + 1, getCol())

def expandClassMethod():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return
    className = getLine(0)[2:]
    currentLineNumber = getRow()
    (indent, functionDeclaration) = splitIndentFromText(getLine(currentLineNumber))

    if functionDeclaration[-1] == ';':
        functionDeclaration = functionDeclaration[0:-1]

    firstBracket = functionDeclaration.index('(');
    startOfFunctionName = functionDeclaration[0:firstBracket].rindex(' ') + 1
    if functionDeclaration[startOfFunctionName] == '*':
        startOfFunctionName += 1
    newFunctionLine = functionDeclaration[0:startOfFunctionName] + className + "::" + functionDeclaration[startOfFunctionName:]
    setLine(currentLineNumber, newFunctionLine)
    insertLine(currentLineNumber + 1, "{")
    insertLine(currentLineNumber + 2, "    ")
    insertLine(currentLineNumber + 3, "}")
    setCursor(currentLineNumber + 2, 5)

def createDebugLine():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return
    currentLineNumber = getRow()
    (indent, expression) = splitIndentFromText(getLine(currentLineNumber))
    debugLine = indent + "std::cout << \"" + expression + ": \" << " + expression + " << std::endl; // DEBUG_LINE"
    setLine(currentLineNumber, debugLine)
    setCursor(currentLineNumber, len(indent))

def createPrintLine():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return
    currentLineNumber = getRow()
    (indent, message) = splitIndentFromText(getLine(currentLineNumber))
    debugLine = indent + "std::cout << \"" + message + "\" << std::endl; // DEBUG_LINE"
    setLine(currentLineNumber, debugLine)
    setCursor(currentLineNumber, len(indent))

endpython

" <leader>mm (make check) runs the unit tests
nnoremap <leader>mm :w<CR>:python runCheckMemoryTests()<CR>

" <leader>ct (create test) creates a declaration and function body for the
" function called on the current line. This essentially only works if the
" current line is something like:
" test_that_creating_object_works();
nnoremap <leader>ct :python createTestFunction()<CR>

" output - create a debugging line that outputs the expression on the current
" line
nnoremap <leader>co :python createDebugLine()<CR>

" delete all debugging lines in the current file
nnoremap <leader>cd :%g/^.*\/\/ DEBUG_LINE$/d<CR>

" print - create a debugging line that prints the current line
nnoremap <leader>cp :python createPrintLine()<CR>

nnoremap <leader>c# :python addFileToIncludes()<CR>

nnoremap <leader>cf :python expandClassMethod()<CR>

"}}}
"Remappings applicable to editing any code
"{{{
"functions used in this section {{{
python << endpython
def replaceSpacesWithUnderscores():
    currentLineNumber = getRow()
    (indent, line) = splitIndentFromText(getLine(currentLineNumber))
    setLine(currentLineNumber, indent + line.replace(" ", "_"))

def runUnitTests():
    for runner in RunUnitTestListeners:
        if runner():
            return

endpython


"}}}

" <leader>mc (make check) runs the unit tests
nnoremap <leader>mc :w<CR>:python runUnitTests()<CR>

" <leader>cu replaces spaces in the current line with underscores
nnoremap <leader>cu :python replaceSpacesWithUnderscores()<CR>

" git patch add
nnoremap <leader>gp :!git add -p<CR>
" git add all files
nnoremap <leader>ga :!git add .<CR>
" git status
nnoremap <leader>gs :!git status<CR>
" git commit
nnoremap <leader>gc :!git commit<CR>
"}}}
"Remapping the enter key
"{{{
" Whenever the enter key is hit in insert mode, all the functions in the array
" EnterKeyListeners will be called. Add more functions by appending them to
" this list.
python << endpython

def matchIndentWithPreviousLine():
    lineNumber = getRow()
    (indent, line) = splitIndentFromText(getLine(lineNumber-1))
    if line.startswith("//"):
        return
    newLineContent = getLine(lineNumber)
    setLine(lineNumber, indent + newLineContent)
    setCursor(lineNumber, len(indent))

def addBulletPoint():
    if getFileType() != 'md':
        return
    currentLine = getRow()
    if str(getLine(currentLine - 1)).lstrip().startswith('+'):
        setLine(currentLine, str(getLine(currentLine)) + '+ ')
        setCursor(currentLine, getCol() + 2)

def expandCurlyBrackets():
    if getFileType() != 'cpp' and getFileType() != 'hpp':
        return
    currentLine = getRow()
    if len(getLine(currentLine - 1)) < 1:
        return
    if getLine(currentLine - 1)[-1] == '{':
        insertLine(currentLine + 1, getLine(currentLine) + '}')
        setLine(currentLine, str(getLine(currentLine)) + '    ')
        setCursor(currentLine, getCol() + 5)

EnterKeyListeners = [
    matchIndentWithPreviousLine,
    expandCurlyBrackets,
    addBulletPoint
]

def EmitEnterKeyEvent():
    for l in EnterKeyListeners:
        l()

endpython

inoremap <CR> <CR><C-O>:python EmitEnterKeyEvent()<CR>
"}}}
"Remapping the Tab key
"{{{

python << endpython

def UnindentCurrentLine():
    if getFileType() == 'md':
        currentLine = getRow()
        (indent, text) = splitIndentFromText(getLine(currentLine))
        indent = indent[2:]
        setLine(currentLine, indent + text)
    else:
        currentLine = getRow()
        (indent, text) = splitIndentFromText(getLine(currentLine))
        indent = indent.replace("\t", "    ")
        newIndentLength = int((len(indent) - 1) / 4) * 4
        indent = " " * newIndentLength
        setLine(currentLine, indent + text)
        setCursor(currentLine, getCol() - 4)

ShiftTabKeyListeners = [
    UnindentCurrentLine
]

def EmitShiftTabKeyEvent():
    for l in ShiftTabKeyListeners:
        l()

ColBeforeTab = 0
def indentBulletPoint():
    if getFileType() != 'md':
        return
    currentLine = getRow()
    if str(getLine(currentLine)).lstrip().startswith('+'):
        # Delete any extra spaces that were inserted
        extraSpaceCount = getCol() - ColBeforeTab
        newLineContent = str(getLine(currentLine)[0:ColBeforeTab]) + str(getLine(currentLine)[getCol():])
        setLine(currentLine, '  ' + str(newLineContent))
        setCursor(currentLine, getCol() - extraSpaceCount + 2)

TabKeyListeners = [
    indentBulletPoint,
]
def EmitTabKeyEvent():
    for l in TabKeyListeners:
        l()

def saveCol():
    global ColBeforeTab
    ColBeforeTab = getCol()

BeforeTabKeyListeners = [
    saveCol
]
def EmitBeforeTabKeyEvent():
    for l in BeforeTabKeyListeners:
        l()


endpython

inoremap <TAB> <C-O>:python EmitBeforeTabKeyEvent()<CR><TAB><C-O>:python EmitTabKeyEvent()<CR>
inoremap <S-TAB> <C-O>:python EmitShiftTabKeyEvent()<CR>
"}}}
