#!/bin/bash

OS=LINUX
#OS=WINDOWS
#OS=MACOSX

PARALLEL="-j 1"

TARGET="arm-none-eabi"
PKGVERSION="PJRC Build of GNU Toolchain from CodeSourcery"
BUGURL="http://forum.pjrc.com/"

# programs needed to compile...
# sudo apt-get install m4 texinfo flex bison libtinfo-dev g++

THISDIR=`pwd`
PREFIX="/usr/local"		# nothing actually gets written here
SOURCES=${THISDIR}/sources	# source code
WORKD=${THISDIR}/workdir	# temporary area where code is compiled
OUTPUT=${THISDIR}/${TARGET}	# location where final output is built
NATIVE=${THISDIR}/native	# native toolchain, used for Canadian cross
PROGRESS=${THISDIR}/progress	# progress marker files
STATICLIBS=${THISDIR}/staticlib	# static libraries

BINUTILS="binutils-2012.09"
CLOOG="cloog-0.15"
EXPAT="expat-2012.09"
GCC="gcc-4.7-2012.09"
GDB="gdb-2012.09"
GMP="gmp-2012.09"
LIBELF="libelf-2012.09"
#LIBICONV="libiconv-1.11"
MAKE="make-3.82"
MPC="mpc-2012.09"
MPFR="mpfr-2012.09"
NEWLIB="newlib-2012.09"
PPL="ppl-sgxx-0.11-2012.09"
ZLIB="zlib-1.2.7"



if [ "$OS" == "LINUX" ]; then
	BUILD=`${SOURCES}/config.guess`
	HOST="$BUILD"
	export CC="gcc"
	export CXX="g++"
	export AR="ar"
	export RANLIB="ranlib"
	export STRIP="strip"
	export CC_FOR_BUILD="gcc"
	export CXX_FOR_BUILD="g++"
	HOST_LIBSTDCXX="-static-libgcc -Wl,-Bstatic,-lstdc++,-Bdynamic -lm"

elif [ "$OS" == "MACOSX" ]; then
	BUILD=`${SOURCES}/config.guess`
	HOST="$BUILD"
	export CC="gcc"
	export CXX="g++"
	export AR="ar"
	export RANLIB="ranlib"
	export STRIP="strip"
	export CC_FOR_BUILD="gcc"
	export CXX_FOR_BUILD="g++"
	HOST_LIBSTDCXX="-lstdc++"

elif [ "$OS" == "WINDOWS" ]; then
	BUILD=`${SOURCES}/config.guess`
	HOST="i586-mingw32msvc"
	EXTENSION=".exe"
	export CC="${HOST}-gcc"
	export CXX="${HOST}-g++"
	export AR="${HOST}-ar"
	export RANLIB="${HOST}-ranlib"
	export STRIP="${HOST}-strip"
	export CC_FOR_BUILD="gcc"
	export CXX_FOR_BUILD="g++"
	export AR_FOR_TARGET="${TARGET}-ar"
	export NM_FOR_TARGET="${TARGET}-nm"
	export OBJDUMP_FOR_TARET="${TARGET}-objdump"
	export STRIP_FOR_TARGET="${TARGET}-strip"
	export CC_FOR_TARGET="${TARGET}-gcc"
	export GCC_FOR_TARGET="${TARGET}-gcc"
	export CXX_FOR_TARGET="${TARGET}-g++"
	HOST_LIBSTDCXX="-lstdc++ -lsupc++ -lm"

fi

if [ ! -e $SOURCES ]; then
	echo "Sources directory missing, can't build anything"
	exit${NATIVE}
fi

echo "Begin Toolchain Build:"
echo "  Build =  ${BUILD}   (the system building this toolchain)"
echo "  Host =   ${HOST}   (the system the toolchain will run upon)"
echo "  Target = ${TARGET}    (the system the toolchain will produce code for)"

if [ $BUILD != $HOST ]; then
	if [ -x ${NATIVE}/bin/${TARGET}-gcc ]; then
		echo "Canadian Cross Compile"
	elif [ -x ${OUTPUT}/bin/${TARGET}-gcc ]; then
		echo "Canadian Cross Compile, moving ${TARGET} to native"
		echo "  from: ${OUTPUT}"
		echo "  to:   ${NATIVE}"
		rm -rf ${NATIVE} ${WORKD} ${PROGRESS} ${STATICLIBS}
		mv ${OUTPUT} ${NATIVE}
	else
		echo "Canadian Cross Compile requires a native toolchain"
		echo "Please build the native version first, then build"
		echo "this version."
		exit
	fi
