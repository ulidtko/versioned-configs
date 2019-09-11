"""
                    ==== SYNOPSYS ====

THIS is the dirty old rug where [YCM][] presupposes you put
all your C++-related violence under.

[YCM]: https://github.com/ycm-core/YouCompleteMe

YouCompleteMe is a code navigation and completion plugin for Vim.

To be any useful, it needs to understand the build system and the
compile flags to intelligibly parse any file.

## Why do I have to do it my own way ##
When building people's code, I prefer an **out-of-source build** if that's
available. It's just too easy to lose track of the build state, *what have you
done* and when, especially if the build doesn't work from the 1st try. And it's
*soooo* easy to wipe the separate build-directory to reset to a known sane state
(without nuking and redoing the whole git repo), knowing you lose nothing,
faster than `git clean -fxd`.

Unfortunately, tooling is usually nearly oblivious of out-of-source builds.
That's what I'm sort-of-bicycling around trying to fix here.

## compile_commands.json -- the compilation database ##

Doc here http://clang.llvm.org/docs/JSONCompilationDatabase.html

    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    ninja -t compdb

-------------------------------------------------------------------------------

Inspired by:
  * https://jonasdevlieghere.com/a-better-youcompleteme-config/
  * https://gist.github.com/locojay/4950253

Also read:
  * http://ycm-core.github.io/YouCompleteMe/#c-family-semantic-completion

"""

# pylint: disable=invalid-name
# pylint: disable=missing-docstring
import logging
import os
import os.path as path
import re

# These imports are provided by YCM, deaggro linter on them.
# pylint: disable=import-error
import ycm_core
from clang_helpers import PrepareClangFlags
# pylint: enable=import-error

# Module-level global, caches the found DB
compilation_db = None

# Last-resort fallback guesswork
C_BASE_FLAGS = [
    '-Wall',
    '-Wextra',
    #'-Werror',
    '-std=c11',
    '-I/usr/include/',
    '-I./include',
    '-I.',
]
CPP_BASE_FLAGS = [
    '-xc++', '-std=c++1z',
    '-Wall',
    '-I/usr/include/',
    '-I./include',
    '-I.',
    #'-stdlib=libc++',
    #'-isystem', '/usr/lib/c++/v1'
]

# pylint: disable=bad-whitespace
PLAINC_EXT_GUESSES = ('.c',)
CPPLUS_EXT_GUESSES = ('.cpp', '.cxx', '.cc', '.m', '.mm')
HEADER_EXT_GUESSES = ('.h', '.hxx', '.hpp', '.hh')
HDR_DIR_GUESSES    = ('include')
SRC_DIR_GUESSES    = ('src', 'lib')

BUILDDIR_GUESSER   = re.compile(r'(build|BUILD)([-_.].*)?')
BUILDDIR_MARKERS   = ('compile_commands.json', 'System.map', '.kernelrelease',
                      'CMakeCache.txt', 'config.status')

PROJECT_MARKERS    = ('.git', 'COPYING', 'LICENSE',
                      'AUTHORS', 'CREDITS', 'package.json', 'setup.py')

DIR_OF_THIS_SCRIPT = os.path.dirname(os.path.abspath(__file__))
# pylint: enable=bad-whitespace


def AppearsAsHdrFile(filename):
    _, ext = path.splitext(filename)
    return ext in HEADER_EXT_GUESSES

def AppearsAsSrcFile(filename):
    _, ext = path.splitext(filename)
    return ext in PLAINC_EXT_GUESSES + CPPLUS_EXT_GUESSES

def LookupBaseFlags(filename):
    _, ext = path.splitext(filename)
    return C_BASE_FLAGS if ext in PLAINC_EXT_GUESSES else CPP_BASE_FLAGS

def WalkParentDirs(start_dir):
    i_dir = start_dir
    while True:
        try:
            os.listdir(i_dir)
        except OSError:
            break

        yield i_dir
        i_dir = path.dirname(i_dir)

        if path.ismount(i_dir):
            break

        if path.realpath(i_dir) == path.realpath(start_dir):
            break

def WalkChildrenLevel(d):
    for item in os.listdir(d):
        yield path.join(d, item)

def WalkCompose(walk1, walk2):
    """ Composes two walks """
    return lambda start_dir: (y for x in walk1(start_dir) for y in walk2(x))

WalkExample0 = lambda start_dir: []
WalkExample1 = lambda start_dir: WalkChildrenLevel(start_dir)
WalkExample2 = WalkChildrenLevel
WalkExample3 = WalkCompose(WalkParentDirs, WalkChildrenLevel)

