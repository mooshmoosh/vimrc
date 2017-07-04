"Preliminiaries. Set up core vim settings
"{{{

syntax enable
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
set foldmethod=marker
set number
set wrap
set linebreak
setlocal nospell spelllang=en_au
set iskeyword=@,48-57,_,192-255,#
colorscheme desert
filetype plugin on
let mapleader = ","

"}}}
"Python set up. Mainly my wrapper around Vim API
"{{{
python3 << endpython3
import vim
import os
import re
import requests
import json

# This contains a list of functions that each check if the file being edited is a particular type
# If it is a certain type, then the unit tests will be run, and the function returns true, other wise
# the function returns false. When the keyboard shortcut is triggered, a function itterates over this list
# looking for the first function that returns true
RunUnitTestListeners = []

# Similarly, this is a list of functions that will add includes for various languages
addIncludeListeners = []

# This is the list of functions that will comment the current line in various languages
commentLineListeners = []

# This is the list of functions that take the current line to be a
# variable, and replace it with a line outputting the contents of the
# variable to stdout or a log file
createDebugLineListeners = []

# Similar to createDebugLineListeners, except these just print messages, not variables
createPrintLineListeners = []

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

def getLines(i,j):
    return vim.current.buffer[i:j]

def getFilename():
    return vim.current.buffer.name

def getChar(i,j):
    return vim.current.buffer[i][j]

def insertLine ( i, newLine ):
    vim.current.buffer.append(newLine, i)

def insertLines ( i, newLines ):
    for line in newLines:
        vim.current.buffer.append(line, i)
        i += 1

def insertText(i, text):
    """Like insert lines, but takes a single (possibly multiline)
    string."""
    for line in text.split('\n'):
        vim.current.buffer.append(line, i)
        i += 1

def appendText(text):
    vim.current.buffer.append(text.split('\n'))

def newTab(initial_text="", tabname=""):
    vim.command('tabedit ' + tabname)
    appendText(initial_text)
    deleteLine(0)

def setLine(i, newLine):
    vim.current.buffer[i] = newLine

def setLines(i, j, newLines):
    for lineNumber in range(i,j):
        vim.current.buffer[lineNumber] = newLines[lineNumber - i]

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

def findFirstLineStartingWith(beginnings):
    for (i, l) in enumerate(vim.current.buffer):
        for beginning in beginnings:
            if l.startswith(beginning):
                return i
    return 0

def linesExist(lines):
    for bufferLineNumber in range(0, len(vim.current.buffer) - len(lines) + 1):
        for lineNumber, line in enumerate(lines):
            if line != vim.current.buffer[bufferLineNumber + lineNumber]:
                break
        else:
            return True
    return False

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
    vim.command("let python3_user_input = input('" + message + "')")
    vim.command("call inputrestore()")
    return vim.eval("python3_user_input")

endpython3
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

"Window related mappings
nnoremap <leader>ws <C-W>v
nnoremap <leader>wv <C-W>s

"Make d, x delete and forget, make s cut
vnoremap s "+d
vnoremap d "_d
vnoremap x "_x

nnoremap s "+d
nnoremap ss "+dd
nnoremap d "_d
nnoremap x "_x

"Use the system clipboard when copying and pasting
nnoremap y "+y
vnoremap y "+y
nnoremap yy "+yy
nnoremap p "+p
vnoremap p "+p
nnoremap P "+P
vnoremap P "+P

"Shortcuts for opening and loading vimrc
nnoremap <leader>ve :tabe ~/.config/nvim/init.vim<CR>
nnoremap <leader>vs :source ~/.config/nvim/init.vim<CR>

nnoremap ; @

"remove all whitespace errors when saving
autocmd BufWritePre * :silent! %s/\(\.*\)\s\+$/\1

"}}}
"Organisational mappings
"{{{
"open a file from the current directory
nnoremap <leader>oi :tabe %:p:h/

"open a file from the current directory in a splitwindow
nnoremap <leader>os :vsplit %:p:h/

