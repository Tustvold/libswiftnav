# Originally developed by Matthias Kretz as part of the Vc library.
# http://gitorious.org/vc/vc/trees/master/cmake.
#
# Licensed under the terms of the GNU LGPL

get_filename_component(_currentDir "${CMAKE_CURRENT_LIST_FILE}" PATH)
include("${_currentDir}/AddCompilerFlag.cmake")
include(CheckIncludeFile)

macro(_my_find _list _value _ret)
   list(FIND ${_list} "${_value}" _found)
   if(_found EQUAL -1)
      set(${_ret} FALSE)
   else(_found EQUAL -1)
      set(${_ret} TRUE)
   endif(_found EQUAL -1)
endmacro(_my_find)

macro(AutodetectHostArchitecture)
   set(TARGET_ARCHITECTURE "generic")
   set(Vc_ARCHITECTURE_FLAGS)
   set(_vendor_id)
   set(_cpu_family)
   set(_cpu_model)
   if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      file(READ "/proc/cpuinfo" _cpuinfo)
      string(REGEX REPLACE ".*vendor_id[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _vendor_id "${_cpuinfo}")
      string(REGEX REPLACE ".*cpu family[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_family "${_cpuinfo}")
      string(REGEX REPLACE ".*model[ \t]*:[ \t]+([a-zA-Z0-9_-]+).*" "\\1" _cpu_model "${_cpuinfo}")
      string(REGEX REPLACE ".*flags[ \t]*:[ \t]+([^\n]+).*" "\\1" _cpu_flags "${_cpuinfo}")
   elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      exec_program("/usr/sbin/sysctl -n machdep.cpu.vendor" OUTPUT_VARIABLE _vendor_id)
      exec_program("/usr/sbin/sysctl -n machdep.cpu.model"  OUTPUT_VARIABLE _cpu_model)
      exec_program("/usr/sbin/sysctl -n machdep.cpu.family" OUTPUT_VARIABLE _cpu_family)
      exec_program("/usr/sbin/sysctl -n machdep.cpu.features" OUTPUT_VARIABLE _cpu_flags)
      string(TOLOWER "${_cpu_flags}" _cpu_flags)
      string(REPLACE "." "_" _cpu_flags "${_cpu_flags}")
   elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
      get_filename_component(_vendor_id "[HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;VendorIdentifier]" NAME CACHE)
      get_filename_component(_cpu_id "[HKEY_LOCAL_MACHINE\\Hardware\\Description\\System\\CentralProcessor\\0;Identifier]" NAME CACHE)
      mark_as_advanced(_vendor_id _cpu_id)
      string(REGEX REPLACE ".* Family ([0-9]+) .*" "\\1" _cpu_family "${_cpu_id}")
      string(REGEX REPLACE ".* Model ([0-9]+) .*" "\\1" _cpu_model "${_cpu_id}")
   endif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
   message(STATUS "Detected: Vendor ID '${_vendor_id}'   CPU Family '${_cpu_family}'  CPU Model '${_cpu_model}'  CPU Flags  '${_cpu_flags}'")
   if(_vendor_id STREQUAL "GenuineIntel")
      if(_cpu_family EQUAL 6)
         # Any recent Intel CPU except NetBurst
         if(_cpu_model EQUAL 69)    # Core i5/i7-4xxxU CPUs
            set(TARGET_ARCHITECTURE "haswell")
         elseif(_cpu_model EQUAL 63) # Xeon E5 series
            set(TARGET_ARCHITECTURE "sandy-bridge")
         elseif(_cpu_model EQUAL 62)
            set(TARGET_ARCHITECTURE "ivy-bridge")
         elseif(_cpu_model EQUAL 60)
            set(TARGET_ARCHITECTURE "haswell")
         elseif(_cpu_model EQUAL 58)
            set(TARGET_ARCHITECTURE "ivy-bridge")
         elseif(_cpu_model EQUAL 47) # Xeon E7 4860
            set(TARGET_ARCHITECTURE "westmere")
         elseif(_cpu_model EQUAL 46) # Xeon 7500 series
            set(TARGET_ARCHITECTURE "westmere")
         elseif(_cpu_model EQUAL 45) # Xeon TNG
            set(TARGET_ARCHITECTURE "sandy-bridge")
         elseif(_cpu_model EQUAL 44) # Xeon 5600 series
            set(TARGET_ARCHITECTURE "westmere")
         elseif(_cpu_model EQUAL 42) # Core TNG
            set(TARGET_ARCHITECTURE "sandy-bridge")
         elseif(_cpu_model EQUAL 37) # Core i7/i5/i3
            set(TARGET_ARCHITECTURE "westmere")
         elseif(_cpu_model EQUAL 31) # Core i7/i5
            set(TARGET_ARCHITECTURE "westmere")
         elseif(_cpu_model EQUAL 30) # Core i7/i5
            set(TARGET_ARCHITECTURE "westmere")
         elseif(_cpu_model EQUAL 29)
            set(TARGET_ARCHITECTURE "penryn")
         elseif(_cpu_model EQUAL 28)
            set(TARGET_ARCHITECTURE "atom")
         elseif(_cpu_model EQUAL 26)
            set(TARGET_ARCHITECTURE "nehalem")
         elseif(_cpu_model EQUAL 23)
            set(TARGET_ARCHITECTURE "penryn")
         elseif(_cpu_model EQUAL 15)
            set(TARGET_ARCHITECTURE "merom")
         elseif(_cpu_model EQUAL 14)
            set(TARGET_ARCHITECTURE "core")
         elseif(_cpu_model LESS 14)
            message(WARNING "Your CPU (family ${_cpu_family}, model ${_cpu_model}) is not known. Auto-detection of optimization flags failed and will use the generic CPU settings with SSE2.")
            set(TARGET_ARCHITECTURE "generic")
         else()
            message(WARNING "Your CPU (family ${_cpu_family}, model ${_cpu_model}) is not known. Auto-detection of optimization flags failed and will use the 65nm Core 2 CPU settings.")
            set(TARGET_ARCHITECTURE "merom")
         endif()
      elseif(_cpu_family EQUAL 7) # Itanium (not supported)
         message(WARNING "Your CPU (Itanium: family ${_cpu_family}, model ${_cpu_model}) is not supported by OptimizeForArchitecture.cmake.")
      elseif(_cpu_family EQUAL 15) # NetBurst
         list(APPEND _available_vector_units_list "sse" "sse2")
         if(_cpu_model GREATER 2) # Not sure whether this must be 3 or even 4 instead
            list(APPEND _available_vector_units_list "sse" "sse2" "sse3")
         endif(_cpu_model GREATER 2)
      endif(_cpu_family EQUAL 6)
   elseif(_vendor_id STREQUAL "AuthenticAMD")
      if(_cpu_family EQUAL 22) # 16h
         set(TARGET_ARCHITECTURE "AMD 16h")
      elseif(_cpu_family EQUAL 21) # 15h
         if(_cpu_model LESS 2)
            set(TARGET_ARCHITECTURE "bulldozer")
         else()
            set(TARGET_ARCHITECTURE "piledriver")
         endif()
      elseif(_cpu_family EQUAL 20) # 14h
         set(TARGET_ARCHITECTURE "AMD 14h")
      elseif(_cpu_family EQUAL 18) # 12h
      elseif(_cpu_family EQUAL 16) # 10h
         set(TARGET_ARCHITECTURE "barcelona")
      elseif(_cpu_family EQUAL 15)
         set(TARGET_ARCHITECTURE "k8")
         if(_cpu_model GREATER 64) # I don't know the right number to put here. This is just a guess from the hardware I have access to
            set(TARGET_ARCHITECTURE "k8-sse3")
         endif(_cpu_model GREATER 64)
      endif()
   endif(_vendor_id STREQUAL "GenuineIntel")
endmacro()

macro(OptimizeForArchitecture)
   set(TARGET_ARCHITECTURE "auto" CACHE STRING "CPU architecture to optimize for. Using an incorrect setting here can result in crashes of the resulting binary because of invalid instructions used.\nSetting the value to \"auto\" will try to optimize for the architecture where cmake is called.\nOther supported values are: \"none\", \"generic\", \"core\", \"merom\" (65nm Core2), \"penryn\" (45nm Core2), \"nehalem\", \"westmere\", \"sandy-bridge\", \"ivy-bridge\", \"atom\", \"k8\", \"k8-sse3\", \"barcelona\", \"istanbul\", \"magny-cours\", \"bulldozer\", \"interlagos\".")
   set(_force)
   if(NOT _last_target_arch STREQUAL "${TARGET_ARCHITECTURE}")
      message(STATUS "target changed from \"${_last_target_arch}\" to \"${TARGET_ARCHITECTURE}\"")
      set(_force FORCE)
   endif()
   set(_last_target_arch "${TARGET_ARCHITECTURE}" CACHE STRING "" FORCE)
   mark_as_advanced(_last_target_arch)
   string(TOLOWER "${TARGET_ARCHITECTURE}" TARGET_ARCHITECTURE)

   set(_march_flag_list)
   set(_available_vector_units_list)

   if(TARGET_ARCHITECTURE STREQUAL "auto")
      AutodetectHostArchitecture()
      message(STATUS "Detected CPU: ${TARGET_ARCHITECTURE}")
   endif(TARGET_ARCHITECTURE STREQUAL "auto")

   if(TARGET_ARCHITECTURE STREQUAL "core")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3")
   elseif(TARGET_ARCHITECTURE STREQUAL "merom")
      list(APPEND _march_flag_list "merom")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3")
   elseif(TARGET_ARCHITECTURE STREQUAL "penryn")
      list(APPEND _march_flag_list "penryn")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3")
      message(STATUS "Sadly the Penryn architecture exists in variants with SSE4.1 and without SSE4.1.")
      if(_cpu_flags MATCHES "sse4_1")
         message(STATUS "SSE4.1: enabled (auto-detected from this computer's CPU flags)")
         list(APPEND _available_vector_units_list "sse4.1")
      else()
         message(STATUS "SSE4.1: disabled (auto-detected from this computer's CPU flags)")
      endif()
   elseif(TARGET_ARCHITECTURE STREQUAL "nehalem")
      list(APPEND _march_flag_list "nehalem")
      list(APPEND _march_flag_list "corei7")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2")
   elseif(TARGET_ARCHITECTURE STREQUAL "westmere")
      list(APPEND _march_flag_list "westmere")
      list(APPEND _march_flag_list "corei7")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2")
   elseif(TARGET_ARCHITECTURE STREQUAL "haswell")
      list(APPEND _march_flag_list "core-avx2")
      list(APPEND _march_flag_list "core-avx-i")
      list(APPEND _march_flag_list "corei7-avx")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx" "avx2" "rdrnd" "f16c" "fma")
   elseif(TARGET_ARCHITECTURE STREQUAL "ivy-bridge")
      list(APPEND _march_flag_list "core-avx-i")
      list(APPEND _march_flag_list "corei7-avx")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx" "rdrnd" "f16c")
   elseif(TARGET_ARCHITECTURE STREQUAL "sandy-bridge")
      list(APPEND _march_flag_list "sandybridge")
      list(APPEND _march_flag_list "corei7-avx")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4.1" "sse4.2" "avx")
   elseif(TARGET_ARCHITECTURE STREQUAL "atom")
      list(APPEND _march_flag_list "atom")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3")
   elseif(TARGET_ARCHITECTURE STREQUAL "k8")
      list(APPEND _march_flag_list "k8")
      list(APPEND _available_vector_units_list "sse" "sse2")
   elseif(TARGET_ARCHITECTURE STREQUAL "k8-sse3")
      list(APPEND _march_flag_list "k8-sse3")
      list(APPEND _march_flag_list "k8")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3")
   elseif(TARGET_ARCHITECTURE STREQUAL "AMD 16h")
      list(APPEND _march_flag_list "btver2")
      list(APPEND _march_flag_list "btver1")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "f16c")
   elseif(TARGET_ARCHITECTURE STREQUAL "AMD 14h")
      list(APPEND _march_flag_list "btver1")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a")
   elseif(TARGET_ARCHITECTURE STREQUAL "piledriver")
      list(APPEND _march_flag_list "bdver2")
      list(APPEND _march_flag_list "bdver1")
      list(APPEND _march_flag_list "bulldozer")
      list(APPEND _march_flag_list "barcelona")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "xop" "fma4" "fma" "f16c")
   elseif(TARGET_ARCHITECTURE STREQUAL "interlagos")
      list(APPEND _march_flag_list "bdver1")
      list(APPEND _march_flag_list "bulldozer")
      list(APPEND _march_flag_list "barcelona")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "xop" "fma4")
   elseif(TARGET_ARCHITECTURE STREQUAL "bulldozer")
      list(APPEND _march_flag_list "bdver1")
      list(APPEND _march_flag_list "bulldozer")
      list(APPEND _march_flag_list "barcelona")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "ssse3" "sse4a" "sse4.1" "sse4.2" "avx" "xop" "fma4")
   elseif(TARGET_ARCHITECTURE STREQUAL "barcelona")
      list(APPEND _march_flag_list "barcelona")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "sse4a")
   elseif(TARGET_ARCHITECTURE STREQUAL "istanbul")
      list(APPEND _march_flag_list "barcelona")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "sse4a")
   elseif(TARGET_ARCHITECTURE STREQUAL "magny-cours")
      list(APPEND _march_flag_list "barcelona")
      list(APPEND _march_flag_list "core2")
      list(APPEND _available_vector_units_list "sse" "sse2" "sse3" "sse4a")
   elseif(TARGET_ARCHITECTURE STREQUAL "generic")
      list(APPEND _march_flag_list "generic")
   elseif(TARGET_ARCHITECTURE STREQUAL "none")
      # add this clause to remove it from the else clause
   else(TARGET_ARCHITECTURE STREQUAL "core")
      message(FATAL_ERROR "Unknown target architecture: \"${TARGET_ARCHITECTURE}\". Please set TARGET_ARCHITECTURE to a supported value.")
   endif(TARGET_ARCHITECTURE STREQUAL "core")

   if(NOT TARGET_ARCHITECTURE STREQUAL "none")
      set(_disable_vector_unit_list)
      set(_enable_vector_unit_list)
      _my_find(_available_vector_units_list "sse2" SSE2_FOUND)
      _my_find(_available_vector_units_list "sse3" SSE3_FOUND)
      _my_find(_available_vector_units_list "ssse3" SSSE3_FOUND)
      _my_find(_available_vector_units_list "sse4.1" SSE4_1_FOUND)
      _my_find(_available_vector_units_list "sse4.2" SSE4_2_FOUND)
      _my_find(_available_vector_units_list "sse4a" SSE4a_FOUND)
      if(DEFINED Vc_AVX_INTRINSICS_BROKEN AND Vc_AVX_INTRINSICS_BROKEN)
         UserWarning("AVX disabled per default because of old/broken compiler")
         set(AVX_FOUND false)
         set(XOP_FOUND false)
         set(FMA4_FOUND false)
         set(AVX2_FOUND false)
      else()
         _my_find(_available_vector_units_list "avx" AVX_FOUND)
         if(DEFINED Vc_FMA4_INTRINSICS_BROKEN AND Vc_FMA4_INTRINSICS_BROKEN)
            UserWarning("FMA4 disabled per default because of old/broken compiler")
            set(FMA4_FOUND false)
         else()
            _my_find(_available_vector_units_list "fma4" FMA4_FOUND)
         endif()
         if(DEFINED Vc_XOP_INTRINSICS_BROKEN AND Vc_XOP_INTRINSICS_BROKEN)
            UserWarning("XOP disabled per default because of old/broken compiler")
            set(XOP_FOUND false)
         else()
            _my_find(_available_vector_units_list "xop" XOP_FOUND)
         endif()
         if(DEFINED Vc_AVX2_INTRINSICS_BROKEN AND Vc_AVX2_INTRINSICS_BROKEN)
            UserWarning("AVX2 disabled per default because of old/broken compiler")
            set(AVX2_FOUND false)
         else()
            _my_find(_available_vector_units_list "avx2" AVX2_FOUND)
         endif()
      endif()
      set(USE_SSE2   ${SSE2_FOUND}   CACHE BOOL "Use SSE2. If SSE2 instructions are not enabled the SSE implementation will be disabled." ${_force})
      set(USE_SSE3   ${SSE3_FOUND}   CACHE BOOL "Use SSE3. If SSE3 instructions are not enabled they will be emulated." ${_force})
      set(USE_SSSE3  ${SSSE3_FOUND}  CACHE BOOL "Use SSSE3. If SSSE3 instructions are not enabled they will be emulated." ${_force})
      set(USE_SSE4_1 ${SSE4_1_FOUND} CACHE BOOL "Use SSE4.1. If SSE4.1 instructions are not enabled they will be emulated." ${_force})
      set(USE_SSE4_2 ${SSE4_2_FOUND} CACHE BOOL "Use SSE4.2. If SSE4.2 instructions are not enabled they will be emulated." ${_force})
      set(USE_SSE4a  ${SSE4a_FOUND}  CACHE BOOL "Use SSE4a. If SSE4a instructions are not enabled they will be emulated." ${_force})
      set(USE_AVX    ${AVX_FOUND}    CACHE BOOL "Use AVX. This will double some of the vector sizes relative to SSE." ${_force})
      set(USE_AVX2   ${AVX2_FOUND}   CACHE BOOL "Use AVX2. This will double all of the vector sizes relative to SSE." ${_force})
      set(USE_XOP    ${XOP_FOUND}    CACHE BOOL "Use XOP." ${_force})
      set(USE_FMA4   ${FMA4_FOUND}   CACHE BOOL "Use FMA4." ${_force})
      mark_as_advanced(USE_SSE2 USE_SSE3 USE_SSSE3 USE_SSE4_1 USE_SSE4_2 USE_SSE4a USE_AVX USE_AVX2 USE_XOP USE_FMA4)
      if(USE_SSE2)
         list(APPEND _enable_vector_unit_list "sse2")
      else(USE_SSE2)
         list(APPEND _disable_vector_unit_list "sse2")
      endif(USE_SSE2)
      if(USE_SSE3)
         list(APPEND _enable_vector_unit_list "sse3")
      else(USE_SSE3)
         list(APPEND _disable_vector_unit_list "sse3")
      endif(USE_SSE3)
      if(USE_SSSE3)
         list(APPEND _enable_vector_unit_list "ssse3")
      else(USE_SSSE3)
         list(APPEND _disable_vector_unit_list "ssse3")
      endif(USE_SSSE3)
      if(USE_SSE4_1)
         list(APPEND _enable_vector_unit_list "sse4.1")
      else(USE_SSE4_1)
         list(APPEND _disable_vector_unit_list "sse4.1")
      endif(USE_SSE4_1)
      if(USE_SSE4_2)
         list(APPEND _enable_vector_unit_list "sse4.2")
      else(USE_SSE4_2)
         list(APPEND _disable_vector_unit_list "sse4.2")
      endif(USE_SSE4_2)
      if(USE_SSE4a)
         list(APPEND _enable_vector_unit_list "sse4a")
      else(USE_SSE4a)
         list(APPEND _disable_vector_unit_list "sse4a")
      endif(USE_SSE4a)
      if(USE_AVX)
         list(APPEND _enable_vector_unit_list "avx")
         # we want SSE intrinsics to result in instructions using the VEX prefix.
         # Otherwise integer ops (which require the older SSE intrinsics) would
         # always have a large penalty.
         list(APPEND _enable_vector_unit_list "sse2avx")
      else(USE_AVX)
         list(APPEND _disable_vector_unit_list "avx")
      endif(USE_AVX)
      if(USE_XOP)
         list(APPEND _enable_vector_unit_list "xop")
      else()
         list(APPEND _disable_vector_unit_list "xop")
      endif()
      if(USE_FMA4)
         list(APPEND _enable_vector_unit_list "fma4")
      else()
         list(APPEND _disable_vector_unit_list "fma4")
      endif()
      if(USE_AVX2)
         list(APPEND _enable_vector_unit_list "avx2")
      else()
         list(APPEND _disable_vector_unit_list "avx2")
      endif()
      if(MSVC)
         # MSVC on 32 bit can select /arch:SSE2 (since 2010 also /arch:AVX)
         # MSVC on 64 bit cannot select anything (should have changed with MSVC 2010)
         _my_find(_enable_vector_unit_list "avx" _avx)
         set(_avx_flag FALSE)
         if(_avx)
            AddCompilerFlag("/arch:AVX" C_FLAGS Vc_ARCHITECTURE_FLAGS C_RESULT _avx_flag)
         endif()
         if(NOT _avx_flag)
            _my_find(_enable_vector_unit_list "sse2" _found)
            if(_found)
               AddCompilerFlag("/arch:SSE2" C_FLAGS Vc_ARCHITECTURE_FLAGS)
            endif()
         endif()
         foreach(_flag ${_enable_vector_unit_list})
            string(TOUPPER "${_flag}" _flag)
            string(REPLACE "." "_" _flag "__${_flag}__")
            add_definitions("-D${_flag}")
         endforeach(_flag)
      elseif(CMAKE_C_COMPILER MATCHES "/(icpc|icc)$") # ICC (on Linux)
         _my_find(_available_vector_units_list "avx2"    _found)
         if(_found)
            AddCompilerFlag("-xCORE-AVX2" C_FLAGS Vc_ARCHITECTURE_FLAGS)
         else(_found)
            _my_find(_available_vector_units_list "f16c"    _found)
            if(_found)
               AddCompilerFlag("-xCORE-AVX-I" C_FLAGS Vc_ARCHITECTURE_FLAGS)
            else(_found)
               _my_find(_available_vector_units_list "avx"    _found)
               if(_found)
                  AddCompilerFlag("-xAVX" C_FLAGS Vc_ARCHITECTURE_FLAGS)
               else(_found)
                  _my_find(_available_vector_units_list "sse4.2" _found)
                  if(_found)
                     AddCompilerFlag("-xSSE4.2" C_FLAGS Vc_ARCHITECTURE_FLAGS)
                  else(_found)
                     _my_find(_available_vector_units_list "sse4.1" _found)
                     if(_found)
                        AddCompilerFlag("-xSSE4.1" C_FLAGS Vc_ARCHITECTURE_FLAGS)
                     else(_found)
                        _my_find(_available_vector_units_list "ssse3"  _found)
                        if(_found)
                           AddCompilerFlag("-xSSSE3" C_FLAGS Vc_ARCHITECTURE_FLAGS)
                        else(_found)
                           _my_find(_available_vector_units_list "sse3"   _found)
                           if(_found)
                              # If the target host is an AMD machine then we still want to use -xSSE2 because the binary would refuse to run at all otherwise
                              _my_find(_march_flag_list "barcelona" _found)
                              if(NOT _found)
                                 _my_find(_march_flag_list "k8-sse3" _found)
                              endif(NOT _found)
                              if(_found)
                                 AddCompilerFlag("-xSSE2" C_FLAGS Vc_ARCHITECTURE_FLAGS)
                              else(_found)
                                 AddCompilerFlag("-xSSE3" C_FLAGS Vc_ARCHITECTURE_FLAGS)
                              endif(_found)
                           else(_found)
                              _my_find(_available_vector_units_list "sse2"   _found)
                              if(_found)
                                 AddCompilerFlag("-xSSE2" C_FLAGS Vc_ARCHITECTURE_FLAGS)
                              endif(_found)
                           endif(_found)
                        endif(_found)
                     endif(_found)
                  endif(_found)
               endif(_found)
            endif(_found)
         endif(_found)
      else() # not MSVC and not ICC => GCC, Clang, Open64
         foreach(_flag ${_march_flag_list})
            AddCompilerFlag("-march=${_flag}" C_RESULT _good C_FLAGS Vc_ARCHITECTURE_FLAGS)
            if(_good)
               break()
            endif(_good)
         endforeach(_flag)
         foreach(_flag ${_enable_vector_unit_list})
            AddCompilerFlag("-m${_flag}" C_RESULT _result)
            if(_result)
               set(_header FALSE)
               if(_flag STREQUAL "sse3")
                  set(_header "pmmintrin.h")
               elseif(_flag STREQUAL "ssse3")
                  set(_header "tmmintrin.h")
               elseif(_flag STREQUAL "sse4.1")
                  set(_header "smmintrin.h")
               elseif(_flag STREQUAL "sse4.2")
                  set(_header "smmintrin.h")
               elseif(_flag STREQUAL "sse4a")
                  set(_header "ammintrin.h")
               elseif(_flag STREQUAL "avx")
                  set(_header "immintrin.h")
               elseif(_flag STREQUAL "avx2")
                  set(_header "immintrin.h")
               elseif(_flag STREQUAL "fma4")
                  set(_header "x86intrin.h")
               elseif(_flag STREQUAL "xop")
                  set(_header "x86intrin.h")
               endif()
               set(_resultVar "HAVE_${_header}")
               string(REPLACE "." "_" _resultVar "${_resultVar}")
               if(_header)
                  CHECK_INCLUDE_FILE("${_header}" ${_resultVar} "-m${_flag}")
                  if(NOT ${_resultVar})
                     set(_useVar "USE_${_flag}")
                     string(TOUPPER "${_useVar}" _useVar)
                     string(REPLACE "." "_" _useVar "${_useVar}")
                     message(STATUS "disabling ${_useVar} because ${_header} is missing")
                     set(${_useVar} FALSE)
                     list(APPEND _disable_vector_unit_list "${_flag}")
                  endif()
               endif()
               if(NOT _header OR ${_resultVar})
                  set(Vc_ARCHITECTURE_FLAGS "${Vc_ARCHITECTURE_FLAGS} -m${_flag}")
               endif()
            endif()
         endforeach(_flag)
         foreach(_flag ${_disable_vector_unit_list})
            AddCompilerFlag("-mno-${_flag}" C_FLAGS Vc_ARCHITECTURE_FLAGS)
         endforeach(_flag)
      endif()
   endif()
endmacro(OptimizeForArchitecture)