def AbsolutizeFlags(flags, working_directory):
    """ Resolve filenames in flags e.g. -I to absolute """
    if not working_directory:
        return list(flags)
    result = []
    path_flags = ['-isystem', '-I', '-iquote', '--sysroot=']
    flag_iter = iter(flags)
    try:
        while 1:
            flag = next(flag_iter)

            if flag in path_flags:
                arg = next(flag_iter)
                if not path.isabs(arg):
                    arg = os.path.join(working_directory, arg)

                result.append(flag)
                result.append(arg)
                continue

            for p in path_flags:
                if flag.startswith(p):
                    arg = flag[len(p):]
                    if not path.isabs(arg):
                        arg = os.path.join(working_directory, arg)
                    result.append(p + arg)
                    break
    except StopIteration:
        pass
    return result

def GuessProjectRoot(query_dir):
    for candidate in WalkParentDirs(query_dir):
        if any(
                path.isfile(path.join(candidate, marker))
            or  path.isdir(path.join(candidate, marker))
            for marker in PROJECT_MARKERS
            ):
            logging.info("Guessed project_root at %s", candidate)
            return candidate

    logging.info("Coward fallback: found no PROJECT_MARKERS at %s", query_dir)
    return query_dir

def GuessBuildsubdir(project_root):
    for d in WalkChildrenLevel(project_root):
        if path.isdir(path.join(project_root, d)) \
            and re.match(BUILDDIR_GUESSER, path.basename(d)) \
            and any(path.exists(path.join(d, m)) for m in BUILDDIR_MARKERS):
            logging.info("Guessed build_dir at %s", d)
            return path.basename(d)
    logging.info("Couldn\'t guess build_dir, fallback to src dir %s", project_root)
    return '.'

def LookupCompileDb(database, filename):
    basename, ext_input = os.path.splitext(filename)
    if ext_input in HEADER_EXT_GUESSES:
        #-- Headers themselves aren't written to compile_commands.json:
        #-- that DB is per-translation-unit (per .c/.cpp file).
        #-- Do more guesswork to pair the header with "its" .cpp
        for extension in PLAINC_EXT_GUESSES + CPPLUS_EXT_GUESSES:
            maybe_source = basename + extension
            if path.exists(maybe_source):
                #-- Neat, we just substituted the extension
                info = database.GetCompilationInfoForFile(maybe_source)
                if info.compiler_flags_:
                    return info
            #-- Not so neat; try to s/include/src/ in the path
            for hdr_frag in HDR_DIR_GUESSES:
                for src_frag in SRC_DIR_GUESSES:
                    src_file = maybe_source.replace(hdr_frag, src_frag)
                    if path.exists(src_file):
                        info = database.GetCompilationInfoForFile(src_file)
                        if info.compiler_flags_:
                            return info
    return database.GetCompilationInfoForFile(filename)

def LookupClangComplete(build_dir):
    for candidate in WalkParentDirs(build_dir):
        try:
            return open(path.join(candidate, '.clang_complete'),
                        'r').read().splitlines()
        except OSError:
            pass

def Settings(language=None, filename=None, _client_data=None, **_kwargs):
    """ YCM entrypoint """
    if language != 'cfamily':
        return {}

    #-- NOTE: don't os.path.realpath(), this clobbers symlinks
    query_dir = os.path.dirname(filename)
    project_root = GuessProjectRoot(query_dir)
    build_subdir = GuessBuildsubdir(project_root)

    build_dir = path.join(project_root, build_subdir)

    global compilation_db
    if not compilation_db:
        # NOTE: it accepts the containing directory, not compile_commands.json!
        compilation_db = ycm_core.CompilationDatabase(build_dir)
        logging.info("Compilation DB in %s", compilation_db.database_directory)

    if compilation_db:
        logging.info("Looking up file %s", filename)
        info = LookupCompileDb(compilation_db, filename)
        logging.debug("Found flags %s", info.compiler_flags_)
        final_flags = AbsolutizeFlags(
            info.compiler_flags_,
            info.compiler_working_dir_
        )
    else:
        if AppearsAsSrcFile(filename):
            final_flags = LookupBaseFlags(filename)

        final_flags += LookupClangComplete(build_dir) or []

        relative_to = DIR_OF_THIS_SCRIPT
        final_flags = AbsolutizeFlags(final_flags, relative_to)

    return {
        'flags': final_flags,
        'do_cache': True,
        # 'include_paths_relative_to_dir': build_dir,
        }