"Change the current directory to the directory containing the current file
nnoremap <leader>od :chdir %:p:h<CR>

"create a new vimproject file with the currently open tabs
nnoremap <leader>op :python3 writeStringToFile("vimproject.sh", "#!/bin/bash\nvim -p " + getCurrentFileList())<CR>:!chmod +x vimproject.sh<CR><CR>
"}}}
"Remappings specifically for python3 code
"{{{
python3 << endpython3

def runPythonUnitTests():
    filetype = getFileType()
    if filetype == 'py':
        if os.path.isfile("manage.py"):
            # If manage.py exists in the current directory, then this is a django project
            vim.command("!python33 manage.py test")
        else:
            vim.command("!python33 -m unittest discover")
        return True
    return False
RunUnitTestListeners.append(runPythonUnitTests)

def addPythonImport():
    filetype = getFileType()
    if filetype != 'py' and getLine(0) != "#!/usr/bin/python33":
        return False
    moduleName = getInput("Name of module: ")
    importSectionBeginning = findFirstLineStartingWith(['import', 'from'])
    if ' from ' in moduleName:
        fromIndex = moduleName.index(' from ')
        parentModuleIndex = fromIndex + len(' from ')
        parentModuleName = moduleName[parentModuleIndex:]
        moduleName = moduleName[:fromIndex]
        insertLine(importSectionBeginning, "from " + parentModuleName + " import " + moduleName)
    else:
        insertLine(importSectionBeginning, "import " + moduleName)
    setCursor(getRow() + 1, getCol())
    return True
addIncludeListeners.append(addPythonImport)

def commentCurrentLinePython():
    filetype = getFileType()
    if filetype != 'py':
        return False
    currentLineNumber = getRow()
    currentIndent, currentLine = splitIndentFromText(getLine(currentLineNumber))
    if currentLine.strip()[0] == '#':
        setLine(getRow(), currentIndent + currentLine[1:])
    else:
        setLine(getRow(), currentIndent + '#' + currentLine)
    return True
commentLineListeners.append(commentCurrentLinePython)

def createPythonDebugLine():
    filetype = getFileType()
    if filetype != 'py':
        return False
    currentLineNumber = getRow()
    currentIndent, currentLine = splitIndentFromText(getLine(currentLineNumber))
    if os.path.isfile("manage.py"):
        # If manage.py exists in the current directory, then this is a django project
        # We use the debugging function in django projects
        if linesExist(["import logging", "logger = logging.getLogger('development')"]):
            setLine(currentLineNumber, currentIndent + "logger.debug(\"" + currentLine +  ": \" + str(" + currentLine + "))")
            setCursor(getRow(), len(currentIndent))
        else:
            # The logging library hasn't been imported, so import it
            importSectionBeginning = findFirstLineStartingWith(['import', 'from'])
            insertLine(importSectionBeginning, "logger = logging.getLogger('development')")
            insertLine(importSectionBeginning, "import logging")
            setCursor(getRow() + 2, len(currentIndent))
            setLine(getRow(), currentIndent + "logger.debug(\"" + currentLine +  ": \" + str(" + currentLine + "))")
    else:
        # otherwise we just print to stdout
        setLine(currentLineNumber, currentIndent + "print(\"" + currentLine +  ": \" + str(" + currentLine + "))")
        setCursor(getRow(), len(currentIndent))
createDebugLineListeners.append(createPythonDebugLine)

def createPythonPrintLine():
    filetype = getFileType()
    if filetype != 'py':
        return
    (indent, message) = splitIndentFromText(getLine(getRow()))
    if os.path.isfile("manage.py"):
        if linesExist(["import logging", "logger = logging.getLogger('development')"]):
            debugLine = indent + "logger.debug(\"" + message + "\")"
        else:
            # The logging library hasn't been imported, so import it
            importSectionBeginning = findFirstLineStartingWith(['import', 'from'])
            insertLine(importSectionBeginning, "logger = logging.getLogger('development')")
            insertLine(importSectionBeginning, "import logging")
            setCursor(getRow() + 2, len(indent))
            debugLine = indent + "logger.debug(\"" + message + "\")"
    else:
        debugLine = indent + "print(\"" + message + "\")"
    setLine(getRow(), debugLine)
    setCursor(getRow(), len(indent))
