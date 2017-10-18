"Preliminiaries. Set up core vim settings
"{{{

syntax on
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab
set foldmethod=marker
set number
set wrap
set linebreak
set nohlsearch
set hidden
setlocal nospell spelllang=en_au
set iskeyword=@,48-57,_,192-255,#
filetype plugin on
let mapleader=","
hi MatchParen ctermbg=1 guibg=lightblue
let $IN_NVIM_TERMINAL="YES"
"}}}
" vim-plug setup
"{{{
call plug#begin('~/.config/nvim/plugged')

" A better file browser
Plug 'scrooloose/nerdtree'
" fuzzy searching
Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
" Highligh the corresponding html tag
Plug 'valloric/MatchTagAlways'
" This lets leader% jump to the corresponding tag, similarly to how % works on
" brackets
nnoremap <leader>% :MtaJumpToOtherTag<cr>
"csv plugin
Plug 'chrisbra/csv.vim'
" beautifiers for json and xml
Plug 'xni/vim-beautifiers'
" grepping files
Plug 'mhinz/vim-grepper'
" Allows organising notes and todos in markdown files that are linked
Plug 'vimwiki/vimwiki'
" A calendar plugin for wiki
Plug 'mattn/calendar-vim'
" Displays the new/modified lines with git in real time
Plug 'airblade/vim-gitgutter'
let g:gitgutter_diff_args = '--patience'
" Allows for aligining of text at specified characters
Plug 'junegunn/vim-easy-align'
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
" A powerline - decide what I want it for first
" You can specify a function and have its output inserted into the status bar
" at the bottom.
" Plug 'itchyny/lightline.vim'
" dispatch lets you run jobs/builds in the background asynchronously.
Plug 'tpope/vim-dispatch'
" scratchpad lets you run python in real time
Plug 'metakirby5/codi.vim'
let g:codi#interpreters = {
       \ 'python': {
           \ 'bin': 'python3',
           \ 'prompt': '^\(>>>\|\.\.\.\) ',
           \ },
       \ }
Plug 'marcweber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
Plug 'jeetsukumaran/vim-buffergator'
" <leader>b should open/close the buffer menu, not just open it
nnoremap <leader>b :BuffergatorToggle<CR>
Plug 'tpope/vim-jdaddy'

call plug#end()
"}}}
"Python set up. Mainly my wrapper around Vim API
"{{{
python3 << endpython3
import vim
import os
import re
import requests
import json
import subprocess

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

def currentTabWindowCount():
    return len(vim.current.tabpage.windows)

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

def newBuffer(initial_text=""):
    vim.command('enew')
    appendText(initial_text)
    deleteLine(0)

def setLine(i, newLink):
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

def NerdtreeIsOpen():
    if "NERD_tree" in vim.current.buffer.name:
        # This only checks if NERDtree is open in a window somewhere else
        # in the current tab. If the current window is the nerdtree one then
        # nerd tree is not open in the sense of being in another window
        return False
    buffer_names = [window.buffer.name for window in vim.current.tabpage.windows]
    for name in buffer_names:
        if "NERD_tree" in name:
            return True
    return False

def switchToAlternativeOrNextBuffer():
    try:
        vim.command(':b#')
    except:
        vim.command(':bnext')

def quitCurrentBuffer(force=False):
    filename = getFilename()
    current_buffer = str(vim.current.window.buffer.number)
    if filename == "" or filename.startswith('term://'):
        quit_command = ":bdelete! " + current_buffer
    else:
        if force:
            quit_command = ":bdelete! " + current_buffer
        else:
            quit_command = ":bdelete " + current_buffer
    window_count = currentTabWindowCount()
    if window_count > 1 and not NerdtreeIsOpen():
        vim.command(':quit')
    elif window_count > 2:
        vim.command(':quit')
    else:
        try:
            switchToAlternativeOrNextBuffer()
            vim.command(quit_command)
        except:
            vim.command(':b#')
            print("This buffer has been modified!")

def findBufferWithName(starts_with, contains=None):
    for buf in vim.buffers:
        if buf.name.startswith(starts_with):
            if contains is None or contains in buf.name:
                return buf

def switchToBufferWithName(name_starts_with, fallback=None, name_contains=None):
    buffer_object = findBufferWithName(name_starts_with, contains=name_contains)
    if buffer_object is None:
        vim.command("edit " + str(fallback))
    else:
        vim.command("b" + str(buffer_object.number))

def launchFirefoxAndSearch():
    search_term = getInput("Search duck duck go for: ")
    search_url = search_term.replace(' ', '+')
    if search_url == '':
        return
    vim.command('!firefox "https://duckduckgo.com/?q=' + search_url + '"')

endpython3
"}}}
"simple remappings
"{{{

"Navigation shortcuts
inoremap kj <ESC>
nnoremap <leader>, :bN<CR>
nnoremap <leader>/ :bn<CR>
nnoremap <leader>. :b#<CR>
nnoremap <leader>q :python3 quitCurrentBuffer()<CR>
nnoremap <leader>wq :w<CR>:python3 quitCurrentBuffer()<CR>
nnoremap !<leader>q :python3 quitCurrentBuffer(force=True)<CR>

