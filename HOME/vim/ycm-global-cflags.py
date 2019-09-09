#-- Inspired by:
#-- https://jonasdevlieghere.com/a-better-youcompleteme-config/
#-- https://gist.github.com/locojay/4950253

import os
import os.path as path
import logging
import re
import ycm_core
from clang_helpers import PrepareClangFlags

# TODO highlevel SYNOPSYS doc
# compile_commands.json directory
# http://clang.llvm.org/docs/JSONCompilationDatabase.html
# cmake with -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON
compilation_database_folder = ''

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

PLAINC_EXT_GUESSES = ('.c',)
CPPLUS_EXT_GUESSES = ('.cpp', '.cxx', '.cc', '.m', '.mm')
HEADER_EXT_GUESSES = ('.h', '.hxx', '.hpp', '.hh')
HDR_DIR_GUESSES    = ('include')
SRC_DIR_GUESSES    = ('src', 'lib')

BUILDDIR_GUESSER   = re.compile(r'(build|BUILD)([-_.].*)?')
BUILDDIR_MARKERS   = ('compile_commands.json', 'System.map', '.kernelrelease',
        'CMakeCache.txt', 'config.status')

PROJECT_MARKERS    = ('.git', 'README', 'README.md', 'COPYING', 'LICENSE',
        'AUTHORS', 'CREDITS', 'package.json', 'setup.py')

def DirectoryOfThisScript():
    return os.path.dirname(os.path.abspath(__file__))

def AppearsAsHdrFile(filename):
    _, ext = path.splitext(filename)
    return ext in HEADER_EXT_GUESSES

def AppearsAsSrcFile(filename):
    _, ext = path.splitext(filename)
    return ext in C_SRCEXT_GUESSES + CPP_SRCEXT_GUESSES

def LookupBaseFlags(filename):
    _, ext = path.splitext(filename)
    return C_BASE_FLAGS if ext in PLAINC_EXT_GUESSES else CPP_BASE_FLAGS

def WalkParentDirs(start_dir):
    i_dir = start_dir
    while True:
        try:
            os.listdir(i_dir)
        except OSError:
            logging.debug("[WalkParents] not found | denied - %s", i_dir)
            break
        else:
            logging.debug("[WalkParents] is accessible      - %s", i_dir)

        yield i_dir
        i_dir = path.dirname(i_dir)

        if path.ismount(i_dir):
            logging.debug("[WalkParents] reached mount boundary - %s", i_dir)
            break

        if path.realpath(i_dir) == path.realpath(start_dir):
            logging.debug(
                "[WalkParentDirs] reached start point - symlink/bindmount loop? %s",
                i_dir)
            break

def WalkChildrenLevel(dir, filter=lambda _: True):
    for item in os.listdir(dir):
        if not filter(item): continue
        yield path.join(dir, item)

def WalkCompose(walk1, walk2):
    """ Composes two walks """
    return lambda start_dir: (y for y in walk2(x) for x in walk1(start_dir))

WalkExample0 = lambda start_dir: []
WalkExample1 = lambda start_dir: WalkChildrenLevel(start_dir)
WalkExample2 = WalkChildrenLevel
WalkExample3 = WalkCompose(WalkParentDirs, WalkChildrenLevel)

def FindNearest(path, needle, build_dir=None): # TODO drop this
    candidate = os.path.join(path, needle)
    if(os.path.isfile(candidate) or os.path.isdir(candidate)):
        logging.info("Found nearest " + needle + " at " + candidate)
        return candidate;

    parent = os.path.dirname(os.path.abspath(path));

    if(build_dir):
        candidate = os.path.join(parent, build_dir, needle)
        if(os.path.isfile(candidate) or os.path.isdir(candidate)):
            logging.info("Found nearest " + needle + " in builddir at " + candidate)
            return candidate;

    if(parent == path):
        raise RuntimeError("Could not find " + needle);
    else:
        return FindNearest(parent, needle, build_dir)

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
            for marker in PROJECT_ROOT_MARKERS
            ):
            logging.info("Guessed project_root at %s" % candidate)
            return candidate

def GuessBuildsubdir(project_root):
    for d in WalkChildrenLevel(project_root):
        if path.isdir(path.join(project_root, d)) \
            and re.match(BUILDDIR_GUESSER, d) \
            and any(path.exists(path.join(d, m) for m in BUILDDIR_MARKERS)):
            logging.info("Guessed build_dir at %s", d)
            return d
    logging.info("Couldn\'t guess build_dir, fallback to src dir %s", project_root)
    return '.'

def LookupCompileDb(database, filename):
    basename, ext_input = os.path.splitext(filename)
    if ext_input in HEADER_EXT_GUESSES:
        #-- Headers themselves aren't written to compile_commands.json:
        #-- that DB is per-translation-unit (per .c/.cpp file).
        #-- Do more guesswork to pair the header with "its" .cpp
        for extension in PLAINC_EXT_GUESSES + CPP_SRCEXT_GUESSES:
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

def FlagsForFile(query_fname):
    """ YCM entrypoint """
    #-- NOTE: don't os.path.realpath(), this clobbers symlinks
    query_dir = os.path.dirname(query_fname)
    project_root = GuessProjectRoot(query_dir)
    build_dir = GuessBuildsubdir(project_root)

    db_path = path.join(build_dir, 'compile_commands.json')
    compile_db = ycm_core.CompilationDatabase(db_path)
    if compile_db:
        info = LookupCompileDb(compile_db, query_fname)
        final_flags = AbsolutizeFlags(
                info.compiler_flags_,
                info.compiler_working_dir
            )
    else:
        if AppearsAsSrcFile(query_fname):
            final_flags = LookupBaseFlags(query_fname)

        final_flags += LookupClangComplete(build_dir) or []

        relative_to = DirectoryOfThisScript()
        final_flags = AbsolutizeFlags(flags, relative_to)

    return {
        'flags': final_flags,
        'do_cache': True}
