"Preliminiaries. Set up core vim settings
""{{{",

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
set mouse=a
setlocal nospell spelllang=en_au
set iskeyword=@,48-57,_,192-255,#
filetype plugin on
let mapleader=","
let maplocalleader=" "
hi MatchParen ctermbg=1 guibg=lightblue
let $IN_NVIM_TERMINAL="YES"
au CursorHold,CursorHoldI * checktime
" need to set python explicitly
let g:python3_host_prog="/usr/bin/python3"
"}}}
" vim-plug setup
"{{{
call plug#begin('~/.config/nvim/plugged')
" A better file browser
Plug 'scrooloose/nerdtree'
" fuzzy searching
Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
let g:ctrlp_follow_symlinks = 1
" Highligh the corresponding html tag
Plug 'valloric/MatchTagAlways'
" This lets leader% jump to the corresponding tag, similarly to how % works on
" brackets
nnoremap <leader>% :MtaJumpToOtherTag<cr>
"csv plugin
"Plug 'chrisbra/csv.vim'
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
"let g:gitgutter_diff_args = '--patience'
" Allows for aligining of text at specified characters
Plug 'junegunn/vim-easy-align'
" Start interactive EasyAlign in visual mode (e.g. vipga)
" align all occurances of a character with gaip*
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
"Plug 'garbas/vim-snipmate'
Plug 'jeetsukumaran/vim-buffergator'
" <leader>b should open/close the buffer menu, not just open it
nnoremap <leader>b :BuffergatorToggle<CR>
Plug 'tpope/vim-jdaddy'
Plug 'idanarye/vim-vebugger'
Plug 'Shougo/vimproc.vim', {'do' : 'make'}
" Plug 'vim-scripts/todo-txt.vim'
" Commented the following out because it overloads the <leader>b shortcut
" which leads to a slight delay when opening buffergator. A delay I don't have
" time for!
"Plug 'christianrondeau/vim-base64'

" Plugin for handling orgmode files. There is a nice app on my phone that used
" the orgmode format.
Plug 'jceb/vim-orgmode'
" This is required for orgmode
Plug 'tpope/vim-speeddating'

" language server protocol support
"Plug 'prabirshrestha/vim-lsp'
"Plug 'mattn/vim-lsp-settings'

" Jedi is an alternative language server
Plug 'davidhalter/jedi-vim'

"Black code formatting
Plug 'psf/black'
"let g:black_linelength =
"if $ENVIRONMENT_COMPUTER == "HOME"
"    autocmd BufWritePre *.py :Black
"endif
"command! Black python3 runBlack()
autocmd BufWritePre *.py :Black

" Syntastic
Plug 'vim-syntastic/syntastic'

"Rust plugin
Plug 'rust-lang/rust.vim'
let g:rustfmt_autosave = 1

call plug#end()
"}}}
"Python set up. Mainly my wrapper around Vim API
"{{{
python3 << endpython3
import vim
import neovim
import os
import re
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

def getLineCount():
    return len(vim.current.buffer)

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

def setClipboard(value):
    value = value.replace('\\', '\\\\')
    value = value.replace('"', '\\"')
    vim.command('let @+="' + value + '"')

def getClipboard():
    return vim.eval('@+')

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

def addLineToSectionByPrefix(line_prefix, newline):
    """
    Find the section of the current file where all lines start with `prefix`.
    Add `newline` just after that section. This is used to add another include
    line to the top of the file in C. The include section is characterised
    by lines that start with '#include'.
    """
    in_section = False
    for line_number, line in enumerate(vim.current.buffer):
        if line.startswith(line_prefix):
            in_section = True
        else:
            if in_section:
                insertLine(line_number, newline)
                return

def getInput(message = "? "):
    vim.command("call inputsave()")
    vim.command("let python3_user_input = input('" + message + "')")
    vim.command("call inputrestore()")
    return vim.eval("python3_user_input")

def NerdtreeIsOpen():
    buffer_names = [window.buffer.name for window in vim.current.tabpage.windows]
    for name in buffer_names:
        if "NERD_tree" in name:
            return True
    return False

def windowsWithBuffersNameAreOpen(names):
    buffers_not_open = set(names)
    for buffer_name in (window.buffer.name for window in vim.current.tabpage.windows):
        for name in names:
            if name in buffer_name:
                try:
                    buffers_not_open.remove(name)
                except:
                    pass
    return len(buffers_not_open) == 0

def getAltBufferNumber():
    current_buffer_number = vim.current.buffer.number
    try:
        vim.command('b#')
        result = vim.current.buffer.number
        vim.command('b#')
    except:
        result = getPreviousBufferNumber()
    return result

def getPreviousBufferNumber():
    vim.command('bNext')
    result = vim.current.buffer.number
    try:
        vim.command('bnext')
    except Exception as e:
        print("exception raised while getting previous buffer number")
        print(e)
    return result

def makePreviousBufferAltBuffer():
    vim.command('bprevious')
    vim.command('bnext')

def switchToBufferNumber(number):
    if number is None:
        return
    try:
        vim.command("b" + str(number))
    except:
        print("could not switch to buffer ", number)

def deleteCurrentBuffer(force=False):
    current_buffer_number = vim.current.buffer.number
    alt_buffer_number = getAltBufferNumber()
    previous_buffer_number = getPreviousBufferNumber()
    filename = getFilename()
    if previous_buffer_number == current_buffer_number:
        if force:
            try:
                vim.command('q!')
            except:
                print("Couldn't even force the closing of the current buffer!")
        else:
            try:
                vim.command('q')
            except:
                print("This buffer has been modified!")
        return None
    elif alt_buffer_number == current_buffer_number:
        alt_buffer_number = previous_buffer_number

    switchToBufferNumber(alt_buffer_number)
    if filename == "" or filename.startswith('term://') or force:
        vim.command("bdelete! " + str(current_buffer_number))
        # once you delete a buffer and move to the alt buffer, the buffer
        # you just deleted becomes the new alt buffer, and you can still
        # switch to it despite it being deleted. To get around this, after
        # deleting a buffer, we make the previous buffer the alt buffer
        makePreviousBufferAltBuffer()
    else:
        try:
            vim.command("bdelete " + str(current_buffer_number))
            # see above
            makePreviousBufferAltBuffer()
        except:
            print("This buffer has been modified!")
            switchToBufferNumber(current_buffer_number)

def quitCurrentBuffer(force=False):
    try:
        if '[[buffergator' in vim.current.buffer.name:
            vim.command('q')
        else:
            deleteCurrentBuffer(force)
    except Exception as e:
        print("Exception raised while quitting current buffer")
        print(e)

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

def exportToAnki():
    try:
        with open("/home/will/Documents/Anki2/exported.tsv", 'r') as f:
            lines = f.read().splitlines()
    except FileNotFoundError:
        print("No previous export, creating")
        lines = []

endpython3
"}}}
"simple remappings
"{{{

" I use expand tab, but occasionally want to use real tabs. The following
" makes shift tab insert a tab character
inoremap <S-Tab> <C-V><Tab>

" I often need to insert text at many points. This lets me create a macro in
" 'e' that move the curser to the next point to insert text. I can then enter
" the text, hit ctrl-Space, and be at the next point.
inoremap <C-Space> <ESC>@ei

"Navigation shortcuts
inoremap kj <ESC>
inoremap KJ <ESC>
nnoremap <leader>, :bN<CR>
nnoremap <leader>< :tabN<CR>
nnoremap <leader>/ :bn<CR>
nnoremap <leader>? :tabn<CR>
nnoremap <leader>. :b#<CR>
nnoremap <leader>q :python3 quitCurrentBuffer()<CR>
nnoremap <leader>wq :w<CR>:python3 quitCurrentBuffer()<CR>
nnoremap !<leader>q :python3 quitCurrentBuffer(force=True)<CR>

" Open the grepper
nnoremap <leader>gg :Grepper<CR>
"nnoremap <leader>gg :Grepper -tool ag -noprompt -dir /home/will/Nextcloud/Notes -grepprg ag --vimgrep -Q <CR>

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

" Make // in visual mode search for the text I've selected
vnoremap // "qy/<C-R>q<CR>

"Shortcuts for opening and loading vimrc
nnoremap <leader>ve :edit ~/.config/nvim/init.vim<CR>
nnoremap <leader>vs :source ~/.config/nvim/init.vim<CR>

nnoremap ; @

"remove all whitespace errors when saving
autocmd BufWritePre * :silent! %s/\(\.*\)\s\+$/\1

" <leader>tt opens / switches to a terminal.
nnoremap <leader>tt :python3 switchToBufferWithName('term:', 'term:///bin/bash', '/bin/bash')<CR>A
" <leader>tp opens / switches to a new terminal with python prompt
nnoremap <leader>tp :python3 switchToBufferWithName('term:', 'term:///usr/bin/ipython', '/usr/bin/ipython')<CR>A
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
python3 << endpython3
def copyCurrentFilename():
    setClipboard(getFilename())
    print("Filename copied: " + getFilename())

endpython3

"open a file from the current directory
nnoremap <leader>oi :edit %:p:h/

"open a file in my spreadsheets folder. These are scripts that output stuff I
"often want to paste into vim. They have data at the top of them that can be
"manipulated in vim easily to affect the output.
nnoremap <leader>os :edit /home/will/Documents/Programming/spreadsheet-scripts<CR>

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

"Export the current set of notes as anki cards
"I don't really use this any more
nnoremap <leader>oea :!markdown_to_anki.py '/home/will/Documents/anki-to-import.csv' '%'<CR>

"move the current line to the end of the file
nnoremap <leader>oe :+1mark0<CR>:m$<CR>`0
vnoremap <leader>oe :+1mark0<CR>:m$<CR>`0

nnoremap <leader>kf :py3 copyCurrentFilename()<CR>

"}}}
"Remappings specifically for python3 code
"{{{
python3 << endpython3

test_module = ""
def runPythonUnitTests(debugger=False):
    global test_module
    filetype = getFileType()
    if os.system('which pytest') == 0:
        test_command = "pytest "
    else:
        test_command = "python3 -m unittest discover "
    if filetype == 'py':
        if os.path.isfile("manage.py"):
            # If manage.py exists in the current directory, then this is a django project
            if debugger:
                vim.command("VBGstartPDB3 manage.py test " + test_module)
            else:
                runShellCommandIntoNewBuffer("python3 manage.py test " + test_module)
        else:
            if debugger:
                vim.command("VBGstartPDB3 " + test_command + test_module)
            else:
                runShellCommandIntoNewBuffer(test_command + test_module)
        return True
    return False
RunUnitTestListeners.append(runPythonUnitTests)

def addPythonImport():
    filetype = getFileType()
    if filetype != 'py' and getLine(0) != "#!/usr/bin/python3":
        return False
    moduleName = getInput("Name of module: ").strip()
    if moduleName == '':
        # if no module name was supplied do nothing, but indicate we've handled
        # the event.
        return True
    importSectionBeginning = findFirstLineStartingWith(['import', 'from'])
    if importSectionBeginning == 0 and getLine(0) == "#!/usr/bin/python3":
        importSectionBeginning = 1
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
    elif filetype in ['c', 'h', 'cpp']:
        extensions = ['.h', '.c']
        command = ['/usr/bin/ctags', '-f', 'tags', '-L', '-']
    elif filetype == '.lisp':
        extensions = ['.lisp']
        command = ['/usr/bin/ctags', '-f', 'tags', '-L', '-']
    else:
        return
    sourcefiles = []
    for root, directories, files in os.walk('.', followlinks=True):
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
def runCPPUnitTests(debugger=False):
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
    if filetype not in ['cpp', 'hpp', 'c', 'h']:
        return False
    currentLineNumber = getRow()
    filename = getInput("Filename to include (including \"\" or <>): ")
    if filename[0] in ['"', '<'] and filename[-1] in ['"', ">"]:
        addLineToSectionByPrefix("#include", "#include " + filename)
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
"Remappings specifically for Lisp code
"{{{
python3 << endpython3

def runLispUnitTests(debugger=False):
    filetype = getFileType()
    if filetype == 'lisp':
        directory = os.path.split(getFilename())[0]
        test_file = os.path.join(directory, 'tests.lisp')
        while not os.path.isfile(test_file):
            if directory == '/':
                print("No tests.lisp file found")
                return True
            directory = os.path.split(directory)[0]
            test_file = os.path.join(directory, 'tests.lisp')
        runShellCommandIntoNewBuffer(
            "sbcl --script {test_file}".format(test_file=test_file))
        return True
    return False

RunUnitTestListeners.append(runLispUnitTests)

endpython3

nnoremap <leader>la J<ESC>xi<RETURN><ESC>0
"}}}
"Remappings applicable to editing any code
"{{{
"functions used in this section
python3 << endpython3
def replaceSpacesWithUnderscores():
    currentLineNumber = getRow()
    (indent, line) = splitIndentFromText(getLine(currentLineNumber))
    setLine(currentLineNumber, indent + line.replace(" ", "_"))

def runUnitTests(debugger=False):
    for runner in RunUnitTestListeners:
        if runner(debugger=debugger):
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

def reverseSomeLines():
    count = int(getInput("How many lines should be reversed? "))
    firstLine = getRow()
    oldLines = getLines(firstLine, firstLine + count)
    newLines = list(reversed(oldLines))
    setLines(firstLine, firstLine + count, newLines)

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

import datetime
last_run = datetime.datetime.now()
def runBlack():
    global last_run
    now = datetime.datetime.now()
    if (now - last_run).total_seconds() > 1:
        last_run = now
        filetype = getFileType()
        if filetype == "py":
            subprocess.run(["/usr/bin/python3", "-m", "black", getFilename()])


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

def launchCurrentFileInDebugger():
    if os.path.isfile("manage.py"):
        # if we're in a django project, then launch the development server with the debugger
        vim.command("VBGstartPDB3 manage.py runserver")
    else:
        vim.command("VBGstartPDB3 " + getFilename())

def executeCurrentScriptIntoNewBuffer():
    if getLine(0).startswith('#!'):
        # get the environment from shebang
        environment = getLine(0)[2:].split()
    elif getFileType() == 'm4':
        environment = ['/usr/bin/m4']
    else:
        print("No shebang found")
        return
    with subprocess.Popen(environment + [getFilename()], stderr=subprocess.PIPE, stdout=subprocess.PIPE) as p:
        result = p.stdout.read().decode()
        result += "\n"
        result += p.stderr.read().decode()
    vim.command('checktime')
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
    elif remaining_text.startswith('; '):
        remaining_text = remaining_text[2:]
        indent += "; "
    elif remaining_text.startswith('-- '):
        # SQL comments
        remaining_text = remaining_text[3:]
        indent += "-- "
    elif remaining_text.startswith('* ') and getFileType() in ['c', 'h']:
        # Block style comments in C, but only in a .c or .h file
        remaining_text = remaining_text[2:]
        indent += "* "
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

def setTestModule():
    if getFileType() != 'py':
        return
    global test_module
    test_module = getInput("What is the name of the module you to test? ")
    runPythonUnitTests(debugger=False)

endpython3

" ensure the current line is no more than 72 characters long
nmap <leader>le :python3 splitCurrentLineIntoParagraphs()<CR>

" <leader>mc (make check) runs the unit tests
nnoremap <leader>mc :w<CR>:python3 runUnitTests()<CR>

" <leader>mt (make test) sets the test module and then runs the unittests.
" This is useful in django projects with lots of tests that take forever to
" run. This will let you just run a single test module
nnoremap <leader>mt :w<CR>:python3 setTestModule()<CR>

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

" reverse the order of the next few lines
nnoremap <leader>cr :python3 reverseSomeLines()<CR>

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
nnoremap <leader>rr :w<CR>:python3 executeCurrentScriptIntoNewBuffer()<CR>

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
"custom commands (python3 functions)
"{{{
" This lets me use python functions like editor commands so they don't need to
" start with a capital letter.
nnoremap <leader>pe :python3 executePythonFunction()<CR>

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

function! VimwikiLinkHandler(link)
  " Use Vim to open external files with the 'vfile:' scheme.  E.g.:
  "   1) [[vfile:~/Code/PythonProject/abc123.py]]
  "   2) [[vfile:./|Wiki Home]]
  let link = a:link
  if link =~# '^vfile:'
    let link = link[1:]
  else
    return 0
  endif
  let link_infos = vimwiki#base#resolve_link(link)
  if link_infos.filename == ''
    echomsg 'Vimwiki Error: Unable to resolve link!'
    return 0
  else
    exe 'edit ' . fnameescape(link_infos.filename)
    return 1
  endif
endfunction

" This is to prevent vimwiki from mapping wc
nnoremap <leader>wVimwikiColorizeNormal <Plug>VimwikiColorizeNormal
" Open the calendar
nnoremap <leader>wc :Calendar<CR>
"next day in diary
nnoremap <leader>w<Down> <Plug>VimwikiDiaryNextDay
"previous day in diary
nnoremap <leader>w<Up> <Plug>VimwikiDiaryPrevDay
"}}}
" Configure vebugger
"{{{
let g:vebugger_leader='<leader>d'

nnoremap <leader>mdc :w<CR>:python3 runUnitTests(debugger=True)<CR>

" same as <leader>r but launches the python script with the debugger
nnoremap <leader>dr :python3 launchCurrentFileInDebugger()<CR>
"}}}
" Remapings for todo.txt / tasks
"{{{
" nnoremap <localleader>to :edit ~/Nextcloud/Notes/todo.txt<CR>

python3 << endpython3

def getTodoContext(line):
    return next(filter(lambda x : x[0] == '@', line.split()))

def foldTodoContext():
    if not getFilename().endswith('todo.txt'):
        return
    vim.command("setlocal foldmethod=manual")
    current_row = getRow()
    current_todo_context = getTodoContext(getLine(current_row))
    first_row = current_row - 1
    while first_row >= 0 and getTodoContext(getLine(first_row)) == current_todo_context:
        first_row -= 1
    first_row += 2
    last_row = current_row + 1
    while last_row < getLineCount() and getTodoContext(getLine(last_row)) == current_todo_context:
        last_row += 1
    if last_row > first_row:
        vim.command("{a},{b}fold".format(a=first_row, b=last_row))

import datetime

def typeDateHere():
    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    line = getLine(getRow())
    idx = getCol() + 1
    setLine(getRow(), line[:idx] + current_date + line[idx:])
    setCursor(getRow(), getCol() + 10)

def ArchiveCompletedTask():
    line_no = getRow()
    line = getLine(line_no)
    deleteLine(line_no)
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    with open(os.path.expanduser('~/Documents/Notes/vimwiki/Todos_done.md'), 'a') as f:
        f.write(f'{line} ({today})\n')


endpython3

" Insert the date at the current location
nnoremap <leader>td :python3 typeDateHere()<CR>

" record a line as completed
nnoremap <leader>tc :python3 ArchiveCompletedTask()<CR>

" Sort all lines by their task name, not the dates or x at the start
" I use this to merge to do text files when I have a conflict between my
" computer and my phone. This makes it easier to compare the two files in
" meld.
nnoremap <localleader>st :sort /\(x\s*\)\?\([0-9]\{4}-[0-9]\{2}-[0-9]\{2}\s*\)\{1,2}/<CR>

" Sort by all the contexts together, and all the projects together within
" each context
nnoremap <localleader>ss :sort /+[a-zA-Z]*/ r<CR>:sort /@[a-zA-Z]*/ r<CR>:sort /^x/ r<CR>
"}}}
" Experiments
"{{{
" Omni complete functions
"
" need a function that is called twice. THe first time findstart is 1, then
" again wtih findstart = 0.
"
" The first time, return a number that indicates the position of the start of
" the word being autocompleted
"
" the second time, return a list of possible words to autocomplete with
"
" function! Python_test_completion(findstart, base)
"     if a:findstart
"         return col('.') - 3
"     else
" python3 << endpython3
"
" findstart = vim.eval('a:findstart')
" base = vim.eval('a:base')
" with open("/tmp/test_onmi.log", 'a') as f:
"     f.write("findstart: {}\n".format(findstart))
"     f.write("base: {}\n".format(base))
"     vim.vars.set('l:result', '
" endpython3
"
"         return ['hello', 'world', 'blah']
"     endif
" endfunction
"}}}