" Open the grepper
nnoremap <leader>gg :Grepper<CR>

" I'm not sure what ctrl-W in insert mode is supposed to do, but I often
" accidently forget I'm in insert mode, want to switch to another window and
" hit ctrl-W. it deletes the last couple of words I just typed. So this makes
" it escape insert mode and behave like normal mode ctrl-W
inoremap <C-w> <ESC><C-w>

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
nnoremap <leader>ve :edit ~/.config/nvim/init.vim<CR>
nnoremap <leader>vs :source ~/.config/nvim/init.vim<CR>

nnoremap ; @

"remove all whitespace errors when saving
autocmd BufWritePre * :silent! %s/\(\.*\)\s\+$/\1

" <leader>tt opens / switches to a terminal.
nnoremap <leader>tt :python3 switchToBufferWithName('term:', 'term:///bin/bash', '/bin/bash')<CR>A
" <leader>tp opens / switches to a new terminal with python prompt
nnoremap <leader>tp :python3 switchToBufferWithName('term:', 'term:///usr/bin/python3', '/usr/bin/python3')<CR>A
nnoremap <leader>tn :edit term://bash<CR>A
" Similarly, but split window
nnoremap <leader>tw :vsplit term://bash<CR>
"ctrl kj in terminal should take me to normal mode
tnoremap <C-k><C-j> <C-\><C-n>
"Ctrl W should still work to move windows in terminal mode
tnoremap <C-w> <C-\><C-n><C-w>

nnoremap <leader>fs :python3 launchFirefoxAndSearch()<CR>

" It is really annoying to have spelling checker on all the time, but I like
" to use it occasionally.
nnoremap <leader>ss :set invspell<CR>

"}}}
"Organisational mappings
"{{{
"open a file from the current directory
nnoremap <leader>oi :edit %:p:h/

"open a file that is already open. This shows the open buffers and gets ready
"to recieve a numbered buffer to switch to.
nnoremap <leader>oo :ls<CR>:b

"open a new file
nnoremap <leader>on :enew<CR>

"open the directory tree
nnoremap <leader>nt :NERDTreeToggle<CR>

"open a file from the current directory in a splitwindow
nnoremap <leader>oh :vsplit %:p:h/

"Change the current directory to the directory containing the current file
nnoremap <leader>od :chdir %:p:h<CR>

"}}}
"Remappings specifically for python3 code
"{{{
python3 << endpython3

def runPythonUnitTests():
    filetype = getFileType()
    if filetype == 'py':
        if os.path.isfile("manage.py"):
            # If manage.py exists in the current directory, then this is a django project
            runShellCommandIntoNewBuffer("python3 manage.py test")
        else:
            runShellCommandIntoNewBuffer("python3 -m unittest discover")
        return True
    return False
RunUnitTestListeners.append(runPythonUnitTests)

def addPythonImport():
    filetype = getFileType()
    if filetype != 'py' and getLine(0) != "#!/usr/bin/python3":
        return False
    moduleName = getInput("Name of module: ")
    if moduleName.strip() == "":
        # We don't do anything, but we've still handled the request to add
        # an import, so we return True
        return True
    importSectionBeginning = findFirstLineStartingWith(['import', 'from'])
    if ' from ' in moduleName:
        fromIndex = moduleName.index(' from ')
        parentModuleIndex = fromIndex + len(' from ')
        parentModuleName = moduleName[parentModuleIndex:]
        moduleName = moduleName[:fromIndex]
        insertLine(importSectionBeginning, "from " + parentModuleName + " import " + moduleName)
    else:
        insertLine(importSectionBeginning, "import " + moduleName)
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

def generateCTagsFile():
    filetype = getFileType()
    if filetype == 'py':
        extensions = ['.py']
        command = ['/usr/bin/ctags', '--python-kinds=-i', '-f', 'tags', '-L', '-']
    elif filetype in ['c', 'h']:
        extensions = ['.h', '.c']
        command = ['/usr/bin/ctags', '-f', 'tags', '-L', '-']
    sourcefiles = []
    for root, directories, files in os.walk('.'):
        for filename in files:
            for extension in extensions:
                if filename.endswith(extension):
                    sourcefiles.append(os.path.join(root, filename))
                    break
    pipeStringToCommand("\n".join(sourcefiles), command)

endpython3

" generate a ctags file for the python files in the current directory
nnoremap <leader>cg :python3 generateCTagsFile()<CR>

"}}}
"Remappings specifically for C code
"{{{

python3 << endpython3
def runCPPUnitTests():
    filetype = getFileType()
    if filetype in ['cpp', 'hpp', 'c', 'h']:
        runShellCommandIntoNewBuffer("make check")
        return True
    return False
RunUnitTestListeners.append(runCPPUnitTests)