fi

if [ ! -e $WORKD ]; then
	mkdir -p $WORKD
fi
if [ ! -e $OUTPUT ]; then
	mkdir -p $OUTPUT
fi
if [ ! -e $PROGRESS ]; then
	mkdir -p $PROGRESS
fi
if [ ! -e $STATICLIBS ]; then
	mkdir -p $STATICLIBS
fi



# recommended by the wiki (does not work on mac)
# http://sourceforge.net/apps/trac/mingw-w64/wiki/PPL,%20CLooG%20and%20GCC
#HOST_LIBSTDCXX="-lstdc++ -lsupc++ -lm"


export AR_FOR_TARGET="${TARGET}-ar"
export NM_FOR_TARGET="${TARGET}-nm"
export OBJDUMP_FOR_TARET="${TARGET}-objdump"
export STRIP_FOR_TARGET="${TARGET}-strip"

export PATH="${NATIVE}/bin:${OUTPUT}/bin:${PATH}"

if [ ! -e ${PROGRESS}/${ZLIB}.built ]; then
	echo "*********************************"
	echo "   Zlib"
	echo "*********************************"
	cd ${WORKD}
	tar -xjf ${SOURCES}/${ZLIB}.tar.bz2
	cd ${WORKD}/${ZLIB}
	export CFLAGS="-O3 -fPIC"
	./configure --prefix=${STATICLIBS} --static || exit
	make ${PARALLEL} || exit
	make install || exit
	export -n CFLAGS
	touch ${PROGRESS}/${ZLIB}.built
	rm -rf ${WORKD}/${ZLIB}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${GMP}.built ]; then
	echo "*********************************"
	echo "   GMP"
	echo "*********************************"
	cd ${WORKD}
	tar -xjf ${SOURCES}/${GMP}.tar.bz2
	cd ${WORKD}/${GMP}
	patch -p0 < ${SOURCES}/gmp-virtualbox9485.patch
	patch -p0 < ${SOURCES}/gmp-tscanf-wine.patch
	./configure --prefix=${STATICLIBS} --build=${BUILD} --host=${HOST} \
		--disable-shared --enable-cxx || exit
	make ${PARALLEL} || exit
	make ${PARALLEL} check || exit
	make install || exit
	touch ${PROGRESS}/${GMP}.built
	rm -rf ${WORKD}/${GMP}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${MPFR}.built ]; then
	echo "*********************************"
	echo "   MPFR"
	echo "*********************************"
	cd ${WORKD}
	tar -xjf ${SOURCES}/${MPFR}.tar.bz2
	cd ${WORKD}/${MPFR}
	./configure --prefix=${STATICLIBS} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} --disable-shared \
		--disable-nls --with-gmp=${STATICLIBS} || exit
	make ${PARALLEL} || exit
	make ${PARALLEL} check || exit
	make install || exit
	touch ${PROGRESS}/${MPFR}.built
	rm -rf ${WORKD}/${MPFR}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${MPC}.built ]; then
	echo "*********************************"
	echo "   MPC"
	echo "*********************************"
	cd ${WORKD}
	tar -xjf ${SOURCES}/${MPC}.tar.bz2
	cd ${WORKD}/${MPC}
	./configure --prefix=${STATICLIBS} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} --disable-shared \
		--disable-nls --with-gmp=${STATICLIBS} --with-mpfr=${STATICLIBS} || exit
	make ${PARALLEL} || exit
	make ${PARALLEL} check || exit
	make install || exit
	touch ${PROGRESS}/${MPC}.built
	rm -rf ${WORKD}/${MPC}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${PPL}.built ]; then
	echo "*********************************"
	echo "   PPL"
	echo "*********************************"
	cd ${WORKD}
	tar -xjf ${SOURCES}/${PPL}.tar.bz2
	cd ${WORKD}/${PPL}
	./configure --prefix=${STATICLIBS} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} --disable-shared \
		--disable-nls --with-gmp=${STATICLIBS} --with-libgmp=${STATICLIBS} \
		CPPFLAGS=-I${STATICLIBS}/include LDFLAGS=-L${STATICLIBS}/lib \
		--disable-watchdog || exit
	make ${PARALLEL} || exit
	make install || exit
	touch ${PROGRESS}/${PPL}.built
	rm -rf ${WORKD}/${PPL}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${CLOOG}.built ]; then
	echo "*********************************"
	echo "   CLOOG"
	echo "*********************************"
	cd ${WORKD}
	tar -xjf ${SOURCES}/${CLOOG}.tar.bz2
	cd ${WORKD}/${CLOOG}
	patch < ${SOURCES}/cloog-mac.patch
	./configure --prefix=${STATICLIBS} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} --disable-shared \
		--disable-nls --with-gmp=${STATICLIBS} --with-ppl=${STATICLIBS} \
		|| exit
	make ${PARALLEL} || exit
	make ${PARALLEL} check || exit
	make install || exit
	touch ${PROGRESS}/${CLOOG}.built
	rm -rf ${WORKD}/${CLOOG}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${LIBELF}.built ]; then
	echo "*********************************"
	echo "   LIBELF"
	echo "*********************************"
	cd ${WORKD}
	tar -xjf ${SOURCES}/${LIBELF}.tar.bz2
	cd ${WORKD}/${LIBELF}
	./configure --prefix=${STATICLIBS} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} --disable-shared \
		--disable-nls || exit
	make ${PARALLEL} || exit
	make install || exit
	touch ${PROGRESS}/${LIBELF}.built
	rm -rf ${WORKD}/${LIBELF}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${EXPAT}.built ]; then
	echo "*********************************"
	echo "   EXPAT"
	echo "*********************************"
	rm -rf ${WORKD}/${EXPAT}
	cd ${WORKD}
	tar -xjf ${SOURCES}/${EXPAT}.tar.bz2
	cd ${WORKD}/${EXPAT}
	./configure --prefix=${STATICLIBS} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} --disable-shared \
		--disable-nls || exit
	make ${PARALLEL} || exit
	make install || exit
	touch ${PROGRESS}/${EXPAT}.built
	rm -rf ${WORKD}/${EXPAT}
	cd ${THISDIR}