createPrintLineListeners.append(createPythonPrintLine)

endpython3
"}}}
"Remappings specifically for C code
"{{{

python3 << endpython3
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

def addFileToCIncludes():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return False
    currentLineNumber = getRow()
    filename = getInput("Filename to include (including \"\" or <>): ")
    if filename.startswith("\"") and filename.endswith("\""):
        addLineToSection("//End Include Section", "#include " + filename)
    elif filename.startswith("<") and filename.endswith(">"):
        addLineToSection("//End Include Section", "#include " + filename)
    else:
        return
    setCursor(currentLineNumber + 1, getCol())
addIncludeListeners.append(addFileToCIncludes)

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

def createCPPDebugLine():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return
    currentLineNumber = getRow()
    (indent, expression) = splitIndentFromText(getLine(currentLineNumber))
    debugLine = indent + "std::cout << \"" + expression + ": \" << " + expression + " << std::endl; // DEBUG_LINE"
    setLine(currentLineNumber, debugLine)
    setCursor(currentLineNumber, len(indent))
createDebugLineListeners.append(createCPPDebugLine)

def createCPPPrintLine():
    filetype = getFileType()
    if filetype != 'cpp' and filetype != 'hpp':
        return
    currentLineNumber = getRow()
    (indent, message) = splitIndentFromText(getLine(currentLineNumber))
    debugLine = indent + "std::cout << \"" + message + "\" << std::endl; // DEBUG_LINE"
    setLine(currentLineNumber, debugLine)
    setCursor(currentLineNumber, len(indent))
createPrintLineListeners.append(createCPPPrintLine)

endpython3

" <leader>mm (make check) runs the unit tests
nnoremap <leader>mm :w<CR>:python3 runCheckMemoryTests()<CR>

" <leader>ct (create test) creates a declaration and function body for the
" function called on the current line. This essentially only works if the
" current line is something like:
" test_that_creating_object_works();
nnoremap <leader>ct :python3 createTestFunction()<CR>

" delete all debugging lines in the current file
nnoremap <leader>cd :%g/^.*\/\/ DEBUG_LINE$/d<CR>

nnoremap <leader>cf :python3 expandClassMethod()<CR>

"}}}
"Remappings specifically for javascript code
"{{{
python3 << endpython3
def createJavascriptPrintLine():
    filetype = getFileType()
    if filetype != 'js':
        return
    (indent, message) = splitIndentFromText(getLine(getRow()))
    debugLine = indent + "console.log(\"" + message + "\");"
    setLine(getRow(), debugLine)
    setCursor(getRow(), len(indent))
createPrintLineListeners.append(createJavascriptPrintLine)

def createJavascriptDebugLine():
    filetype = getFileType()
    if filetype != 'js':
        return
    (indent, currentLine) = splitIndentFromText(getLine(getRow()))
    debugLine = indent + "console.log(\"" + currentLine + ": \" + " + currentLine + ");"
    setLine(getRow(), debugLine)
    setCursor(getRow(), len(indent))
createDebugLineListeners.append(createJavascriptDebugLine)

endpython3
"}}}
"Remappings applicable to editing any code
"{{{
"functions used in this section
python3 << endpython3
def replaceSpacesWithUnderscores():
    currentLineNumber = getRow()
    (indent, line) = splitIndentFromText(getLine(currentLineNumber))
    setLine(currentLineNumber, indent + line.replace(" ", "_"))

def runUnitTests():
    for runner in RunUnitTestListeners:
        if runner():
            return

def addToIncludes():
    for adder in addIncludeListeners:
        if adder():
            return

