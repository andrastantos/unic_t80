dnl Process this file with autoconf to produce a configure script.
UPDATED='November 1, 2016'
AC_INIT(LibDsk, 1.4.2)
AC_CONFIG_SRCDIR(lib/dskopen.c)
AC_CONFIG_AUX_DIR(config)
AC_CONFIG_MACRO_DIR(m4)
AC_CANONICAL_SYSTEM
LT_INIT
AM_CONFIG_HEADER(config.h)
AM_INIT_AUTOMAKE

dnl Support for the Java Native Interface bindings
AC_ARG_WITH(jni,
[  --with-jni              Include Java Native Interface bindings [default=no]],
	      , with_jni=no)
dnl Support for transparent zlib compression
AC_ARG_WITH(zlib,
[  --with-zlib             Include support for gz-compressed files [default=yes]],
	      , with_zlib=yes)
dnl Support for transparent bzlib compression
AC_ARG_WITH(bzlib,
[  --with-bzlib            Include support for bz2-compressed files [default=yes]],
	      , with_bzlib=yes)
dnl Enable / disable machine-specific "floppy" driver
AC_ARG_ENABLE(floppy,
[  --enable-floppy         Enable host floppy driver [default=yes]],
              , enable_floppy=yes)
AC_JAVA_OPTIONS
if test x$enable_floppy = xyes; then
    :
else
    CFLAGS="$CFLAGS -DDISABLE_FLOPPY"
fi


dnl Checks for programs.
AC_PROG_CC
AC_PROG_INSTALL
dnl Obsoleted by LIBTOOL AC_PROG_RANLIB
AC_PROG_MAKE_SET
AM_PROG_LIBTOOL

dnl GCC extra options
dnl Disable DLL export functions, because gcc 2.95.2 crashes
dnl trying to compile with them present.
if test "$ac_cv_prog_gcc" = "yes"; then
  CFLAGS="-Wall -DNOTWINDLL $CFLAGS"
fi

dnl Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS(errno.h limits.h sys/ioctl.h stat.h sys/stat.h sys/types.h)
AC_CHECK_HEADERS(unistd.h termios.h libgen.h assert.h)
AC_CHECK_HEADERS(dirent.h fcntl.h utime.h pwd.h time.h dir.h direct.h)
AC_CHECK_HEADERS(linux/fd.h linux/fdreg.h shlobj.h)
AC_CHECK_HEADERS([windows.h winioctl.h], [], [], 
[[#ifdef HAVE_WINDOWS_H
#include <windows.h>
#endif
]])

dnl Checks for functions
AC_CHECK_FUNCS(strcmpi stricmp strcasecmp, break)
AC_CHECK_FUNCS(mkstemp)
AC_CHECK_FUNCS(basename)
AC_CHECK_FUNCS(fork)
AC_CHECK_FUNCS(GetTempFileName)
AC_CHECK_FUNCS(sleep)

dnl Checks for zlib
if test x$with_zlib = xyes; then
	AC_CHECK_HEADERS(zlib.h)
	AC_CHECK_LIB(z, zlibVersion)
fi
dnl Checks for bzlib
if test x$with_bzlib = xyes; then
	AC_CHECK_HEADERS(bzlib.h)
	AC_CHECK_LIB(bz2, BZ2_bzlibVersion)
fi

dnl Checks for Java bits
if test x$with_jni = xyes; then
	JAVA=java
	JAVAC=javac
	AC_CHECK_CLASSPATH
	AC_PROG_JAVAC
	AC_PROG_JAVA
	AC_PROG_JAVAH
	AC_PROG_JAVADOC
	AC_PROG_JAR
	AC_JNI_INCLUDE_DIR
     for JNI_INCLUDE_DIR in $JNI_INCLUDE_DIRS
     do
             CPPFLAGS="$CPPFLAGS -I$JNI_INCLUDE_DIR"
     done
	AC_CHECK_HEADERS(jni.h)
	LIBDSKJAR=libdsk.jar
	TOOLCLASSES="DskFormat.class DskID.class DskTrans.class" 
else
	LIBDSKJAR=
	TOOLCLASSES=
	JAVAH=true 
	JAVAC=true 
	JAVA=true
	JAVADOC=true
	JAR=true
fi

dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T
AC_EXEEXT
AC_OBJEXT

dnl Pass path for the 'share' directory
CPPFLAGS="$CPPFLAGS -DAUTOSHARE=${datadir}/LibDsk"

dnl Checks for library functions.
AC_PROG_GCC_TRADITIONAL
AC_HEADER_MAJOR
AC_FUNC_MEMCMP
AC_CHECK_FUNCS(strerror)

AC_SUBST(LIBDSKJAR)
AC_SUBST(TOOLCLASSES)
AC_SUBST(CLASSPATH)
AC_OUTPUT(Makefile doc/Makefile include/Makefile lib/Makefile tools/Makefile man/Makefile)