fi

#if [ ! -e ${PROGRESS}/${LIBICONV}.built ]; then
#	echo "*********************************"
#	echo "   LIBICONV"
#	echo "*********************************"
#	rm -rf ${WORKD}/${LIBICONV}
#	cd ${WORKD}
#	tar -xjf ${SOURCES}/${LIBICONV}.tar.bz2
#	cd ${WORKD}/${LIBICONV}
#	./configure --prefix=${STATICLIBS} --target=${TARGET} \
#		--build=${BUILD} --host=${HOST} --disable-shared \
#		--disable-nls || exit
#	make ${PARALLEL} || exit
#	make install || exit
#	touch ${PROGRESS}/${LIBICONV}.built
#	rm -rf ${WORKD}/${LIBICONV}
#	cd ${THISDIR}
#fi

#TODO: should also bundle rm, cp, and other utils for windows

if [ "$OS" != "LINUX" -a ! -e ${PROGRESS}/${MAKE}.built ]; then
	echo "*********************************"
	echo "   MAKE"
	echo "*********************************"
	rm -rf ${WORKD}/${MAKE}
	cd ${WORKD}
	tar -xjf ${SOURCES}/${MAKE}.tar.bz2
	cd ${WORKD}/${MAKE}
	patch -p0 < ${SOURCES}/make-3.82-mingw32msvc.patch
	./configure --prefix=${PREFIX} --build=${BUILD} --host=${HOST} \
        	--disable-nls || exit
	make ${PARALLEL} || exit
	make install prefix=${OUTPUT} exec_prefix=${OUTPUT} \
		libdir=${OUTPUT}/lib datadir=${OUTPUT}/share \
		htmldir=${OUTPUT}/share/doc/arm-none-eabi/html \
		pdfdir=${OUTPUT}/share/doc/arm-none-eabi/pdf \
		infodir=${OUTPUT}/share/doc/arm-none-eabi/info \
		mandir=${OUTPUT}/share/doc/arm-none-eabi/man \
		|| exit
	${STRIP} ${OUTPUT}/bin/make${EXTENSION}
	touch ${PROGRESS}/${MAKE}.built
	rm -rf ${WORKD}/${MAKE}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${BINUTILS}.built ]; then
	echo "*********************************"
	echo "   BINUTILS"
	echo "*********************************"
	cd ${WORKD}
	rm -rf ${WORKD}/${BINUTILS}
	tar -xjf ${SOURCES}/${BINUTILS}.tar.bz2
	cd ${WORKD}/${BINUTILS}
	export CPPFLAGS="-I${STATICLIBS}/include"
	export LDFLAGS="-I${STATICLIBS}/lib"
	./configure --prefix=${PREFIX} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} --disable-nls \
        	"--with-pkgversion=${PKGVERSION}" --with-bugurl=${BUGURL} \
		--with-sysroot=${PREFIX}/${TARGET} \
        	--enable-poison-system-directories --enable-plugins || exit
	make ${PARALLEL} all-libiberty || exit
	cp -r ${WORKD}/${BINUTILS}/include/* ${STATICLIBS}/include || exit
	cp ${WORKD}/${BINUTILS}/libiberty/libiberty.a ${STATICLIBS}/lib
	make ${PARALLEL} || exit
	make install prefix=${OUTPUT} exec_prefix=${OUTPUT} \
		libdir=${OUTPUT}/lib datadir=${OUTPUT}/share \
		htmldir=${OUTPUT}/share/doc/arm-arm-none-eabi/html \
		pdfdir=${OUTPUT}/share/doc/arm-arm-none-eabi/pdf \
		infodir=${OUTPUT}/share/doc/arm-arm-none-eabi/info \
		mandir=${OUTPUT}/share/doc/arm-arm-none-eabi/man \
		|| exit
	export -n CPPFLAGS
	export -n LDFLAGS
	rm -f ${OUTPUT}/lib/libiberty.a
	cp ${WORKD}/${BINUTILS}/bfd/.libs/libbfd.a ${STATICLIBS}/lib
	cp ${WORKD}/${BINUTILS}/bfd/bfd.h ${STATICLIBS}/include
	cp ${WORKD}/${BINUTILS}/bfd/elf-bfd.h ${STATICLIBS}/include
	cp ${WORKD}/${BINUTILS}/opcodes/.libs/libopcodes.a ${STATICLIBS}/lib
	mkdir -p ${STATICLIBS}/testbin
	cp ${WORKD}/${BINUTILS}/binutils/bfdtest1${EXTENSION} ${STATICLIBS}/testbin
	rm -f ${OUTPUT}/bin/${TARGET}-ld.bfd${EXTENSION}
	rm -f ${OUTPUT}/bin/ld.bfd${EXTENSION}
	rm -f ${OUTPUT}/${TARGET}/bin/ld.bfd${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-addr2line${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-ar${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-as${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-c++filt${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-elfedit${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-gprof${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-ld${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-nm${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-objcopy${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-objdump${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-ranlib${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-readelf${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-size${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-strings${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-strip${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/ar${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/as${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/ld${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/nm${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/objcopy${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/objdump${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/ranlib${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/strip${EXTENSION}
	touch ${PROGRESS}/${BINUTILS}.built
	#rm -rf ${WORKD}/${BINUTILS}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${GCC}-extract.built ]; then
	echo "*********************************"
	echo "   GCC Extract & Patch"
	echo "*********************************"
	cd ${WORKD}
	rm -rf ${WORKD}/${GCC} ${WORKD}/gcc-first ${WORKD}/gcc-final
	cd ${WORKD}
	tar -xjf ${SOURCES}/${GCC}.tar.bz2
	cp ${SOURCES}/t-cs-eabi-lite ${GCC}/gcc/config/arm
	cd ${GCC}
	patch -p0 < ${SOURCES}/gcc-multilib-bash.patch 
	patch -p0 < ${SOURCES}/gcc-4.7-2012.09-caddr_t.patch
	touch ${PROGRESS}/${GCC}-extract.built
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${GCC}-boot.built -a $BUILD == $HOST ]; then
	echo "*********************************"
	echo "   GCC Bootstrap"
	echo "*********************************"
	rm -rf ${WORKD}/gcc-first
	mkdir -p ${WORKD}/gcc-first
	cd ${WORKD}/gcc-first
	${WORKD}/${GCC}/configure --prefix=${PREFIX} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} \
		--enable-threads --disable-libmudflap --disable-libssp \
		--disable-libstdcxx-pch --enable-extra-sgxxlite-multilibs \
		--with-gnu-as --with-gnu-ld \
		'--with-specs=%{save-temps: -fverbose-asm} %{O2:%{!fno-remove-local-statics: -fremove-local-statics}} %{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics: -fremove-local-statics}}}' \
		--disable-shared --enable-lto --with-newlib \
        	"--with-pkgversion=${PKGVERSION}" --with-bugurl=${BUGURL} \
		--disable-nls --disable-shared --disable-threads --disable-libssp \
		--disable-libgomp --without-headers --with-newlib --disable-decimal-float \
		--disable-libffi --disable-libquadmath --disable-libitm --disable-libatomic \
		--enable-languages=c \
		--with-sysroot=${PREFIX}/${TARGET} \
		--with-build-sysroot=${OUTPUT}/${TARGET} \
		--with-gmp=${STATICLIBS} \
		--with-mpfr=${STATICLIBS} \
		--with-mpc=${STATICLIBS} \
		--with-ppl=${STATICLIBS} \
		"--with-host-libstdcxx=${HOST_LIBSTDCXX}" \
		--with-cloog=${STATICLIBS} \
		--with-libelf=${STATICLIBS} \
		--disable-libgomp \
		--disable-libitm \
		--enable-poison-system-directories \
		--with-build-time-tools=${OUTPUT}/${TARGET}/bin \
        	|| exit
	make ${PARALLEL} LDFLAGS_FOR_TARGET=--sysroot=${OUTPUT}/arm-none-eabi \
		CPPFLAGS_FOR_TARGET=--sysroot=${OUTPUT}/arm-none-eabi \
		build_tooldir=${OUTPUT}/arm-none-eabi \
		|| exit
	make prefix=${OUTPUT} exec_prefix=${OUTPUT} libdir=${OUTPUT}/lib \
		htmldir=${OUTPUT}/share/doc/arm-arm-none-eabi/html \
		pdfdir=${OUTPUT}/share/doc/arm-arm-none-eabi/pdf \
		infodir=${OUTPUT}/share/doc/arm-arm-none-eabi/info \
		mandir=${OUTPUT}/share/doc/arm-arm-none-eabi/man \
		install || exit
	rm -f ${OUTPUT}/lib/libiberty.a
	rmdir ${OUTPUT}/include
	touch ${PROGRESS}/${GCC}-boot.built
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/${NEWLIB}.built -a $BUILD == $HOST ]; then
	echo "*********************************"
	echo "   Newlib"
	echo "*********************************"
	cd ${WORKD}
	rm -rf ${WORKD}/${NEWLIB} ${WORKD}/newlib-build
	tar -xjf ${SOURCES}/${NEWLIB}.tar.bz2
	mkdir -p ${WORKD}/newlib-build
	cd ${WORKD}/newlib-build
	export CFLAGS_FOR_TARGET="-g -O2 -fno-unroll-loops"
	${WORKD}/${NEWLIB}/configure --prefix=${PREFIX} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} \
		--enable-newlib-io-long-long \
		--enable-newlib-register-fini \
		--disable-newlib-supplied-syscalls \
		--disable-libgloss \
		--disable-nls \
		|| exit
	make ${PARALLEL}
	make install prefix=${OUTPUT} exec_prefix=${OUTPUT} libdir=${OUTPUT}/lib \
		htmldir=${OUTPUT}/share/doc/arm-arm-none-eabi/html \
		pdfdir=${OUTPUT}/share/doc/arm-arm-none-eabi/pdf \
		infodir=${OUTPUT}/share/doc/arm-arm-none-eabi/info \
		mandir=${OUTPUT}/share/doc/arm-arm-none-eabi/man \
		datadir=${OUTPUT}/share \
		|| exit
	export -n CFLAGS_FOR_TARGET
	touch ${PROGRESS}/${NEWLIB}.built
	#rm -rf ${WORKD}/${NEWLIB}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/copy_native_libs.built -a $BUILD != $HOST ]; then
	echo "*********************************"
	echo "   Copy Libs From Native"
	echo "*********************************"
	mkdir -p ${OUTPUT}/${TARGET}
	cp -r ${NATIVE}/${TARGET}/lib ${OUTPUT}/${TARGET}
	cp -r ${NATIVE}/${TARGET}/include ${OUTPUT}/${TARGET}
	mkdir -p ${OUTPUT}/lib
	cp -r ${NATIVE}/lib/gcc ${OUTPUT}/lib
	touch ${PROGRESS}/copy_native_libs.built
fi

if [ ! -e ${PROGRESS}/${GCC}-final.built ]; then
	echo "*********************************"
	echo "   GCC Final"
	echo "*********************************"
	rm -rf ${WORKD}/gcc-final
	mkdir -p ${WORKD}/gcc-final
	cd ${WORKD}/gcc-final
	ln -s . ${OUTPUT}/arm-none-eabi/usr
	${WORKD}/${GCC}/configure --prefix=${PREFIX} --target=${TARGET} \
		--build=${BUILD} --host=${HOST} \
		--enable-threads --disable-libmudflap --disable-libssp \
		--disable-libstdcxx-pch --enable-extra-sgxxlite-multilibs \
		--with-gnu-as --with-gnu-ld \
		'--with-specs=%{save-temps: -fverbose-asm} %{O2:%{!fno-remove-local-statics: -fremove-local-statics}} %{O*:%{O|O0|O1|O2|Os:;:%{!fno-remove-local-statics: -fremove-local-statics}}}' \
		--enable-languages=c,c++ \
		--disable-shared --enable-lto --with-newlib \
        	"--with-pkgversion=${PKGVERSION}" --with-bugurl=${BUGURL} \
		--disable-nls \
		--with-headers=yes \
		--with-sysroot=${PREFIX}/${TARGET} \
		--with-build-sysroot=${OUTPUT}/${TARGET} \
		--with-gmp=${STATICLIBS} \
		--with-mpfr=${STATICLIBS} \
		--with-mpc=${STATICLIBS} \
		--with-ppl=${STATICLIBS} \
		"--with-host-libstdcxx=${HOST_LIBSTDCXX}" \
		--with-cloog=${STATICLIBS} \
		--with-libelf=${STATICLIBS} \
		--disable-libgomp \
		--disable-libitm \
		--enable-poison-system-directories \
		--with-build-time-tools=${OUTPUT}/${TARGET}/bin \
        	|| exit
	make ${PARALLEL} LDFLAGS_FOR_TARGET=--sysroot=${OUTPUT}/arm-none-eabi \
		CPPFLAGS_FOR_TARGET=--sysroot=${OUTPUT}/arm-none-eabi \
		build_tooldir=${OUTPUT}/arm-none-eabi \
		|| exit
	make prefix=${OUTPUT} exec_prefix=${OUTPUT} \
		libdir=${OUTPUT}/lib \
		htmldir=${OUTPUT}/share/doc/arm-arm-none-eabi/html \
		pdfdir=${OUTPUT}/share/doc/arm-arm-none-eabi/pdf \
		infodir=${OUTPUT}/share/doc/arm-arm-none-eabi/info \
		mandir=${OUTPUT}/share/doc/arm-arm-none-eabi/man \
		install || exit
	touch ${PROGRESS}/${GCC}-final.built
	#rm -rf ${WORKD}/${GCC}
	cd ${THISDIR}
fi

#skip GDB - Arduino doesn't use it... worry about it later
# TODO: GDB is dynamically linking to libtinfo and zlib - use static linking
touch ${PROGRESS}/${GDB}.built
if [ ! -e ${PROGRESS}/${GDB}.built ]; then
	echo "*********************************"
	echo "   GDB"
	echo "*********************************"
	rm -rf ${WORKD}/gdb-final ${WORKD}/${GDB}
	cd ${WORKD}
	tar -xjf ${SOURCES}/${GDB}.tar.bz2
	mkdir -p ${WORKD}/gdb-final
	cd ${WORKD}/gdb-final
	export CPPFLAGS="-I${STATICLIBS}/include"
	export LDFLAGS="-I${STATICLIBS}/lib"
	${WORKD}/${GDB}//configure --prefix=${PREFIX} --target=${TARGET} \
		--disable-sim \
		"--with-pkgversion=${PKGVERSION}" --with-bugurl=${BUGURL} \
		--disable-libmcheck \
		--disable-nls \
		--with-libexpat-prefix=${STATICLIBS} \
		|| exit
		#TODO: are these ok???
		#--with-system-gdbinit=${PREFIX}/lib/gdbinit \
		#--with-gdb-datadir=${PREFIX}/share/gdb \
	make ${PARALLEL} || exit
	make install prefix=${OUTPUT} exec_prefix=${OUTPUT} libdir=${OUTPUT}/lib \
		htmldir=${OUTPUT}/share/doc/arm-arm-none-eabi/html \
		pdfdir=${OUTPUT}/share/doc/arm-arm-none-eabi/pdf \
		infodir=${OUTPUT}/share/doc/arm-arm-none-eabi/info \
		mandir=${OUTPUT}/share/doc/arm-arm-none-eabi/man \
		datadir=${OUTPUT}/share \
		|| exit
	export -n CPPFLAGS
	export -n LDFLAGS
	strip ${OUTPUT}/bin/arm-none-eabi-gdb
	touch ${PROGRESS}/${GDB}.built
	#rm -rf ${WORKD}/${GDB}
	cd ${THISDIR}
fi

if [ ! -e ${PROGRESS}/cleanup.built ]; then
	echo "*********************************"
	echo "   Cleanup"
	echo "*********************************"
	#delete unnecessary stuff
	rm -f ${OUTPUT}/lib/libiberty.a
	rmdir -p --ignore-fail-on-non-empty ${OUTPUT}/include
	rm -f ${OUTPUT}/arm-none-eabi/usr
	rm -f ${OUTPUT}/lib/libiberty.a
	rm -rf ${OUTPUT}/share/doc
	find ${OUTPUT} -name '*.la' -exec rm '{}' ';'
	#strip the executables to save space
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-c++${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-cpp${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-g++${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-gcc${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-gcc-4.7.2${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-gcc-ar${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-gcc-nm${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-gcc-ranlib${EXTENSION}
	${STRIP} ${OUTPUT}/bin/arm-none-eabi-gcov${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/c++${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/g++${EXTENSION}
	${STRIP} ${OUTPUT}/arm-none-eabi/bin/gcc${EXTENSION}
	${STRIP} ${OUTPUT}/libexec/gcc/arm-none-eabi/4.7.2/cc1${EXTENSION}
	${STRIP} ${OUTPUT}/libexec/gcc/arm-none-eabi/4.7.2/collect2${EXTENSION}
	${STRIP} ${OUTPUT}/libexec/gcc/arm-none-eabi/4.7.2/install-tools/fixincl${EXTENSION}
	${STRIP} ${OUTPUT}/libexec/gcc/arm-none-eabi/4.7.2/cc1plus${EXTENSION}
	${STRIP} ${OUTPUT}/libexec/gcc/arm-none-eabi/4.7.2/lto-wrapper${EXTENSION}
	${STRIP} ${OUTPUT}/libexec/gcc/arm-none-eabi/4.7.2/lto1${EXTENSION}
	#delete unused (by Teensy) multilibs
	rm -f ${OUTPUT}/${TARGET}/lib/*.a
	rm -f ${OUTPUT}/${TARGET}/lib/*.a-gdb.py
	rm -f ${OUTPUT}/lib/gcc/${TARGET}/*/*.a
	rm -f ${OUTPUT}/lib/gcc/${TARGET}/*/*.o
	#strip the libs we do use
	if [ $BUILD == $HOST ]; then
		RUNABLE="${OUTPUT}";
	else
		RUNABLE="${NATIVE}";
	fi
	find ${OUTPUT}/${TARGET}/lib -name '*.a' \
		-exec ${RUNABLE}/bin/arm-none-eabi-objcopy -R .comment \
		-R .note -R .debug_info -R .debug_aranges -R .debug_pubnames \
		-R .debug_pubtypes -R .debug_abbrev -R .debug_line -R .debug_str \
		-R .debug_ranges -R .debug_loc '{}' ';'
	find ${OUTPUT}/lib/gcc/${TARGET} -name '*.a' \
		-exec ${RUNABLE}/bin/arm-none-eabi-objcopy -R .comment \
		-R .note -R .debug_info -R .debug_aranges -R .debug_pubnames \
		-R .debug_pubtypes -R .debug_abbrev -R .debug_line -R .debug_str \
		-R .debug_ranges -R .debug_loc '{}' ';'
	touch ${PROGRESS}/cleanup-final.built
	#echo "Multilib specs:"
	#${RUNABLE}/bin/arm-none-eabi-gcc -dumpspecs | grep -A1 multilib:
	cd ${THISDIR}
fi


# Cleanup
cat > ${OUTPUT}/arm-none-eabi/bin/README.txt <<'EOF0'
The executables in this directory are for internal use by the compiler
and may not operate correctly when used directly.  This directory
should not be placed on your PATH.  Instead, you should use the
executables in ../../bin/ and place that directory on your PATH.
EOF0
echo "Build Completed"