def commentCurrentLine():
    for commenter in commentLineListeners:
        if commenter():
            return

def createDebugLine():
    for listener in createDebugLineListeners:
        if listener():
            return

def createPrintLine():
    for listener in createPrintLineListeners:
        if listener():
            return


def zipSpecifiedLines(firstLine, count, sections):
    oldLines = getLines(firstLine, firstLine + sections * count)
    newLines = []
    for lineNumber in range(0, count):
        for sectionNumber in range(0, sections):
            newLines.append(oldLines[lineNumber + sectionNumber * count])
    setLines(firstLine, firstLine + sections * count, newLines)

def zipLines():
    args = getInput("How many lines should be zipped? ")
    if ',' in args:
        args = args.split(',')
        count = args[0]
        sections = args[1]
    else:
        sections = 2
        count = args
    zipSpecifiedLines(getRow(), int(count), int(sections))

def indentTill():
    finalLineNumber = getInput("Indent all lines till which line number (negative indicates unindent)? ")
    finalLineNumber = int(finalLineNumber)
    indent = True
    if finalLineNumber < 0:
        indent = False
        finalLineNumber = -finalLineNumber
    oldLines = getLines(getRow(), finalLineNumber)
    newLines = []
    if indent:
        for line in oldLines:
            newLines.append(" " * 4 + line)
    else:
        for line in oldLines:
            newLines.append(line[4:])
    setLines(getRow(), finalLineNumber, newLines)

def executeCurrentFileAsScript():
    filetype = getFileType()
    if filetype == "html":
        vim.command("!firefox %")
    else:
        vim.command("!" + getFilename())

def splitWords(text, max_length):
    words = text.split(' ')
    length = len(words[0])
    word_count = 1
    while length < max_length:
        length += len(words[word_count]) + 1
        word_count += 1
    word_count -= 1
    result = ' '.join(words[:word_count])
    return result, text[len(result):].strip()

def splitCurrentLineIntoParagraphs():
    current_line_number = getRow()
    current_line = getLine(current_line_number)
    new_lines = []
    (indent, remaining_text) = splitIndentFromText(current_line)
    if remaining_text.startswith('// '):
        remaining_text = remaining_text[3:]
        indent += "// "
    while len(remaining_text) + len(indent) > 72:
        new_line, remaining_text = splitWords(remaining_text, 72 - len(indent))
        new_lines.append(indent + new_line)
    new_lines.append(indent + remaining_text)
    deleteLine(current_line_number)
    insertLines(current_line_number, new_lines)

endpython3

" ensure the current line is no more than 72 characters long
nmap <leader>le :python3 splitCurrentLineIntoParagraphs()<CR>

" <leader>mc (make check) runs the unit tests
nnoremap <leader>mc :w<CR>:python3 runUnitTests()<CR>

" <leader>cu replaces spaces in the current line with underscores
nnoremap <leader>cu :python3 replaceSpacesWithUnderscores()<CR>

" git patch add
nnoremap <leader>gp :!git add -p<CR>
" git add all files
nnoremap <leader>ga :!git add .<CR>
" git status
nnoremap <leader>gs :!git status<CR>
" git commit
nnoremap <leader>gc :!git commit<CR>
" git diff
nnoremap <leader>gd :!git diff<CR>
" git blame on current file
nnoremap <leader>gb :!git blame %<CR>

"Add an include/import
nnoremap <leader>c# :python3 addToIncludes()<CR>

" alternate between the nth line and the (n + count)th line
nnoremap <leader>cz :python3 zipLines()<CR>

" indent all lines till a specified line number
nnoremap <leader>ci :python3 indentTill()<CR>

" comment out the current line
nnoremap <leader>cc :python3 commentCurrentLine()<CR>

" output - create a debugging line that outputs the expression on the current
" line
nnoremap <leader>co :python3 createDebugLine()<CR>

" print - create a debugging line that prints the current line
nnoremap <leader>cp :python3 createPrintLine()<CR>