def runCheckMemoryTests():
    filetype = getFileType()
    if filetype in ['cpp', 'hpp', 'c', 'h']:
        runShellCommandIntoNewBuffer("make check_memory")
        return True
    return False

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

# This decorator makes any function magically asyncronous
def vim_async(inner_function):
    def wrapper(*args, **kwargs):
        return vim.async_call(inner_function, *args, **kwargs)
    return wrapper

@vim_async
def executeCurrentFileAsScript():
    filetype = getFileType()
    if filetype == "html":
        vim.command("!firefox %")
    else:
        vim.command("!" + getFilename())

@vim_async
def runShellCommandIntoNewBuffer(command):
    with subprocess.Popen([command], stderr=subprocess.PIPE, stdout=subprocess.PIPE, shell=True) as p:
        result = p.stdout.read().decode()
        result += "\n"
        result += p.stderr.read().decode()
    newBuffer(initial_text=result)

def executeCurrentScriptIntoNewBuffer():
    if getLine(0).startswith('#!'):
        # get the environment from shebang
        environment = getLine(0)[2:]
    else:
        print("No shebang found")
        return
    with subprocess.Popen([environment, getFilename()], stderr=subprocess.PIPE, stdout=subprocess.PIPE) as p:
        result = p.stdout.read().decode()
        result += "\n"
        result += p.stderr.read().decode()
    newBuffer(initial_text=result)

def pipeStringToCommand(data, command):
    if isinstance(command, str):
        command = [command]
    with subprocess.Popen(command, stdin=subprocess.PIPE, stderr=subprocess.STDOUT, stdout=subprocess.PIPE) as p:
        result = p.communicate(input=data.encode())[0].decode()
    return result

def splitWords(text, max_length):
    words = text.split(' ')
    length = len(words[0])
    word_count = 1
    while length < max_length and word_count < len(words):
        length += len(words[word_count]) + 1
        word_count += 1
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
    elif remaining_text.startswith('# '):
        remaining_text = remaining_text[2:]
        indent += "# "
    elif remaining_text.startswith('* '):
        # The text should be indented assuming the bullet point isn't there
        # But the first line should still have the bullet point
        remaining_text = remaining_text[2:]
        new_line, remaining_text = splitWords(remaining_text, 72 - len(indent))
        new_lines.append(indent + "* " + new_line)
        indent += "  "
    while len(remaining_text) + len(indent) > 72:
        new_line, remaining_text = splitWords(remaining_text, 72 - len(indent))
        new_lines.append(indent + new_line)
    if len(remaining_text.strip()) > 0:
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

" git patch add -> open a file to hold the commit message, and
" next to it a terminal window running git patch add
nnoremap <leader>gp :edit commitmsg<CR>:vsplit term:///bin/bash<CR>Agit add -p<CR>
" git add all files
nnoremap <leader>ga :!git add .<CR>
" git status
nnoremap <leader>gs :!git status<CR>
" git commit
nnoremap <leader>gc :!git commit<CR>
" git diff
nnoremap <leader>gd :vsplit term:///bin/bash<CR>Agit diff<CR>
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
nnoremap <leader>r :w<CR>:python3 executeCurrentScriptIntoNewBuffer()<CR>
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
    if getFileType() not in ['cpp', 'hpp', 'json', 'py']:
        return
    currentLine = getRow()
    if len(getLine(currentLine - 1)) < 1:
        return
    if getLine(currentLine - 1)[-1] == '{':
        insertLine(currentLine + 1, getLine(currentLine) + '}')
        setLine(currentLine, str(getLine(currentLine)) + '    ')
        setCursor(currentLine, getCol() + 5)

PreEnterKeyListeners = [
]

def EmitPreEnterKeyEvent():
    for l in PreEnterKeyListeners:
        l()

EnterKeyListeners = [
    matchIndentWithPreviousLine,
    extendCommentBlock,
    expandCurlyBrackets,
    addBulletPoint
]

def EmitEnterKeyEvent():
    for l in EnterKeyListeners:
        l()

endpython3

"commented out because I think it clashes with extenstions
"inoremap <CR> <C-O>:python3 EmitPreEnterKeyEvent()<CR><CR><C-O>:python3 EmitEnterKeyEvent()<CR>
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

"inoremap <TAB> <C-O>:python3 EmitBeforeTabKeyEvent()<CR><TAB><C-O>:python3 EmitTabKeyEvent()<CR>
"inoremap <S-TAB> <C-O>:python3 EmitShiftTabKeyEvent()<CR>
"}}}
"Remappings for CSV files
"{{{
autocmd FileType csv nnoremap o :NewRecord<CR>
autocmd FileType csv :%CSVArrangeColumn
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
"Configure personal wiki
"{{{
let g:vimwiki_list = [{'path': '~/Documents/Notes/vimwiki', 'syntax': 'markdown', 'ext': '.md'}]

" Open the calendar
nnoremap <leader>wc :Calendar<CR>
"}}}
