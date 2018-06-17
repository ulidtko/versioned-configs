#-- https://github.com/Valloric/YouCompleteMe#option-2-provide-the-flags-manually

import os

def FlagsForFile(filename, **kwargs):
    _, ext = os.path.splitext(filename)

    lang = 'c++' if ext in ('.cpp', '.cc', '.hpp', '.hh') else 'c'

    return {
        'flags': [ '-x', lang, '-std=c++14', '-Wall', '-Wextra' ]
    }