" Format List - used to put a comma separated list of values on individual
" lines
nmap <leader>fl f,wi<CR><ESC>

"execute the current file as a script
nnoremap <leader>r :w<CR>:python3 executeCurrentFileAsScript()<CR>
"}}}
"Remapping the enter key
"{{{
" Whenever the enter key is hit in insert mode, all the functions in the array
" EnterKeyListeners will be called. Add more functions by appending them to
" this list.
python3 << endpython3

def matchIndentWithPreviousLine():
    lineNumber = getRow()
    (indent, line) = splitIndentFromText(getLine(lineNumber-1))
    if line.startswith("//") or line.startswith(' *') or line.startswith('/*'):
        return
    newLineContent = getLine(lineNumber)
    setLine(lineNumber, indent + newLineContent)
    setCursor(lineNumber, len(indent))

def extendCommentBlock():
    lineNumber = getRow()
    (indent, line) = splitIndentFromText(getLine(lineNumber-1))
    if line.startswith('//'):
        newLineContent = getLine(lineNumber)
        setLine(lineNumber, indent + '// ')
        setCursor(lineNumber, len(indent) + 3)
    elif not (line.startswith('*') or line.startswith('/*')):
        return
    elif '*/' in line:
        return
    else:
        if line.startswith('/'):
            indent += ' '
        newLineContent = getLine(lineNumber)[4:]
        setLine(lineNumber, indent + '* ' + newLineContent)
        setCursor(lineNumber, len(indent) + 3)

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

def expandHtmlTag():
    if getFileType() != 'html':
        return
    currentLineNumber = getRow() - 1
    currentLine = getLine(currentLineNumber)
    indent, lineContent = splitIndentFromText(currentLine)
    r = re.compile(r'<([^\s\/]+)\s*[^>]*>$')
    matches = [m for m in re.finditer(r, currentLine)]
    if len(matches) == 0:
        return
    match = matches[-1]
    if match.endpos == len(currentLine):
        insertLine(currentLineNumber + 2, indent + "</" + match.group(1) + ">")
    newLineContent = getLine(getRow())
    setLine(currentLineNumber + 1, "    " + newLineContent)
    setCursor(currentLineNumber + 1, len(newLineContent) + 4)

PreEnterKeyListeners = [
]

def EmitPreEnterKeyEvent():
    for l in PreEnterKeyListeners:
        l()

EnterKeyListeners = [
    matchIndentWithPreviousLine,
    extendCommentBlock,
    expandCurlyBrackets,
    addBulletPoint,
    expandHtmlTag
]

def EmitEnterKeyEvent():
    for l in EnterKeyListeners:
        l()

endpython3

inoremap <CR> <C-O>:python3 EmitPreEnterKeyEvent()<CR><CR><C-O>:python3 EmitEnterKeyEvent()<CR>
"}}}
"Remapping the Tab key
"{{{

python3 << endpython3

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

endpython3

inoremap <TAB> <C-O>:python3 EmitBeforeTabKeyEvent()<CR><TAB><C-O>:python3 EmitTabKeyEvent()<CR>
inoremap <S-TAB> <C-O>:python3 EmitShiftTabKeyEvent()<CR>
"}}}
"Remappings for CSV files
"{{{
autocmd FileType csv nnoremap o :NewRecord<CR>
"}}}
"custom commands (python3 functions)
"{{{
" This lets me use python functions like editor commands so they don't need to
" start with a capital letter.
nnoremap <leader>pr :python3 executePythonFunction()<CR>

python3 << endpython3
def executePythonFunction():
    command = getInput(":")
    command = command.split(' ', 1)
    if len(command) == 0:
        return
    if len(command) > 1:
        argument = repr(command[1].strip())
    else:
        argument = ''
    command = command[0]
    # This line ensures output of the command appears on the next line.
    # Not the same line as the ":commandname"
    print(" ")
    vim.command("python3 " + command + "(" + argument + ")")

def testcommand(argument=""):
    print("It worked!")

endpython3
"}}}